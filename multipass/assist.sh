#!/usr/bin/env bash

set -eo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BASE_DIR 

source "$BASE_DIR/lib.sh"

function help(){
    echo "Usage: $0  {up|down|status}" >&2
    echo
    echo "   up   <vm>  ->   Provision, Configure, Validate Application Stack"
    echo "   down <vm>  ->   Destroy Application Stack"
    echo "   status     ->   Displays Status of Application Stack"
    echo
    return 1
}

opt="$1"
VM_NAME="$2"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    up)
      check_precondition
      [ -z $VM_NAME ] && help
      echo -e "Bring Up VM -> $VM_NAME"
      create_vm "$VM_NAME"
      ;;
    down)
      echo "Destroy VM"
      [ -z $VM_NAME ] && help
      echo -e "Deleting VM -> $VM_NAME"
      delete_vm "$VM_NAME"
      ;;
    configure)
      local PLAYBOOK_HOME="vm-provisioner/playbooks"
      ansible-playbook ${PLAYBOOK_HOME}/git-checkout.yml
      ansible-playbook ${PLAYBOOK_HOME}/docker.yml
      ansible-playbook ${PLAYBOOK_HOME}/trasfer-files.yml
      ;;
    status)
      multipass ls
      ;;
    *)  help ;;
esac


