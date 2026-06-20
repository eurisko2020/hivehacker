################################################################################
#
# python-hypothesis
#
################################################################################

PYTHON_HYPOTHESIS_VERSION = 6.82.6
PYTHON_HYPOTHESIS_SOURCE = hypothesis-$(PYTHON_HYPOTHESIS_VERSION).tar.gz
PYTHON_HYPOTHESIS_SITE = https://files.pythonhosted.org/packages/6d/3a/543cc05753e7fde9cf85e14d9210fc97664e7f870ca5cb45f1c7481f9cac
PYTHON_HYPOTHESIS_SETUP_TYPE = setuptools
PYTHON_HYPOTHESIS_LICENSE = Apache-2.0
PYTHON_HYPOTHESIS_LICENSE_FILES = LICENSE

$(eval $(python-package))