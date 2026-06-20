################################################################################
#
# python-torch
#
################################################################################

PYTHON_TORCH_VERSION = e85d494707b835c12165976b8442af54b9afcb26
# PYTHON_TORCH_SOURCE = v$(PYTHON_TORCH_VERSION).tar.gz
PYTHON_TORCH_SITE = https://github.com/pytorch/pytorch.git
PYTHON_TORCH_SITE_METHOD = git
PYTHON_TORCH_GIT_SUBMODULES = YES
PYTHON_TORCH_SETUP_TYPE = setuptools
PYTHON_TORCH_LICENSE = Apache-2.0
PYTHON_TORCH_LICENSE_FILES = LICENSE

PYTHON_TORCH_CONF_OPTS += \
	-DPLIBDIR=/home/eduard/git/hdc_firmware/output/build/python3-3.11.2 \
	-DINSTSONAME=libpython3.11.so.1.0 \
	-DHAVE_STD_REGEX=ON \
	-DRUN_HAVE_STD_REGEX=1 \
	-DBUILD_TEST=False \ 
	-DLD_LIBRARY_PATH=/usr/bin/gcc-11/lib

$(eval $(python-package))
