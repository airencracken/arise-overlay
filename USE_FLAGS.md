# Arise USE flag roadmap

USE flags must correspond to a real optional capability, dependency boundary,
or build-time behavior. Runtime preferences such as color and job count do not
belong in the ebuild's USE surface.

## Current flags

- `info`: build and install the GNU Info manual.
- `rsync`: install `net-misc/rsync` for rsync repository transport.
- `test`: run the upstream unit, adversarial, and non-live integration suite
  through Portage's standard test phase.

The supported Arise build is always a verified `CGO_ENABLED=0` static binary;
this recovery property is not optional and therefore is not a USE flag. The
`arise(1)` manual page and Bash completion are also baseline package contents.

## Planned capability flags

- `isolation`: enable the production process/filesystem isolation backend,
  expected to use `sys-apps/bubblewrap`. Add this only when normal Arise
  execution has a stable bubblewrap contract.
- `snapshots`: enable backend-neutral transactional filesystem snapshot
  integration, if Arise develops useful behavior independent of a particular
  filesystem or volume manager.
- `btrfs`: enable Btrfs snapshot support through `sys-fs/btrfs-progs`.
- `lvm`: enable LVM thin-snapshot support through `sys-fs/lvm2`.
- `zfs`: enable ZFS snapshot support through `sys-fs/zfs`.
- `binpkg`: enable optional binary-package creation and consumption if it gains
  a meaningful compile-time or dependency boundary.
- `signing`: enable signed plans, repositories, snapshots, or binary packages
  through a defined signing backend.
- `seccomp`: enable syscall filtering if it is implemented as a capability
  separate from the main isolation backend.
- `systemd`: install optional services or timers if Arise eventually ships
  them.
- `doc`: generate and install extended documentation beyond the unconditional
  manual page and README.

Snapshot backend flags should be used directly unless a backend-neutral
`snapshots` mode exists. Avoid allowing `snapshots` with no usable backend.

Once production-ready, `isolation` and at least one appropriate snapshot
backend are candidates for default-on flags.

## Standard Gentoo behavior

The standard `test` flag should control the upstream test suite through
`src_test` and `RESTRICT`, rather than a package-local replacement flag.

## Deliberate non-flags

- `man`: the primary manual page is baseline package documentation.
- `static`: the standalone recovery build is baseline behavior, not an optional
  capability.
- `git`: Arise has a built-in Git implementation; the external executable is
  an optimization rather than a required feature.
- `python` and `perl`: audit commands should detect optional host runtimes and
  report their absence without forcing global runtime dependencies.
- `color` and `parallel`: these are runtime configuration.
- `sqlite` and `badger`: these remain internal implementation details unless
  Arise offers interchangeable compiled storage backends.
- `xz`, `bzip2`, and similar package-format compression support: formats needed
  for normal package-manager operation are core dependencies, not optional
  features. They currently use the system archive tools and therefore remain
  unconditional runtime dependencies. The long-term goal is to replace those
  subprocess paths with native Go implementations where mature,
  format-compatible libraries exist, then remove the corresponding external
  dependencies rather than turn them into USE flags.
