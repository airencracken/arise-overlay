VERSION ?= 0.1.0
OWNER   ?= airencracken
REPO    ?= arise
GITHUB  ?= https://github.com
SRC_URI ?= $(GITHUB)/$(OWNER)/$(REPO)/archive/v$(VERSION).tar.gz

.PHONY: manifest release clean

manifest:
	@echo "Fetching $(SRC_URI)..."
	@curl -sL '$(SRC_URI)' -o /tmp/arise-$(VERSION).tar.gz || \
		{ echo "Failed to download tarball. Is v$(VERSION) tagged?"; exit 1; }
	@echo "Computing checksums..."
	@SIZE=$$(stat -c %s /tmp/arise-$(VERSION).tar.gz); \
	 SHA256=$$(sha256sum /tmp/arise-$(VERSION).tar.gz | cut -d' ' -f1); \
	 SHA512=$$(sha512sum /tmp/arise-$(VERSION).tar.gz | cut -d' ' -f1); \
	 BLAKE2B=$$(b2sum /tmp/arise-$(VERSION).tar.gz | cut -d' ' -f1); \
	 EB_256=$$(sha256sum sys-apps/$(REPO)/arise-$(VERSION).ebuild | cut -d' ' -f1); \
	 EB_512=$$(sha512sum sys-apps/$(REPO)/arise-$(VERSION).ebuild | cut -d' ' -f1); \
	 EB_B2=$$(b2sum sys-apps/$(REPO)/arise-$(VERSION).ebuild | cut -d' ' -f1); \
	 EB_SZ=$$(stat -c %s sys-apps/$(REPO)/arise-$(VERSION).ebuild); \
	 LIVE_256=$$(sha256sum sys-apps/$(REPO)/arise-9999.ebuild | cut -d' ' -f1); \
	 LIVE_512=$$(sha512sum sys-apps/$(REPO)/arise-9999.ebuild | cut -d' ' -f1); \
	 LIVE_B2=$$(b2sum sys-apps/$(REPO)/arise-9999.ebuild | cut -d' ' -f1); \
	 LIVE_SZ=$$(stat -c %s sys-apps/$(REPO)/arise-9999.ebuild); \
	 echo "DIST arise-$(VERSION).tar.gz $$SIZE BLAKE2B $$BLAKE2B SHA512 $$SHA512 SHA256 $$SHA256" > sys-apps/$(REPO)/Manifest; \
	 echo "EBUILD arise-$(VERSION).ebuild $$EB_SZ BLAKE2B $$EB_B2 SHA512 $$EB_512 SHA256 $$EB_256" >> sys-apps/$(REPO)/Manifest; \
	 echo "EBUILD arise-9999.ebuild $$LIVE_SZ BLAKE2B $$LIVE_B2 SHA512 $$LIVE_512 SHA256 $$LIVE_256" >> sys-apps/$(REPO)/Manifest
	@echo "Manifest updated."
	@rm -f /tmp/arise-$(VERSION).tar.gz

release: manifest
	@echo "Ready to release arise v$(VERSION)"
	@echo "  1. git add sys-apps/$(REPO)/Manifest sys-apps/$(REPO)/arise-$(VERSION).ebuild"
	@echo "  2. git commit -m 'release v$(VERSION)'"
	@echo "  3. git push"
	@echo ""
	@echo "In the main arise repo:"
	@echo "  git tag v$(VERSION) && git push --tags"

clean:
	rm -f /tmp/arise-*.tar.gz
