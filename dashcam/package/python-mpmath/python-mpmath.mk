################################################################################
#
# python-mpmath
#
################################################################################

PYTHON_MPMATH_VERSION = 1.3.0
PYTHON_MPMATH_SOURCE = mpmath-$(PYTHON_MPMATH_VERSION).tar.gz
PYTHON_MPMATH_SITE = https://files.pythonhosted.org/packages/e0/47/dd32fa426cc72114383ac549964eecb20ecfd886d1e5ccf5340b55b02f57
PYTHON_MPMATH_SETUP_TYPE = setuptools
PYTHON_MPMATH_LICENSE = Apache-2.0
PYTHON_MPMATH_LICENSE_FILES = LICENSE

$(eval $(python-package))
