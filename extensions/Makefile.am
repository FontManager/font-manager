extension_name=font-manager.py

if INSTALL_NAUTILUS_EXTENSION
extension_nautilus_dir = ${datarootdir}/nautilus-python/extensions/
if COMPILE_PYTHON_EXTENSIONS
extension_nautilus__PYTHON = Nautilus/$(extension_name)
else
extension_nautilus__DATA = Nautilus/$(extension_name)
endif
endif

if INSTALL_NEMO_EXTENSION
extension_nemo_dir = ${datarootdir}/nemo-python/extensions/
if COMPILE_PYTHON_EXTENSIONS
extension_nemo__PYTHON = Nemo/$(extension_name)
else
extension_nemo__DATA = Nemo/$(extension_name)
endif
endif

if INSTALL_THUNAR_EXTENSION
extension_thunar_dir =	${datarootdir}/thunarx-python/extensions/
if COMPILE_PYTHON_EXTENSIONS
extension_thunar__PYTHON = Thunar/$(extension_name)
else
extension_thunar__DATA = Thunar/$(extension_name)
endif
endif


EXTRA_DIST = \
	Nautilus \
  Nemo \
	Thunar \
  README

