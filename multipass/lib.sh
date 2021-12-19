#!/usr/bin/env bash

NC=$'\e[0m' # No Color
BOLD=$'\033[1m'
UNDERLINE=$'\033[4m'
RED=$'\e[31m'
GREEN=$'\e[32m'
BLUE=$'\e[34m'
ORANGE=$'\x1B[33m'

# Path to your hosts file
hostsFile="/etc/hosts"

# Default IP address for host
ip="127.0.0.1"

function yell() { echo "$0: $*" >&2; }
function die() { yell "$*"; exit 111; }
function try() { "$@" || die "cannot $*"; }

function remove() {
    hostname=$1
    if [ -n "$(grep  "[[:space:]]$hostname" /etc/hosts)" ]; then
        echo "$hostname found in $hostsFile. Removing now...";
        try sudo sed -ie "/[[:space:]]$hostname/d" "$hostsFile";
    else
        yell "$hostname was not found in $hostsFile";
    fi
}

function add() {
    hostname=$1
    if [ -n "$(grep  "[[:space:]]$hostname" /etc/hosts)" ]; then
        yell "$hostname, already exists: $(grep $hostname $hostsFile)";
    else
        echo "Adding $hostname to $hostsFile...";
        try printf "%s\t%s\n" "$ip" "$hostname" | sudo tee -a "$hostsFile" > /dev/null;

        if [ -n "$(grep $hostname /etc/hosts)" ]; then
            echo "$hostname was added succesfully:";
            #echo "$(grep $hostname /etc/hosts)";
        else
            die "Failed to add $hostname";
        fi
    fi
}

function backup(){
    try sudo cp "$hostsFile" "$hostsFile.bak" 
}

function execute_action(){
  action=$1
  for service in "${services[@]}"
  do
    $action "$service.${BASE_DOMAIN}"
  done
}

function add_host_entries(){
  execute_action "add"
}

function remove_host_entries(){
  backup
  execute_action "remove"
}

function verify_certificates(){
  execute_action "wait_for_url"
}

function display_app_status(){
    echo "Apps Status"
    execute_action "display_url_status"
}

function display_url_status(){
    HOST=$1
    if [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${HOST})" != "200" ]] ; then 
        echo "https://$HOST  -> Down"
    else
        echo "https://$HOST  -> Up"
    fi
}

function wait_for_url() {
    echo "If this the first time, Certificate generation takes around a min..."
    HOST=$1
    echo "Testing $1"
    timeout -s TERM 40 bash -c \
            'while [[ "$(curl -s -o /dev/null -L -w ''%{http_code}'' ${0})" != "200" ]];\
            do echo "Waiting for ${0}" && sleep 5;\
            done' ${1}
    echo "OK!" 
    #curl -I $1
}

function check_precondition(){
    if ! [ -x "$(command -v multipass)" ]; then
        echo 'Error: multipass is not installed.' >&2
        echo 'Goto https://multipass.run/'
        exit 1
    fi
}

# raise error
function raise_error(){
  echo -e "${BOLD}${RED}${1}${NC}" >&2
  exit 1
}

# workaround for path limitations in windows
function _docker() {
  export MSYS_NO_PATHCONV=1
  export MSYS2_ARG_CONV_EXCL='*'

  case "$OSTYPE" in
      *msys*|*cygwin*) os="$(uname -o)" ;;
      *) os="$(uname)";;
  esac

  if [[ "$os" == "Msys" ]] || [[ "$os" == "Cygwin" ]]; then
      # shellcheck disable=SC2230
      realdocker="$(which -a docker | grep -v "$(readlink -f "$0")" | head -1)"
      printf "%s\0" "$@" > /tmp/args.txt
      # --tty or -t requires winpty
      if grep -ZE '^--tty|^-[^-].*t|^-t.*' /tmp/args.txt; then
          #exec winpty /bin/bash -c "xargs -0a /tmp/args.txt '$realdocker'"
          winpty /bin/bash -c "xargs -0a /tmp/args.txt '$realdocker'"
          return 0
      fi
  fi
  docker "$@"
  return 0
}

function configure_vm(){
    local PLAYBOOK_HOME="vm-provisioner/playbooks"
    VM_NAME=$1
    export VM_NAME
    multipass exec $VM_NAME -- sudo apt-get install ansible -y 
    multipass exec $VM_NAME -- ansible-galaxy install geerlingguy.docker --force
    multipass exec $VM_NAME -- ansible-playbook ${PLAYBOOK_HOME}/docker.yml
}

function mount_apps(){
    local VM_HOME="/home/ubuntu"
    VM_NAME=$1
    multipass mount ${HOME}/workspace/zero-day-exploits/vm-provisioner  ${VM_NAME}:${VM_HOME}/vm-provisioner
    multipass mount ${HOME}/workspace/zero-day-exploits/log4j-app  ${VM_NAME}:${VM_HOME}/log4j-app
    multipass mount ${HOME}/workspace/zero-day-exploits/jndi-app  ${VM_NAME}:${VM_HOME}/jndi-app
}

function umount_apps(){
    local VM_HOME="/home/ubuntu"
    VM_NAME=$1
    multipass exec $VM_NAME -- sudo umount ${VM_HOME}/vm-provisioner
    multipass exec $VM_NAME -- sudo umount ${VM_HOME}/log4j-app
    multipass exec $VM_NAME -- sudo umount ${VM_HOME}/jndi-app
}

function create_vm(){
    # local VM_HOME="/home/ubuntu"
    VM_NAME=$1
    multipass launch --name $VM_NAME --cpus 2 --mem 4G --disk 5G --cloud-init cloud-init.yaml
}

function delete_vm(){
    VM_NAME=$1
    multipass stop ${VM_NAME} 
    multipass delete ${VM_NAME}
    multipass purge
}