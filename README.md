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

For a minimal, newly unpacked stage3, use the tested
[bootstrap handoff](BOOTSTRAP.md). It documents the testing keyword, the exact
Portage boundary, and the first Arise commands.

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

Cross-repository releases are prepared, verified, and published by the
dedicated [arise-release](https://github.com/airencracken/arise-release)
manager:

```bash
arise-release prepare 0.0.10
arise-release verify 0.0.10
arise-release publish 0.0.10
```

This repository retains Manifest generation, metadata cache, package QA, and
local Portage build primitives that intrinsically belong to the overlay. The
release manager owns the versioned ebuild template as well as tagging,
publishing, asset uploads, and cross-repository coordination.

Published tags and dependency archives are immutable. Fix a bad release with a
new patch version rather than replacing its inputs.
