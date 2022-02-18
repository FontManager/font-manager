
config = configuration_data()
config.set('PROJECT_NAME', meson.project_name())
config.set('MODULE_PATH', meson.current_build_dir())
config.set('TEST_ENTRIES', join_paths(meson.current_source_dir(), 'tests.json'))
configure_file(input: 'test-application.h.in', output: 'test-application.h', configuration: config)

gresources = gnome.compile_resources('gresources', 'gresources.xml', c_name: 'test')

test_application_sources = [
    'test-application.c',
    gresources
]

widget_test = executable('test-application', dependencies: base_deps, sources: test_application_sources)

test('Widget Test', widget_test, timeout: 0)
