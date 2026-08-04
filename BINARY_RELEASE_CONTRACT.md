# Arise binary release contract

`sys-apps/arise-bin` installs the official static Arise release artifact. It is
intended for fresh-stage3 bootstrapping, constrained machines, and recovery
media which should not need a Go toolchain merely to install the package
manager.

## Bundle identity

The amd64 release asset is named:

```text
arise-bin-${version}-linux-amd64.tar.xz
```

It expands into the same-named directory containing exactly the maintained
payload classes:

```text
arise
arise.1
arise-completion.bash
arise-artifact-manifest.json
README.md
LICENSE
```

The release manager produces the archive reproducibly from the tagged source
commit. The embedded manifest records its schema version, Arise version,
source commit, GOOS, GOARCH, Go toolchain identity, build mode, binary SHA-256,
and the source-date epoch. The release process verifies the manifest against
the binary before upload.

The overlay Manifest remains the package-manager download-integrity authority.
The embedded manifest supplies provenance and review evidence; it does not
replace the overlay Manifest or repository trust.

## Binary requirements

- `arise --version` must print exactly the ebuild version.
- The amd64 artifact must be a stripped, statically linked, 64-bit x86-64 ELF
  executable built with `CGO_ENABLED=0` and deterministic Go build flags.
- The bundle must contain the matching manual, Bash completion, license,
  README, and provenance manifest.
- The ebuild uses `RESTRICT="strip"` so Portage does not rewrite the published
  and checksummed binary.
- Each additional architecture receives a distinct asset and explicit ebuild
  validation before it is keyworded. No runtime architecture guessing or
  cross-architecture fallback is allowed.

## Package relationship

`sys-apps/arise-bin` and source-built `sys-apps/arise` install the same command
and are mutually exclusive. The binary ebuild blocks the source package; the
source ebuild must gain the reciprocal blocker in the same overlay release
which first publishes `arise-bin`.

Both packages retain Portage, sandbox, and the runtime archive utilities. The
binary package removes only the Go compiler, source archive, vendor archive,
and compilation work from bootstrap requirements.

## Publication gate

Do not publish or Manifest an `arise-bin` ebuild until all of these refer to the
same final commit and version:

1. tagged source archive;
2. source ebuild and vendor archive;
3. binary bundle and embedded provenance manifest;
4. release ledger and checksums;
5. live fresh-stage3 validation evidence.

Before publication, test a clean binary install, source-to-binary and
binary-to-source replacement, `arise --version`, `arise --pretend`, repository
sync, JSON output, and one real package transaction. A failed validation must
not leave a partial binary package or a source/binary file collision.
