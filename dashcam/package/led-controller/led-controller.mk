################################################################################
#
# led-controller
#
################################################################################

LED_CONTROLLER_VERSION = 3b7e55af23cc40b5d4b53b0640b0db8ac8d464c9
LED_CONTROLLER_SITE = git@github.com:Hivemapper/capable_camera_firmware.git
LED_CONTROLLER_SITE_METHOD = git
LED_CONTROLLER_CONF_OPTS = -DCMAKE_INSTALL_PREFIX="/opt/dashcam" \
						-DINSTALL_CONFIG_FILES_PATH="/opt/dashcam/bin/"
LED_CONTROLLER_DEPENDENCIES = boost json-for-modern-cpp
LED_CONTROLLER_MAKE_OPTS = led-controller

define LED_CONTROLLER_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/led-controller/led-controller.service \
		$(TARGET_DIR)/usr/lib/systemd/system/led-controller.service
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/led-controller/led-controller-config.txt \
		$(TARGET_DIR)/opt/dashcam/led-controller-config.txt
endef

$(eval $(cmake-package))
