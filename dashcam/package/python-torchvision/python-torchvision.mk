################################################################################
#
# python-torchvision
#
################################################################################

PYTHON_TORCHVISION_VERSION = 0.15.2
PYTHON_TORCHVISION_SOURCE = v$(PYTHON_TORCHVISION_VERSION).tar.gz
PYTHON_TORCHVISION_SITE = https://github.com/pytorch/vision/archive/refs/tags
PYTHON_TORCHVISION_SETUP_TYPE = setuptools
PYTHON_TORCHVISION_LICENSE = Apache-2.0
PYTHON_TORCHVISION_LICENSE_FILES = LICENSE

$(eval $(python-package))
