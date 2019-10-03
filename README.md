# Experiment in MFS-based cohosting

> Exploration around simple tools and conventions for cohosting existing websites with IPFS

## Motivation

- Make it easier for people to contribute storage and bandwidth to sites and datasets they care about
  - Support [IPNS](https://docs.ipfs.io/guides/concepts/ipns/) (libp2p keys) and [DNSLink](https://docs.ipfs.io/guides/concepts/dnslink/) roots (human-readable)
  - Switch tools like ipfs-cohost and ipfs-companion from raw pins to MFS
- Periodically detect updates to and preload them to a local node
- Experiment in userland: make it easy to implement, no new APIs, reuse existing ones
  - Identify constraints of the [mutable filesystem (MFS)](https://docs.ipfs.io/guides/concepts/mfs/) and propose ways to improve it

### Scope vs. Use Cases

See [this analysis](https://github.com/ipfs-shipyard/cohosting/pull/2#issuecomment-524288790).

## Specification

See [SPEC.md](SPEC.md)

> ### 🚧 note: this is a draft, an early, exploratory experiment 🚧
> Feedback is welcome. Fill an issue!

## Potential Implementations

This specification is not implemented yet.
The following [IPFS Shipyard](https://github.com/ipfs-shipyard/) projects could implement it:

🍎 = Not started  
🍊 = In progress  
🍏 = Complete

#### 🍎 [cohosting.sh](cohosting.sh)
> MVP bash script that can be used for cli

  - [ ] `add` `rm` for adding / removing sites to cohosting list via commandline
  - [ ] `sync` a command to run cohosting check (for use in `crond` etc)
  - [ ] `gc <n>` drop all old snapshots (if `n` is provided, keeps that many snapshots per site)

#### 🍎 [ipfs-cohost](https://github.com/olizilla/ipfs-cohost)
> NPM-based interactive cli tool

  - [ ] switch from `pin` to MFS-based spec

#### 🍎 [ipfs-companion](https://github.com/ipfs-shipyard/ipfs-companion)
  > browser extension

  - [ ] provides UI for adding / removing sites via browser action menu
  - [ ] runs cohosting check periodically

#### 🍎 [ipfs-desktop](https://github.com/ipfs-shipyard/ipfs-desktop)
  > desktop app and GUI for managing go-ipfs

  - [ ] runs cohosting check periodically

#### 🍎 [ipfs-webui](https://github.com/ipfs-shipyard/ipfs-webui)
  > web frontend for IPFS node

  - [ ] provides UI for adding / removing sites to cohosting list as an experiment on _Settings_ page
