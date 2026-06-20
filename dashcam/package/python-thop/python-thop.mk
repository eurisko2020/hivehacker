################################################################################
#
# python-thop
#
################################################################################

PYTHON_THOP_VERSION = 0.1.1.post2209072238
PYTHON_THOP_SOURCE = thop-$(PYTHON_THOP_VERSION)-py3-none-any.whl
PYTHON_THOP_SITE = https://files.pythonhosted.org/packages/f2/8d/6244e0a9c257cbf16c9904af249e72d530bc03185ce60a0f5af812dadbbd
PYTHON_THOP_SETUP_TYPE = setuptools
PYTHON_THOP_LICENSE = Apache-2.0
PYTHON_THOP_LICENSE_FILES = LICENSE

$(eval $(python-package))
