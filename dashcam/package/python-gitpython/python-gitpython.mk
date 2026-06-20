################################################################################
#
# python-gitpython
#
################################################################################

PYTHON_GITPYTHON_VERSION = 3.1.32
PYTHON_GITPYTHON_SOURCE = GitPython-$(PYTHON_GITPYTHON_VERSION).tar.gz
PYTHON_GITPYTHON_SITE = https://files.pythonhosted.org/packages/87/56/6dcdfde2f3a747988d1693100224fb88fc1d3bbcb3f18377b2a3ef53a70a
PYTHON_GITPYTHON_SETUP_TYPE = setuptools
PYTHON_GITPYTHON_LICENSE = Apache-2.0
PYTHON_GITPYTHON_LICENSE_FILES = LICENSE

$(eval $(python-package))
