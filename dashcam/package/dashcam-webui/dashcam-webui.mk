################################################################################
#
# dashcam-webui
#
################################################################################

DASHCAM_WEBUI_VERSION = 1.0.0
DASHCAM_WEBUI_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src
DASHCAM_WEBUI_SITE_METHOD = local

DASHCAM_WEBUI_DEPENDENCIES = python3 python-flask nginx

define DASHCAM_WEBUI_INSTALL_TARGET_CMDS
	# Install Flask app
	$(INSTALL) -d $(TARGET_DIR)/opt/dashcam/webui
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/app.py \
		$(TARGET_DIR)/opt/dashcam/webui/app.py

	# Install all templates
	$(INSTALL) -d $(TARGET_DIR)/opt/dashcam/webui/templates
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/templates/base.html \
		$(TARGET_DIR)/opt/dashcam/webui/templates/base.html
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/templates/splash.html \
		$(TARGET_DIR)/opt/dashcam/webui/templates/splash.html
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/templates/index.html \
		$(TARGET_DIR)/opt/dashcam/webui/templates/index.html
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/templates/recordings.html \
		$(TARGET_DIR)/opt/dashcam/webui/templates/recordings.html
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/templates/settings.html \
		$(TARGET_DIR)/opt/dashcam/webui/templates/settings.html
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/templates/events.html \
		$(TARGET_DIR)/opt/dashcam/webui/templates/events.html
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/templates/firmware.html \
		$(TARGET_DIR)/opt/dashcam/webui/templates/firmware.html
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/templates/stream.html \
		$(TARGET_DIR)/opt/dashcam/webui/templates/stream.html

	# Install static files
	$(INSTALL) -d $(TARGET_DIR)/opt/dashcam/webui/static
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/static/style.css \
		$(TARGET_DIR)/opt/dashcam/webui/static/style.css
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/static/app.js \
		$(TARGET_DIR)/opt/dashcam/webui/static/app.js
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/src/static/logo.png \
		$(TARGET_DIR)/opt/dashcam/webui/static/logo.png

	# Install systemd service
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcam-webui/dashcam-webui.service \
		$(TARGET_DIR)/usr/lib/systemd/system/dashcam-webui.service
endef

$(eval $(generic-package))