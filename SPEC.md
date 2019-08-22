# cohosting SPEC

* [Site identifiers](#site-identifiers)
* [Path conventions](#path-conventions)
* [Operations](#operations)
  * [Adding](#adding)
  * [Removing](#removing)
  * [Updating](#updating)


## Site identifiers

`/ipns/<site-id>` is a mutable pointer to immutable data.

Currently supported pointers:
- [CID](https://docs.ipfs.io/guides/concepts/cid/) of libp2p-key used by an   [IPNS](https://docs.ipfs.io/guides/concepts/ipns/) site (`/ipns/<libp2p-key>`)
- [FQDN](https://en.wikipedia.org/wiki/Fully_qualified_domain_name) with a [DNSLink](https://docs.ipfs.io/guides/concepts/dnslink/) (`/ipns/<domain-name>`)

## Path conventions

- `/cohosting` - presence of directory in MFS root enables cohosting logic
- `/cohosting/<site-id>` - presence of directory enables update checks for this site
- `/cohosting/<site-id>/<timestamp>` - site snapshot at a point in time
  - `<timestamp>` format is `YYYY-MM-DD_hhmmss`  (zero-padded [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601) in UTC)

## Operations

Below is a complete list of all operations needed for implementing this spec.  
One can execute commands manually in shell or automate everything using programmatic interfaces.

Note: the following examples use `docs.ipfs.io` as a `<site-id>`

### Adding

```console
$ ipfs files mkdir -p /cohosting/docs.ipfs.io
```

### Removing

```console
$ ipfs files rm  /cohosting/docs.ipfs.io
```

### Updating

1. Get the list of cohosted sites
   ```console
   $ ipfs files ls /cohosting
   docs.ipfs.io
   libp2p.io
   multiformats.io
   ```
   Next: execute following steps for each `<site-id>`:

2. List existing snapshots, sort them lexicographically and read timestamp of the latest one
   ```console
   $ ipfs files ls /cohosting/docs.ipfs.io | sort | head -1
   2019-08-22_150420
   ```
   If timestamp is older than 12 hours, remember it and continue to step 3.
   Otherwise, do nothing and move to the next site.

3. Find the current CID of checked site
   ```console
   $ ipfs resolve -r /ipns/docs.ipfs.io
   /ipfs/Qmd41WqbCsfTx4wJvP6vvv3hHb46bEHG1hC6Kqt7mhGQUR
   ```

4. Copy it to MFS using current UTC time as `<timestamp>`
   ```console
   $ ipfs files cp /ipfs/Qmd41WqbCsfTx4wJvP6vvv3hHb46bEHG1hC6Kqt7mhGQUR /cohosting/docs.ipfs.io/2019-08-22_153940
   ```
5. (optional) Drop the previous snapshot (identified in step 2) if it points at the same CID
   * read the CID of the previous snapshot:
      ```console
      $ ipfs files stat /cohosting/docs.ipfs.io/2019-08-22_153940 | head -1
      Qmd41WqbCsfTx4wJvP6vvv3hHb46bEHG1hC6Kqt7mhGQUR
      ```
   * if the CID is the same as one from step 3, remove the snapshot (do nothing otherwise):
     ```console
     $  ipfs files rm /cohosting/docs.ipfs.io/2019-08-22_153940
     ```
