#!/usr/bin/env bash

open_ssh() {
  ghostty -e ssh "$@" >/dev/null 2>&1 &
}

case "$1" in
  aliyun)
    open_ssh 47.112.190.71
    ;;
  azure)
    open_ssh azure-vm
    ;;
  localhost)
    open_ssh localhost
    ;;
  "")
    printf '%s\n' "aliyun" "azure" "localhost"
    ;;
esac
