#!/bin/bash
set -eu

usage () {
  echo "Usage:"
  echo -e "\t$0 add <domain>... - cohost a list of domains"
  echo -e "\t$0 rm <domain>... - stop cohosting domains"
  echo -e "\t$0 ls [domain]... - list cohosted domains or snapshots for a domain"
  echo -e "\t$0 sync - update all cohosted domains"
  echo -e "\t$0 prune [n] - remove all but the last [n] snapshots. default 1"
  exit 1
}

MFS_DIR="/cohosting/full"

update () {
  domain=$1
  cid=$(ipfs resolve "/ipns/$1")
  path="$MFS_DIR/$domain"

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
  ipfs files rm -rf "$MFS_DIR/$1"
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
    echo -n "Adding $domain..."
    update $domain
    echo " done!"
  done

  exit 0
fi

if [ "$1" = "rm" ]; then
  if [ $# -lt 2 ]; then
   usage
  fi

  shift 1

  for domain in "$@"; do
    echo -n "Removing $domain..."
    remove $domain
    echo " done!"
  done

  exit 0
fi

if [ "$1" = "ls" ]; then
  if [ $# -lt 2 ]; then
    ipfs files ls $MFS_DIR
    exit 0
  fi

  shift 1

  for domain in "$@"; do
    echo "snapshots for $domain"
    ipfs files ls "$MFS_DIR/$domain"
  done
  exit 0
fi

if [ "$1" = "sync" ]; then
  ipfs files ls $MFS_DIR | while read domain; do
    echo -n "Syncing $domain..."
    update $domain
    echo " done!"
  done
  exit 0
fi

function prune () {
  local historyLength=${1:-"1"}
  ipfs files ls $MFS_DIR | while read domain; do
    echo -n "Cleaning $domain..."
    ipfs files ls "$MFS_DIR/$domain" | tail -r | tail -n "+$(($historyLength + 1))" | while read snap; do
      ipfs files rm -rf "$MFS_DIR/$domain/$snap"
    done
    echo " done!"
  done
}

if [ "$1" = "prune" ]; then
  if [ $# -eq 1 ]; then
    prune
    exit 0
  fi

  if [ ! $# -eq 2 ]; then
    usage
  fi

  prune $2
  exit 0
fi

usage
