
if INSTALL_NAUTILUS_EXTENSION
extension_nautilus_dir = ${datarootdir}/nautilus-python/extensions/
if COMPILE_PYTHON_EXTENSIONS
extension_nautilus__PYTHON = Nautilus/$(PACKAGE_NAME).py
else
extension_nautilus__DATA = Nautilus/$(PACKAGE_NAME).py
endif
endif

if INSTALL_NEMO_EXTENSION
extension_nemo_dir = ${datarootdir}/nemo-python/extensions/
if COMPILE_PYTHON_EXTENSIONS
extension_nemo__PYTHON = Nemo/$(PACKAGE_NAME).py
else
extension_nemo__DATA = Nemo/$(PACKAGE_NAME).py
endif
endif

if INSTALL_THUNAR_EXTENSION
extension_thunar_dir =	${datarootdir}/thunarx-python/extensions/
if COMPILE_PYTHON_EXTENSIONS
extension_thunar__PYTHON = Thunar/$(PACKAGE_NAME).py
else
extension_thunar__DATA = Thunar/$(PACKAGE_NAME).py
endif
endif

EXTRA_DIST = \
	Nautilus \
	Nemo \
	Thunar \
	README

MAINTAINERCLEANFILES = \
	./Makefile.in
