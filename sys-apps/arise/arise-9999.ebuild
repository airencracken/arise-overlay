# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit shell-completion go-module

DESCRIPTION="Live experimental high-performance package manager for Gentoo"
HOMEPAGE="https://github.com/airencracken/arise"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/airencracken/arise.git"
	EGIT_BRANCH="master"
else
	SRC_URI="
		https://github.com/airencracken/arise/archive/v${PV}.tar.gz -> ${P}.tar.gz
		https://github.com/airencracken/arise/releases/download/v${PV}/${P}-deps.tar.xz
	"
fi

LICENSE="GPL-3 Apache-2.0 BSD BSD-2 MIT MPL-2.0"
SLOT="0"
IUSE="info pie rsync test"

RDEPEND="
	app-arch/bzip2
	app-arch/tar
	app-arch/xz-utils
	app-shells/bash
	rsync? ( net-misc/rsync )
	sys-apps/portage
	sys-apps/sandbox
	sys-apps/util-linux
"
BDEPEND="
	>=dev-lang/go-1.26.3
	sys-apps/file
	info? ( sys-apps/texinfo )
"

RESTRICT="!test? ( test )"

src_unpack() {
	if [[ ${PV} == 9999 ]]; then
		git-r3_src_unpack
		go-module_live_vendor
	else
		go-module_src_unpack
	fi
}

src_compile() {
	local buildmode=exe
	local linkage
	use pie && buildmode=pie

	CGO_ENABLED=0 ego build \
		-buildmode="${buildmode}" \
		-buildvcs=false \
		-trimpath \
		-ldflags="-X main.version=${PV}" \
		-o arise \
		./cmd/arise/

	linkage=$(file arise) || die "could not inspect built binary"
	if use pie; then
		[[ ${linkage} == *"pie executable"* ]] ||
			die "pie build must produce a PIE executable: ${linkage}"
	else
		[[ ${linkage} == *"statically linked"* ]] ||
			die "recovery build must produce a statically linked executable: ${linkage}"
	fi

	if use info; then
		texi2any --info arise.texi -o arise.info ||
			die "Info generation failed"
	fi
}

src_test() {
	mkdir -p "${T}/test-home" || die "could not create isolated test home"
	env -i \
		GOCACHE="${GOCACHE}" \
		GOMODCACHE="${GOMODCACHE}" \
		GOPROXY=off \
		HOME="${T}/test-home" \
		PATH="${PATH}" \
		TMPDIR="${T}" \
		go test ./... -timeout 120s
}

src_install() {
	dobin arise
	doman arise.1
	use info && doinfo arise.info
	dodoc README.md LICENSE
	newbashcomp misc/arise-completion.bash arise
}

pkg_postinst() {
	elog "This is the live Arise ebuild. Keep Portage installed as the reference and recovery implementation."
}
