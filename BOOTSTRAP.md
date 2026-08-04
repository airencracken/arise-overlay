# Fresh stage3 bootstrap handoff

This overlay installs Arise onto an existing Gentoo stage3. It does not replace
the stage3 toolchain or claim a stage1 bootstrap. Keep Portage installed as the
reference and recovery path.

If Git and `eselect-repository` are the only missing registration tools, the
complete initial handoff is:

```sh
emerge --oneshot dev-vcs/git app-eselect/eselect-repository
eselect repository add arise-overlay git \
  https://github.com/airencracken/arise-overlay.git
emaint sync -r arise-overlay
mkdir -p /etc/portage/package.accept_keywords
printf '%s\n' 'sys-apps/arise-bin ~amd64' \
  >> /etc/portage/package.accept_keywords/arise
emerge --ask sys-apps/arise-bin
```

The release is intentionally testing-keyworded. Do not use `ACCEPT_KEYWORDS` on
the command line for the whole dependency transaction; scope the exception to
`sys-apps/arise-bin` as shown above. The binary package avoids installing Go
and avoids compiling Arise on the new system.

To build Arise locally instead, keyword and emerge `sys-apps/arise`. The source
package supports the optional `pie` USE flag; the bootstrap binary is the
static recovery-oriented release artifact. The packages are mutually
exclusive because both install `/usr/bin/arise`.

The versioned source ebuild uses two immutable inputs: the tagged source archive and a
vendor archive from `arise-overlay-assets`. Portage fetches both, the ebuild
verifies vendor provenance, and the Go compile and test phases run with
`GOPROXY=off`. The initial emerge may still install the ebuild's declared build
and runtime dependencies from the Gentoo repository.

After installation, verify and hand repository management to Arise:

```sh
arise --version
arise sync
arise --pretend --verbose --update --deep --newuse --complete-graph \
  --with-bdeps=y --backtrack=20 update @world
```

Take a VPS snapshot before approving a live world transaction. The full
frozen-plan, recovery, validation, and reboot workflow is maintained in the
upstream [fresh-stage3 runbook](https://github.com/airencracken/arise/blob/master/docs/fresh-stage3.md).
