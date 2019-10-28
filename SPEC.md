

# MFS cohosting SPEC (experimental draft)

> ### 🚧 this is not an official specification, just an early, exploratory experiment 🚧
>
> The goal is to see what is possible with the [mutable filesystem (MFS)](https://docs.ipfs.io/guides/concepts/mfs/), and what could be possible if we extend it.
>
> ⚠️ Feedback is welcome, PR or fill an issue!  ⚠️


* [Site identifiers](#site-identifiers)
* [Lazy and full cohosting](#lazy-and-full-cohosting)
* [Path conventions](#path-conventions)
* [Operations](#operations)
  * [Adding](#adding)
  * [Removing](#removing)
  * [Listing](#listing)
  * [Updating](#updating)
  * [Changing cohosting type](#changing-cohosting-type)
  * [Prune](#prune)

## Lazy and full cohosting

There are two modes of cohosting a website: `lazy` (default) and `full`.

- **Lazy** cohosting means that contents will be fetched on the first use. In other words, only the pages visited by the user are stored in local datastore and shared with the network. This mode is the safe default that enables cohosting of big websites such as Wikipedia (hundreds of gigabytes) on machines with limited disk space while enabling offline access to resources they previously visited.
- **Full** cohosting means the entire website should be fetched fully whenever a new snapshot is made. This mode should remain an opt-in: user needs to make an informed decision if they have enough storage to fit the entire thing in the local repository.

## Site identifiers

`/ipns/<site-id>` is a mutable pointer to immutable data.

Currently supported pointers:
- [CID](https://docs.ipfs.io/guides/concepts/cid/) of libp2p-key used by an   [IPNS](https://docs.ipfs.io/guides/concepts/ipns/) site (`/ipns/<libp2p-key>`)
- [FQDN](https://en.wikipedia.org/wiki/Fully_qualified_domain_name) with a [DNSLink](https://docs.ipfs.io/guides/concepts/dnslink/) (`/ipns/<domain-name>`)

## Path conventions

- `/cohosting` - presence of directory in MFS root enables cohosting logic.
- `/cohosting/lazy` - lazy cohosting directories.
- `/cohosting/full` - full cohosting directories.
- `/cohosting/<lazy|full>/<site-id>` - presence of directory enables update checks for this site.
- `/cohosting/<lazy|full>/<site-id>/<timestamp>` - site snapshot at a point in time.
  - `<timestamp>` format is `YYYY-MM-DD_hhmmss`  (zero-padded [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) in UTC)

## Operations

Below is a complete list of all operations needed for implementing this spec.
One can execute commands manually in shell or automate everything using programmatic interfaces.

Note: the following examples use `docs.ipfs.io` as a `<site-id>`

### Adding

```console
$ ipfs files mkdir -p /cohosting/<lazy|full>/docs.ipfs.io
```

### Removing

```console
$ ipfs files rm -r /cohosting/<lazy|full>/docs.ipfs.io
```

### Listing

```console
$ ipfs files ls /cohosting/<lazy|full>
docs.ipfs.io
libp2p.io
multiformats.io
```

### Updating

1. Get the list of cohosted sites
   ```console
   $ ipfs files ls /cohosting/<lazy|full>
   docs.ipfs.io
   libp2p.io
   multiformats.io
   ```
   Next: execute following steps for each `<site-id>`:

2. List existing snapshots, sort them lexicographically and read timestamp of the latest one
   ```console
   $ ipfs files ls /cohosting/<lazy|full>/docs.ipfs.io | sort | head -1
   2019-08-22_150420
   ```
   If timestamp is older than 12 hours, remember it and continue to step 3.
   Otherwise, do nothing and move to the next site.

3. Find the current CID of checked site
   ```console
   $ ipfs resolve -r /ipns/docs.ipfs.io
   /ipfs/Qmd41WqbCsfTx4wJvP6vvv3hHb46bEHG1hC6Kqt7mhGQUR
   ```

4. **If** it is a **fully** cohosted website, ensure contents are in the local repo:
   ```console
   $ ipfs refs --recursive /ipfs/Qmd41WqbCsfTx4wJvP6vvv3hHb46bEHG1hC6Kqt7mhGQUR   # blocking
   $ ipfs refs --recursive /ipfs/Qmd41WqbCsfTx4wJvP6vvv3hHb46bEHG1hC6Kqt7mhGQUR & # in the background
   ```

5. Copy it to MFS using current UTC time as `<timestamp>`
   ```console
   $ ipfs files cp /ipfs/Qmd41WqbCsfTx4wJvP6vvv3hHb46bEHG1hC6Kqt7mhGQUR /cohosting/<lazy|full>/docs.ipfs.io/2019-08-22_153940
   ```

6. (optional) Drop the previous snapshot (identified in step 2) if it points at the same CID
   * read the CID of the previous snapshot:
      ```console
      $ ipfs files stat /cohosting/<lazy|full>/docs.ipfs.io/2019-08-22_153940 | head -1
      Qmd41WqbCsfTx4wJvP6vvv3hHb46bEHG1hC6Kqt7mhGQUR
      ```
   * if the CID is the same as one from step 3, remove the snapshot (do nothing otherwise):
     ```console
     $  ipfs files rm /cohosting/<lazy|full>/docs.ipfs.io/2019-08-22_153940
     ```

### Changing cohosting type

When changing from `lazy` to `full` cohosting, simply move snapshots to the respective directory:

```console
$ ipfs files mv /cohosting/lazy/ipfs.io /cohosting/full/ipfs.io
```

Or the other way around.

### Pruning

The act of deleting old snapshots. To remove all snapshots for a certain domain:

```console
$ ipfs files rm -r /cohosting/<lazy|full>/ipfs.io
```

To remove all but the last _n_ snapshots:

```console
$ ipfs files ls /cohosting/<lazy|full>/ipfs.io | tail -r | tail -n +3
# For each snapshot
$ ipfs files ls /cohosting/<lazy|full>/ipfs.io/$snapshot
```
