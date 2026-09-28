#!/bin/bash

DISTRO_ID=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')

case "$DISTRO_ID" in
  arch)        echo "󰣇" ;;
  cachyos)     echo "" ;;
  endeavouros) echo "" ;;
  nixos)       echo "" ;;
  manjaro)     echo "" ;;
  fedora)      echo "" ;;
  *)           echo "" ;;
  esac
