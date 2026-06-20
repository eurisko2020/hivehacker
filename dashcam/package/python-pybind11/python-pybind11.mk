################################################################################
#
# python-pybind11
#
################################################################################

PYTHON_PYBIND11_VERSION = 2.11.1
PYTHON_PYBIND11_SOURCE = pybind11-$(PYTHON_PYBIND11_VERSION).tar.gz
PYTHON_PYBIND11_SITE = https://files.pythonhosted.org/packages/3a/cc/903bb18de90b5d6e15379c97175371ac6414795d94b9c2f6468a9c1303aa
PYTHON_PYBIND11_SETUP_TYPE = setuptools
PYTHON_PYBIND11_LICENSE = Apache-2.0
PYTHON_PYBIND11_LICENSE_FILES = LICENSE

$(eval $(python-package))
