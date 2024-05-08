
project('font-manager', ['c', 'vala'], license: 'GPL3', version: '0.9.0')

if meson.version().version_compare('< 0.59')
    error('Meson version is @0@ but project requires >= 0.59'.format(meson.version()))
endif

# There has to be a better way to require a specific vala version, right?
valac = meson.get_compiler('vala')
if not valac.version().version_compare('>= 0.56.3')
    error('Vala compiler version is @0@ but project requires >= 0.56.3'.format(valac.version()))
endif
if valac.version().version_compare('>= 0.56.17')
    add_global_arguments('-D', 'VALA_0_56_17', language: 'vala')
endif

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required: false)

i18n = import('i18n')
fontconfig = dependency('fontconfig', version: '>= 2.12')
freetype = dependency('freetype2', version: '>= 2.10')
gio = dependency('gio-2.0', version: '>= 2.7')
gio_unix = dependency('gio-unix-2.0', version: '>= 2.7')
glib = dependency('glib-2.0', version: '>= 2.62')
gmodule = dependency('gmodule-2.0', version: '>= 2.50')
gtk = dependency('gtk4', version: '>= 4.10')
harfbuzz = dependency('harfbuzz', version: '>= 2.5')
json = dependency('json-glib-1.0', version: '>= 1.5')
pangoft2 = dependency('pangoft2', version: '>= 1.45')
python = import('python').find_installation('python3')
sqlite = dependency('sqlite3', version: '>= 3.35')
xml = dependency('libxml-2.0', version: '>= 2.9.10')

gnome = import('gnome')

# This dependency cannot be used for vala targets
base_deps = declare_dependency(
    dependencies: [ fontconfig, freetype, glib, gmodule, gtk, harfbuzz,
                    json, m_dep, pangoft2, sqlite, xml ]
)

vala_deps = declare_dependency(
    dependencies: [ glib, gio, gio_unix, gmodule, gtk, json, m_dep, sqlite, xml ]
)

if get_option('webkit')
    soup = dependency('libsoup-3.0', version: '>= 3.2')
    webkit = dependency('webkitgtk-6.0', version: '>= 2.4')
    add_global_arguments('-D', 'HAVE_WEBKIT', language: 'vala')
endif

includes = [ include_directories('.') ]

config_vapi = files('config.vapi')
prefix = get_option('prefix')
datadir = get_option('datadir')
pkglib_dir = join_paths(prefix, get_option('libdir'), meson.project_name())
pkglibexec_dir = join_paths(prefix, get_option('libexecdir'), meson.project_name())

config = configuration_data()
config.set('PACKAGE_NAME', meson.project_name())
config.set('PACKAGE_VERSION', meson.project_version())
config.set('PACKAGE_URL', 'http://fontmanager.github.io/')
config.set('PACKAGE_BUGREPORT', 'https://github.com/FontManager/master/issues')
config.set('GETTEXT_PACKAGE', meson.project_name())
config.set('PKGLIBEXECDIR', pkglibexec_dir)
config.set('PREFIX', prefix)
config.set('BINDIR', join_paths(prefix, 'bin'))
config.set('LOCALEDIR', join_paths(prefix, datadir, 'locale'))
config.set('SRCDIR', meson.current_build_dir())

configure_file(input: 'config.h.meson', output: 'config.h', configuration: config)

reproducible = get_option('reproducible') ? '-DREPRODUCIBLE' : '-DNOT_REPRODUCIBLE'

add_project_arguments(
    '-DG_LOG_DOMAIN="[@0@]"'.format(meson.project_name()),
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    reproducible,
    language: 'c'
)

if get_option('unihan')
    add_global_arguments('-DINCLUDE_UNIHAN_DATA=1', language: 'c')
else
    add_global_arguments('-DINCLUDE_UNIHAN_DATA=0', language: 'c')
endif

subdir('lib')
subdir('src')
subdir('extensions')
subdir('help')
subdir('data')

if get_option('enable-nls')
    subdir('po')
endif

subdir('test')

meson.add_dist_script('meson_dist.py')

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true,
    update_desktop_database: true
)

summary(
    {
        ' Font Manager ': get_option('manager'),
        ' Font Viewer ': get_option('viewer'),
        ' Help Documents ': get_option('yelp-doc'),
        ' GNOME search provider ': get_option('search-provider'),
        ' Google Fonts Integration ': get_option('webkit'),
        ' Nautilus extension ': get_option('nautilus'),
        ' Nemo extension ': get_option('nemo'),
        ' Thunar extension ': get_option('thunar'),
        ' Translations ': get_option('enable-nls'),
        ' Unihan data ' : get_option('unihan'),
        ' API Documentation ': get_option('gtk-doc'),
        ' Reproducible build ': get_option('reproducible')
    },
    section: '''Project options
    ''',
    bool_yn: true
)

summary(
    {
        ' prefix ': prefix,
        ' bindir ': join_paths(prefix, get_option('bindir')),
        ' libdir ': join_paths(prefix, get_option('libdir'), meson.project_name()),
        ' libexecdir ': join_paths(prefix, get_option('libexecdir'), meson.project_name()),
        ' datadir ': join_paths(prefix, datadir)
    },
    section: '''Directories
    '''
)

