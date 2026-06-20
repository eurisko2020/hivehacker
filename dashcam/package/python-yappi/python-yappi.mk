################################################################################
#
# python-yappi
#
################################################################################

PYTHON_YAPPI_VERSION = 1.4.0
PYTHON_YAPPI_SOURCE = yappi-$(PYTHON_YAPPI_VERSION).tar.gz
PYTHON_YAPPI_SITE = https://files.pythonhosted.org/packages/88/4a/e16c320be27ea5ed9015ebe4a5fe834e714a0f0fc9cf46a20b2f87bf4fe3
PYTHON_YAPPI_SETUP_TYPE = setuptools
PYTHON_YAPPI_LICENSE = MIT
PYTHON_YAPPI_LICENSE_FILES = LICENSE

$(eval $(python-package))
