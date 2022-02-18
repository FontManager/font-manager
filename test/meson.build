
config = configuration_data()
config.set('MODULE_PATH', join_paths(meson.current_build_dir(), 'tests'))
config.set('TEST_ENTRIES', join_paths(meson.current_source_dir(), 'tests.json'))

gresources = gnome.compile_resources('gresources', 'gresources.xml', c_name: 'test')

subdir('application')
subdir('tests')

