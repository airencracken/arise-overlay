# Local Portage development

The local workflow packages the current Arise working tree in a disposable
overlay, then asks Portage to build it exactly as an ebuild. It does not modify
the registered overlay in `/var/db/repos` or the system distfiles directory.

```sh
cd /path/to/arise-overlay

# Run manifest, unpack, compile, install-to-image, and binpkg phases.
make local-build

# Merge the same development version onto this machine.
make local-install

# Remove disposable state and the dependency cache.
make local-clean
```

The dependency archive is cached under `/tmp/arise-local` using a digest of
`go.mod` and `go.sum`. Editing Go source only rebuilds the source archive;
changing dependencies regenerates the larger dependency archive.

Useful overrides:

```sh
make local-build ARISE_SOURCE_DIR=/path/to/arise
ARISE_LOCAL_STATE=/var/tmp/arise-local make local-build
```

`local-build` does not merge files into `/`. `local-install` is the explicit
system-changing step. When run as a normal user, both commands invoke `su` for
the Portage phases; when run from a root shell, they execute `ebuild` directly.
Custom state directories must be absolute and have an `arise-*` basename.
