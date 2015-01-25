extension_name=font-manager.py

if INSTALL_NAUTILUS_EXTENSION
extension_nautilus_dir =	${datarootdir}/nautilus-python/extensions/
extension_nautilus__PYTHON = Nautilus/$(extension_name)
endif
if INSTALL_NEMO_EXTENSION
extension_nemo_dir =	${datarootdir}/nemo-python/extensions/
extension_nemo__PYTHON = Nemo/$(extension_name)
endif
if INSTALL_THUNAR_EXTENSION
extension_thunar_dir =	${libdir}/thunarx-2/python/
extension_thunar__PYTHON = Thunar/$(extension_name)
endif

EXTRA_DIST = \
	Nautilus \
	Thunar
