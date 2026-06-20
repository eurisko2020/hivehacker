################################################################################
#
# onboard-updater
#
################################################################################

ONBOARD_UPDATER_VERSION = bac054b3659702e2b9eed0dc90038639a42d47f4
# Note that this is a private repo being accessed over SSH, so you need to have
# SSH keys setup for BitBucket.
ONBOARD_UPDATER_SITE = git@github.com:Hivemapper/hdc_background_updater.git
ONBOARD_UPDATER_SITE_METHOD = git
ONBOARD_UPDATER_DEPENDENCIES = python-transitions
ONBOARD_UPDATER_SETUP_TYPE = setuptools

define ONBOARD_UPDATER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/onboard-updater/onboard-updater.service \
		$(TARGET_DIR)/usr/lib/systemd/system/onboard-updater.service
endef

$(eval $(python-package))