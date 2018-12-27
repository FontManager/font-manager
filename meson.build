
project('font-manager', ['c', 'vala'], license: 'GPL3', version: '0.7.4')

i18n = import('i18n')
gnome= import('gnome')
python = import('python').find_installation('python3')

add_global_arguments(
    '-DG_LOG_DOMAIN="[@0@]"'.format(meson.project_name()),
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DGDK_DISABLE_DEPRECATED',
    '-DGTK_DISABLE_DEPRECATED',
    '-Wall', '-Wextra', '-Werror=format-security',
    language: 'c'
)

default_includes = include_directories( '.', 'lib/common', 'lib/orthographies', 'lib/unicode')

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required: false)
fontconfig = dependency('fontconfig', version: '>= 2.1')
freetype = dependency('freetype2', version: '>= 2.5')
json = dependency('json-glib-1.0', version: '>= 0.15')
gio = dependency('gio-2.0', version: '>= 2.4')
glib = dependency('glib-2.0', version: '>= 2.4')
gobject = dependency('gobject-2.0', version: '>= 2.4')
gtk = dependency('gtk+-3.0', version: '>= 3.22')
pango = dependency('pango', version: '>= 1.4')
pangoft2 = dependency('pangoft2', version: '>= 1.4')
sqlite = dependency('sqlite3', version: '>= 3.8')
xml = dependency('libxml-2.0', version: '>= 2.9')

config_vapi_file = files('config.vapi')
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
config.set('prefix', prefix)
config.set('abs_top_srcdir', meson.current_build_dir())
configure_file(input: 'config.h.meson', output: 'config.h', configuration: config)

file_list_template = '''
from glob import glob
for f in glob('**/*.@0@', recursive=True):
    print(f)
'''

list_sources = file_list_template.format('c')
list_headers = file_list_template.format('h')
list_vala_sources = file_list_template.format('vala')

subdir('data')
subdir('extensions')
subdir('help')
subdir('lib')
subdir('src')
subdir('po')

meson.add_install_script('meson_post_install.py')
