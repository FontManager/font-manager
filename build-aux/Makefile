DATADIR=../data/
HELPDIR=../help/
LIBDIR=../lib/
PODIR=../po/
SED=`which sed`
SRCFILE=ValaSources.mk
SRCDIR=../src/
TOPDIR=../

all: update
.PHONY: update headers

POTFILES.readme:
	echo "POTFILES.* automatically generated. Do not edit. See build-aux directory" > ${PODIR}POTFILES.readme

POTFILES.in:
	find ${TOPDIR} -name "*.vala" -print | sort > ${PODIR}POTFILES.in ;
	echo "[type: gettext/glade]data/ApplicationMenu.ui" >> ${PODIR}POTFILES.in ;
	echo "data/org.gnome.FontManager.appdata.xml.in" >> ${PODIR}POTFILES.in ;
	echo "data/org.gnome.FontManager.desktop.in" >> ${PODIR}POTFILES.in ;
	echo "" >> ${PODIR}POTFILES.in ;
	$(SED) -i 's|\.\./||g' ${PODIR}POTFILES.in ;

POTFILES.skip:
	find ${TOPDIR} -name "*.vala" -print | sort | $(SED) 's/.vala/.c/g' > ${PODIR}POTFILES.skip ;
	$(SED) -i 's|\.\./||g' ${PODIR}POTFILES.skip ;

potfiles: POTFILES.readme POTFILES.in POTFILES.skip

update_sources:
	cd ${LIBDIR} && \
	echo "# This file automatically generated" > ${SRCFILE} && \
	echo "# Do not edit. See build-aux directory" >> ${SRCFILE} && \
	echo "" >> ${SRCFILE} && \
	echo "libfontmanager_la_VALASOURCES = \\" >> ${SRCFILE} && \
	for i in `find . -type f -name '*.vala*' -print | sed -e 's/\.in//g' | sort | uniq`;\
	do \
		echo "$$i \\" >> ${SRCFILE} ; \
	done && \
	sed -i '$$ s/\\//' ${SRCFILE} && \
	echo "" >> ${SRCFILE} && \
	cd ${DATADIR}
	cd ${SRCDIR}font-manager && \
	echo "# This file automatically generated" > ${SRCFILE} && \
	echo "# Do not edit. See build-aux directory" >> ${SRCFILE} && \
	echo "" >> ${SRCFILE} && \
	echo "font_manager_VALASOURCES = \\" >> ${SRCFILE} && \
	for i in `find . -type f -name '*.vala*' -print | sed -e 's/\.in//g' | sort | uniq`;\
	do \
		echo "$$i \\" >> ${SRCFILE} ; \
	done && \
	sed -i '$$ s/\\//' ${SRCFILE} && \
	echo "" >> ${SRCFILE} && \
	cd ../${DATADIR}

update: update_sources potfiles

headers:
	license/genheader.py
	vendor/genheader.py

