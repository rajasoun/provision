#!/usr/bin/env bash

set -eo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BASE_DIR

source "$BASE_DIR/lib.sh"

function help(){
    echo "Usage: $0  {up|down|status}" >&2
    echo
    echo "   up          ->   Provision, Configure, Validate Application Stack"
    echo "   down        ->   Destroy Application Stack"
    echo "   status      ->   Displays Status of Application Stack"
    echo
    return 1
}

opt="$1"
choice=$( tr '[:upper:]' '[:lower:]' <<<"$opt" )
case $choice in
    up)
      echo "Bring Up VM"
      check_precondition
      create_vm "$2"
      ;;
    down)
      echo "Destroy VM"
      delete_vm "$2"
      echo "Removing Host Enteries & Log files...  "
      ;;
    status)
      multipass ls
      ;;
    *)  help ;;
esac


