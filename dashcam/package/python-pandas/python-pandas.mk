################################################################################
#
# python-pandas
#
################################################################################

PYTHON_PANDAS_VERSION = 2.0.3
PYTHON_PANDAS_SOURCE = pandas-$(PYTHON_PANDAS_VERSION).tar.gz
PYTHON_PANDAS_SITE = https://files.pythonhosted.org/packages/b1/a7/824332581e258b5aa4f3763ecb2a797e5f9a54269044ba2e50ac19936b32
PYTHON_PANDAS_SETUP_TYPE = setuptools
PYTHON_PANDAS_LICENSE = Apache-2.0
PYTHON_PANDAS_LICENSE_FILES = LICENSE

$(eval $(python-package))
