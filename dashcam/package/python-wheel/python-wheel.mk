################################################################################
#
# python-wheel
#
################################################################################

PYTHON_WHEEL_VERSION = 0.41.1
PYTHON_WHEEL_SOURCE = wheel-$(PYTHON_WHEEL_VERSION).tar.gz
PYTHON_WHEEL_SITE = https://files.pythonhosted.org/packages/c9/3d/02a14af2b413d7abf856083f327744d286f4468365cddace393a43d9d540
PYTHON_WHEEL_SETUP_TYPE = flit
PYTHON_WHEEL_LICENSE = Apache-2.0
PYTHON_WHEEL_LICENSE_FILES = LICENSE

$(eval $(python-package))
$(eval $(host-python-package))
