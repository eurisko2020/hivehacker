################################################################################
#
# python-astunparse
#
################################################################################

PYTHON_ASTUNPARSE_VERSION = 1.6.3
PYTHON_ASTUNPARSE_SOURCE = astunparse-$(PYTHON_ASTUNPARSE_VERSION).tar.gz
PYTHON_ASTUNPARSE_SITE = https://files.pythonhosted.org/packages/f3/af/4182184d3c338792894f34a62672919db7ca008c89abee9b564dd34d8029
PYTHON_ASTUNPARSE_SETUP_TYPE = setuptools
PYTHON_ASTUNPARSE_LICENSE = Apache-2.0
PYTHON_ASTUNPARSE_LICENSE_FILES = LICENSE

$(eval $(python-package))