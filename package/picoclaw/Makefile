#
# PicoClaw package for OpenWrt
# Includes pre-compiled binaries
#

include $(TOPDIR)/rules.mk

PKG_NAME:=picoclaw
PKG_VERSION:=0.2.4
PKG_RELEASE:=1

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE

include $(INCLUDE_DIR)/package.mk

define Package/picoclaw
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Ultra-Efficient AI Assistant
  URL:=https://github.com/sipeed/picoclaw
  DEPENDS:=+ca-certificates @(aarch64||x86_64)
endef

define Package/picoclaw/description
  PicoClaw is an ultra-lightweight personal AI assistant written in Go.
  Runs on hardware with <10MB RAM. Includes pre-compiled binaries.
endef

define Package/picoclaw/conffiles
/etc/picoclaw/config.yml
/etc/config/picoclaw
endef

# Set download URLs based on architecture - download tar.gz archives
PICOCLAW_URL_arm64:=https://github.com/sipeed/picoclaw/releases/download/v$(PKG_VERSION)/picoclaw_Linux_arm64.tar.gz
PICOCLAW_URL_x86_64:=https://github.com/sipeed/picoclaw/releases/download/v$(PKG_VERSION)/picoclaw_Linux_x86_64.tar.gz

# Select URLs based on CONFIG_ARCH
ifeq ($(CONFIG_ARCH),"aarch64")
  PICOCLAW_URL=$(PICOCLAW_URL_arm64)
else ifeq ($(CONFIG_ARCH),"arm64")
  PICOCLAW_URL=$(PICOCLAW_URL_arm64)
else ifeq ($(CONFIG_ARCH),"x86_64")
  PICOCLAW_URL=$(PICOCLAW_URL_x86_64)
else
  $(error Unsupported architecture: $(CONFIG_ARCH). Only aarch64/arm64 and x86_64 are supported)
endif

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
	# Download and extract pre-compiled binaries during build
	echo "=================================================================="
	echo "PicoClaw Build - Downloading and extracting binaries"
	echo "=================================================================="
	echo "Target Architecture: $(CONFIG_ARCH)"
	echo "PicoClaw URL: $(PICOCLAW_URL)"
	echo "=================================================================="

	# Create bin and temp directory
	mkdir -p $(PKG_BUILD_DIR)/bin
	mkdir -p $(PKG_BUILD_DIR)/tmp

	# Download tar.gz archive if not already cached
	if [ ! -f $(PKG_BUILD_DIR)/tmp/picoclaw.tar.gz ]; then \
		echo ">>> Downloading picoclaw tar.gz..."; \
		wget -O $(PKG_BUILD_DIR)/tmp/picoclaw.tar.gz "$(PICOCLAW_URL)" || { \
			echo "ERROR: Failed to download picoclaw archive"; \
			rm -f $(PKG_BUILD_DIR)/tmp/picoclaw.tar.gz; \
			exit 1; \
		}; \
		echo ">>> Download successful"; \
	else \
		echo ">>> Archive already downloaded, skipping download"; \
	fi

	# Extract binaries from tar.gz
	echo ">>> Extracting binaries..."
	tar -xzf $(PKG_BUILD_DIR)/tmp/picoclaw.tar.gz -C $(PKG_BUILD_DIR)/tmp/ || { \
		echo "ERROR: Failed to extract archive"; \
		exit 1; \
	}

	# Copy and set permissions for picoclaw
	if [ -f $(PKG_BUILD_DIR)/tmp/picoclaw ]; then \
		cp $(PKG_BUILD_DIR)/tmp/picoclaw $(PKG_BUILD_DIR)/bin/picoclaw; \
		chmod +x $(PKG_BUILD_DIR)/bin/picoclaw; \
		echo ">>> picoclaw extracted successfully"; \
	else \
		echo "ERROR: picoclaw binary not found in archive"; \
		exit 1; \
	fi

	# Copy and set permissions for picoclaw-launcher
	if [ -f $(PKG_BUILD_DIR)/tmp/picoclaw-launcher ]; then \
		cp $(PKG_BUILD_DIR)/tmp/picoclaw-launcher $(PKG_BUILD_DIR)/bin/picoclaw-launcher; \
		chmod +x $(PKG_BUILD_DIR)/bin/picoclaw-launcher; \
		echo ">>> picoclaw-launcher extracted successfully"; \
	else \
		echo "ERROR: picoclaw-launcher binary not found in archive"; \
		exit 1; \
	fi

	@echo "=================================================================="
	@echo "All binaries extracted successfully!"
	@echo "=================================================================="
	@ls -lh $(PKG_BUILD_DIR)/bin/
endef

define Package/picoclaw/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/picoclaw $(1)/usr/bin/picoclaw
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/picoclaw-launcher $(1)/usr/bin/picoclaw-launcher
	$(INSTALL_BIN) ./files/picoclaw-public $(1)/usr/bin/picoclaw-public

	$(INSTALL_DIR) $(1)/etc/picoclaw
	$(INSTALL_CONF) ./files/config.yml $(1)/etc/picoclaw/config.yml

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/uciron $(1)/etc/config/picoclaw

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/picoclaw.init $(1)/etc/init.d/picoclaw
endef

$(eval $(call BuildPackage,picoclaw))
