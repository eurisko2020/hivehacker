################################################################################
#
# python-expecttest
#
################################################################################

PYTHON_EXPECTTEST_VERSION = 0.1.6
PYTHON_EXPECTTEST_SOURCE = expecttest-$(PYTHON_EXPECTTEST_VERSION).tar.gz
PYTHON_EXPECTTEST_SITE = https://files.pythonhosted.org/packages/a2/46/42526e9e0f6d67966bd15364fc3713ac5a3501204868e472583f12c5271d
PYTHON_EXPECTTEST_SETUP_TYPE = setuptools
PYTHON_EXPECTTEST_LICENSE = Apache-2.0
PYTHON_EXPECTTEST_LICENSE_FILES = LICENSE

$(eval $(python-package))