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
      start=$(date +%s)
      check_precondition
      [ -z $VM_NAME ] && help
      echo -e "Bring Up VM -> $VM_NAME"
      create_vm "$VM_NAME"
      mount_apps "$VM_NAME"
      configure_vm "$VM_NAME"
      umount_apps "$VM_NAME"
      end=$(date +%s)
      runtime=$((end-start))
      echo -e "${GREEN}${BOLD}VM Provision Done! | Duration:  $(display_time $runtime)${NC}"
      ;;
    down)
      echo "Destroy VM"
      [ -z $VM_NAME ] && help
      echo -e "Deleting VM -> $VM_NAME"
      delete_vm "$VM_NAME"
      ;;
    configure)
      echo "Configure VM"
      [ -z $VM_NAME ] && help
      echo -e "Configure VM -> $VM_NAME"
      configure_vm "$VM_NAME"
      ;;
    mount)
      echo "Mounting Host Folders to  VM"
      [ -z $VM_NAME ] && help
      echo -e "Mounting Folders to -> $VM_NAME"
      mount_apps "$VM_NAME"
      ;;
    umount)
      echo "Un Mounting Host Folders from  VM"
      [ -z $VM_NAME ] && help
      echo -e "UnMounting Folders From -> $VM_NAME"
      umount_apps "$VM_NAME"
      ;;
    status)
      multipass ls
      ;;
    *)  help ;;
esac


