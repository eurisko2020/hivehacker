################################################################################
#
# python-seaborn
#
################################################################################

PYTHON_SEABORN_VERSION = 0.12.2
PYTHON_SEABORN_SOURCE = seaborn-$(PYTHON_SEABORN_VERSION).tar.gz
PYTHON_SEABORN_SITE = https://files.pythonhosted.org/packages/8a/77/5cde8bc47df770486acf64f550839b4136d1696e5e4d57ce33fa1823972b
PYTHON_SEABORN_SETUP_TYPE = setuptools
PYTHON_SEABORN_LICENSE = Apache-2.0
PYTHON_SEABORN_LICENSE_FILES = LICENSE

$(eval $(python-package))
