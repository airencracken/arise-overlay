# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="High-performance, self-healing package manager for Gentoo Linux"
HOMEPAGE="https://github.com/airencracken/arise"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/airencracken/arise.git"
	EGIT_BRANCH="master"
else
	SRC_URI="https://github.com/airencracken/arise/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64 ~arm64"
fi

LICENSE="GPL-3"
SLOT="0"

IUSE="man info"

RDEPEND="
	app-arch/bzip2
	app-arch/xz-utils
	app-arch/tar
	sys-apps/file
"
DEPEND="${RDEPEND}"
BDEPEND=">=dev-lang/go-1.21"

RESTRICT="mirror strip"
QA_FLAGS_IGNORED="usr/bin/arise"

src_compile() {
	CGO_ENABLED=0 go build \
		-mod=vendor \
		-trimpath \
		-ldflags="-s -w -X main.version=${PV}" \
		-o arise \
		./cmd/arise/ || die "build failed"
}

src_install() {
	dobin arise

	if use man; then
		doman arise.1
	fi

	if use info; then
		doinfo arise.info
	fi

	dodoc README.md
}

pkg_postinst() {
	elog "arise is installed. To initialize:"
	elog "  arise -repo-url <url> sync    # sync the gentoo repository"
	elog "  arise index                   # build metadata database"
	elog "  arise search <query>          # search packages (replaces eix)"
	elog "  arise install -av <pkg>       # install a package"
	elog ""
	elog "See arise(1) or arise.info for full documentation."
}
