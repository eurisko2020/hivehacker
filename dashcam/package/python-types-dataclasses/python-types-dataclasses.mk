################################################################################
#
# python-types-dataclasses
#
################################################################################

PYTHON_TYPES_DATACLASSES_VERSION = 0.6.6
PYTHON_TYPES_DATACLASSES_SOURCE = types-dataclasses-$(PYTHON_TYPES_DATACLASSES_VERSION).tar.gz
PYTHON_TYPES_DATACLASSES_SITE = https://files.pythonhosted.org/packages/4b/6a/dec8fbc818b1e716cb2d9424f1ea0f6f3b1443460eb6a70d00d9d8527360
PYTHON_TYPES_DATACLASSES_SETUP_TYPE = setuptools
PYTHON_TYPES_DATACLASSES_LICENSE = Apache-2.0
PYTHON_TYPES_DATACLASSES_LICENSE_FILES = LICENSE

$(eval $(python-package))