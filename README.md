# Arise Gentoo overlay

This is the maintained Gentoo packaging repository for
[Arise](https://github.com/airencracken/arise).

## Add the repository

With `app-eselect/eselect-repository` installed:

```bash
eselect repository add arise-overlay git \
  https://github.com/airencracken/arise-overlay.git
emaint sync -r arise-overlay
```

Or create `/etc/portage/repos.conf/arise-overlay.conf`:

```ini
[arise-overlay]
location = /var/db/repos/arise-overlay
sync-type = git
sync-uri = https://github.com/airencracken/arise-overlay.git
auto-sync = yes
```

Then install:

```bash
emerge --ask sys-apps/arise
```

The versioned package builds without network access using a small,
release-bound vendor archive from
[`arise-overlay-assets`](https://github.com/airencracken/arise-overlay-assets).
The ebuild verifies the archive's provenance manifest against its source
commit and module metadata before compiling with `GOPROXY=off`.

The `9999` ebuild follows the main branch and is intended for development.
Arise remains experimental and the versioned release is testing-keyworded for
`~amd64`; keep Portage installed as the reference and recovery implementation.

## USE flags

- `info`: build and install the GNU Info manual where the release supports it;
- `pie`: build a position-independent executable instead of the default
  standalone recovery binary.
- `rsync`: install the optional rsync repository transport.
- `test`: run the upstream non-live test suite.

The default binary is statically linked. The ebuild explicitly selects Go's
executable build mode instead of Gentoo's normal PIE default, keeping the Arise
recovery control plane independent of the host dynamic loader and
shared-library state. Users who prefer Gentoo's normal hardening tradeoff can
enable `pie`. The man page and Bash completion are always installed.

See `USE_FLAGS.md` for the longer-term capability policy.
Core archive formats currently use the system `tar`, `xz`, and `bzip2` tools;
the long-term direction is native Go implementations and removal of those
runtime dependencies, not optional format USE flags.

## Maintenance

```bash
make check
make manifest VERSION=0.0.1
make local-build ARISE_SOURCE_DIR=/path/to/arise
```

`make local-build` exercises the current source through Portage in disposable
state without merging it. `make local-install` is the explicit live-system
mutation step. See `LOCAL_DEVELOPMENT.md`.

After publishing an immutable source release, prepare its overlay entry with
the full tagged commit:

```bash
scripts/prepare-release.sh 0.0.4 5a9f219403533bd43146dbecaf4dafa9edd52f3e
```

The script validates its inputs, atomically creates the pinned ebuild from the
maintained vendor template, updates the Makefile default, regenerates the Manifest
and metadata cache, and runs overlay QA. Use `--prepare-only` as the third
argument only when intentionally deferring derived metadata generation.

Release order:

1. test, tag, and publish the corresponding Arise source release;
2. publish its vendor archive in `arise-overlay-assets`;
3. add the versioned ebuild and generate its Manifest through Portage;
4. pass local checks, `pkgcheck`, and an offline package build;
5. commit and push the overlay release.

Published tags and dependency archives are immutable. Fix a bad release with a
new patch version rather than replacing its inputs.
