################################################################################
#
# python-opencv-python
#
################################################################################

PYTHON_OPENCV_PYTHON_VERSION = 4.5.5.64
PYTHON_OPENCV_PYTHON_SOURCE = opencv-python-$(PYTHON_OPENCV_PYTHON_VERSION).tar.gz
PYTHON_OPENCV_PYTHON_SITE = https://files.pythonhosted.org/packages/3c/61/ee4496192ed27f657532fdf0d814b05b9787e7fc5122ed3ca57282bae69c
PYTHON_OPENCV_PYTHON_SETUP_TYPE = setuptools
PYTHON_OPENCV_PYTHON_LICENSE = Apache-2.0
PYTHON_OPENCV_PYTHON_LICENSE_FILES = LICENSE
PYTHON_OPENCV_PYTHON_DEPENDENCIES = readline python-distro python-scikit-build python-wheel

$(eval $(python-package))
$(eval $(host-autotools-package))