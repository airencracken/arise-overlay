VERSION ?= 0.0.26
PACKAGE ?= arise
DISTDIR ?= /tmp/arise-overlay-distfiles-$(VERSION)

.PHONY: manifest clean check check-go-version local-prepare local-build local-install local-clean

ARISE_SOURCE_DIR ?= $(abspath ../arise)

check:
	./scripts/check-overlay.sh

check-go-version:
	@GO_VERSION=$$(awk '$$1 == "go" { print $$2; exit }' "$(ARISE_SOURCE_DIR)/go.mod"); \
	grep -q ">=dev-lang/go-$$GO_VERSION" sys-apps/arise/arise-9999.ebuild || { \
		echo "Go version mismatch: go.mod requires $$GO_VERSION; update arise-9999.ebuild BDEPEND"; \
		exit 1; \
	}

local-prepare: check-go-version
	ARISE_SOURCE_DIR="$(ARISE_SOURCE_DIR)" ./scripts/local-portage.sh prepare

local-build: check-go-version
	ARISE_SOURCE_DIR="$(ARISE_SOURCE_DIR)" ./scripts/local-portage.sh build

local-install: check-go-version
	ARISE_SOURCE_DIR="$(ARISE_SOURCE_DIR)" ./scripts/local-portage.sh install

local-clean:
	./scripts/local-portage.sh clean

manifest:
	@test -f sys-apps/$(PACKAGE)/$(PACKAGE)-$(VERSION).ebuild || { \
		echo "Missing sys-apps/$(PACKAGE)/$(PACKAGE)-$(VERSION).ebuild"; exit 1; }
	mkdir -p "$(DISTDIR)"
	DISTDIR="$(DISTDIR)" ebuild \
		sys-apps/$(PACKAGE)/$(PACKAGE)-$(VERSION).ebuild manifest
	@echo "Manifest updated through Portage."

clean:
	@case "$(notdir $(DISTDIR))" in \
		arise-overlay-distfiles*) ;; \
		*) echo "Refusing to clean non-Arise DISTDIR=$(DISTDIR)"; exit 1 ;; \
	esac
	rm -rf -- "$(DISTDIR)"
