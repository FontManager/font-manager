
configure_file(input: 'test-application.h.in', output: 'test-application.h', configuration: config)

test_application_sources = [
    files('test-application.c'),
    gresources
]

test_build_dir = include_directories('.')

widget_test = executable('test-application',
                         dependencies: base_deps,
                         include_directories: includes,
                         sources: test_application_sources )

test('Widget Test', widget_test, timeout: 0)

