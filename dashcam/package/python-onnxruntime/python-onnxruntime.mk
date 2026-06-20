################################################################################
#
# python-onnxruntime
#
################################################################################

PYTHON_ONNXRUNTIME_VERSION = 1.15.1
PYTHON_ONNXRUNTIME_SOURCE = v$(PYTHON_ONNXRUNTIME_VERSION).tar.gz
PYTHON_ONNXRUNTIME_SITE = https://github.com/microsoft/onnxruntime/archive/refs/tags
PYTHON_ONNXRUNTIME_LICENSE = Apache-2.0
PYTHON_ONNXRUNTIME_LICENSE_FILES = LICENSE

define PYTHON_ONNXRUNTIME_BUILD_CMDS
	echo "Build ONNXRuntime"
	echo $(which python)
	# /home/eduard/git/hdc_firmware/output/build/python-onnxruntime-1.15.1/
	cd /home/eduard/git/hdc_firmware/output/build/python-onnxruntime-1.15.1/; ./build.sh --allow_running_as_root --skip_submodule_sync --config Release --build_wheel --update --build --parallel --cmake_extra_defines ONNXRUNTIME_VERSION=1.15.1
	# $(TARGET_DIR)
endef

define PYTHON_ONNXRUNTIME_INSTALL_TARGET_CMDS
	echo "Install ONNXRuntime"
	$(INSTALL) 
endef

$(eval $(generic-package))
