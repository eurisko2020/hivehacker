################################################################################
#
# dashcamd
#
################################################################################

DASHCAMD_VERSION = 1.0.0
DASHCAMD_SITE = $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src
DASHCAMD_SITE_METHOD = local

DASHCAMD_DEPENDENCIES = python3 libcamera libcamera-apps ffmpeg libgpiod i2c-tools

define DASHCAMD_INSTALL_TARGET_CMDS
	# Install Python daemon and modules
	$(INSTALL) -d $(TARGET_DIR)/opt/dashcam/bin
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src/dashcamd.py \
		$(TARGET_DIR)/opt/dashcam/bin/dashcamd
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src/camera_worker.py \
		$(TARGET_DIR)/opt/dashcam/bin/camera_worker.py
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src/imu_worker.py \
		$(TARGET_DIR)/opt/dashcam/bin/imu_worker.py
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src/gps_worker.py \
		$(TARGET_DIR)/opt/dashcam/bin/gps_worker.py
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src/storage_worker.py \
		$(TARGET_DIR)/opt/dashcam/bin/storage_worker.py
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src/led_worker.py \
		$(TARGET_DIR)/opt/dashcam/bin/led_worker.py
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src/parking_worker.py \
		$(TARGET_DIR)/opt/dashcam/bin/parking_worker.py
	$(INSTALL) -D -m 755 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/src/config_loader.py \
		$(TARGET_DIR)/opt/dashcam/bin/config_loader.py

	# Install systemd service
	$(INSTALL) -D -m 644 $(BR2_EXTERNAL_DASHCAM_PATH)/package/dashcamd/dashcamd.service \
		$(TARGET_DIR)/usr/lib/systemd/system/dashcamd.service

	# Note: dashcamd.conf is installed via the board overlay at:
		# $(BR2_EXTERNAL_DASHCAM_PATH)/board/raspberrypicm4io_64_clean/overlays/common/etc/dashcamd.conf
endef

$(eval $(generic-package))