################################################################################
#
# python-ultralytics
#
################################################################################

PYTHON_ULTRALYTICS_VERSION = 8.0.157
PYTHON_ULTRALYTICS_SOURCE = ultralytics-$(PYTHON_ULTRALYTICS_VERSION).tar.gz
PYTHON_ULTRALYTICS_SITE = https://files.pythonhosted.org/packages/e6/bc/cdcd252339b67dd71c2c2e864402bfd80651a5fe5a024019f988f4c21da7
PYTHON_ULTRALYTICS_SETUP_TYPE = setuptools
PYTHON_ULTRALYTICS_LICENSE = Apache-2.0
PYTHON_ULTRALYTICS_LICENSE_FILES = LICENSE

$(eval $(python-package))
