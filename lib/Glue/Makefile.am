
h:
	${VALAC} \
	--pkg=pango \
	--pkg=gee-0.8 \
	--pkg=json-glib-1.0 \
	../FontConfig/Font.vala \
	../FontConfig/Enums.vala \
	../Common/Cacheable.vala \
	../Common/FontInfo.vala \
	./Glue.vala -C -H ./_Glue_.h

all: h

CLEANFILES = \
	./Enums.c \
	./Font.c \
	./Cacheable.c \
	./FontInfo.c

MAINTAINERCLEANFILES = \
	./Makefile.in

