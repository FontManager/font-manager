
GLUE_DEPS = \
	$(abs_top_srcdir)/lib/FontConfig/Font.vala \
	$(abs_top_srcdir)/lib/FontConfig/Enums.vala \
	$(abs_top_srcdir)/lib/Common/Cacheable.vala \
	$(abs_top_srcdir)/lib/Common/FontInfo.vala

_Glue_.h:
	${VALAC} \
	--pkg=pango \
	--pkg=gee-0.8 \
	--pkg=json-glib-1.0 \
	$(GLUE_DEPS) \
	Glue.vala \
	-C -H $@

all: _Glue_.h

MAINTAINERCLEANFILES = \
	Makefile.in
