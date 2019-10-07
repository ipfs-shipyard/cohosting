#!/bin/bash
set -eu

usage () {
  echo "Usage:"
  echo -e "\t$0 add <domain>..."
  echo -e "\t$0 rm <domain>..."
  echo -e "\t$0 ls [domain]..."
  echo -e "\t$0 sync"
  echo -e "\t$0 gc [n]"
  exit 1
}

update () {
  domain=$1
  cid=$(ipfs resolve "/ipns/$1")
  path="/cohosting/$domain"

  ipfs files mkdir -p $path
  latest=$(ipfs files ls $path | sort | head -1)

  if [ ! "$latest" = "" ]; then
    latest_cid=$(ipfs files stat "$path/$latest" | head -1)

    if [ "/ipfs/$latest_cid" = "$cid" ]; then
      ipfs files mv "$path/$latest" "$path/$(date -u +"%Y-%m-%d_%H%M%S")"
      return
    fi
  fi

  ipfs refs --recursive $cid > /dev/null
  ipfs files cp $cid "$path/$(date -u +"%Y-%m-%d_%H%M%S")"
}

remove () {
  ipfs files rm -rf "/cohosting/$1"
}

if ! [ -x "$(command -v ipfs)" ]; then
  echo "Error: ipfs is not installed."
  exit 1
fi

if [ $# -eq 0 ]; then
  usage
fi

if [ "$1" = "add" ]; then
  if [ $# -lt 2 ]; then
    usage
  fi

  shift 1

  for domain in "$@"; do
    update $domain
  done

  exit 0
fi

if [ "$1" = "rm" ]; then
  if [ $# -lt 2 ]; then
   usage
  fi

  shift 1

  for domain in "$@"; do
    remove $domain
  done

  exit 0
fi

if [ "$1" = "ls" ]; then
  if [ $# -lt 2 ]; then
    ipfs files ls /cohosting
    exit 0
  fi

  shift 1

  for domain in "$@"; do
    echo "snapshots for $domain"
    ipfs files ls "/cohosting/$domain"
  done
  exit 0
fi

if [ "$1" = "sync" ]; then
  ipfs files ls /cohosting | while read domain; do
    update $domain
  done
  exit 0
fi

if [ "$1" = "gc" ]; then
  if [ $# -eq 1 ]; then
    ipfs files ls /cohosting | while read domain; do
      remove $domain
      ipfs files mkdir -p "/cohosting/$domain"
    done
    exit 0
  fi

  if [ ! $# -eq 2 ]; then
    usage
  fi

  ipfs files ls /cohosting | while read domain; do
    ipfs files ls "/cohosting/$domain" | tail -r | tail -n "+$2" | while read snap; do
      ipfs files rm -rf "/cohosting/$domain/$snap"
    done
  done
fi
