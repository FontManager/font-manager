
tests = [
    'character-map',
    'font-scale',
    'font-list',
    'license-page',
    'place-holder',
    'preference-row',
    'preview-controls',
    'preview-page',
    'preview-pane',
    'properties-page'
]

foreach t: tests
    library(t,
            name_prefix: '',
            dependencies: base_deps,
            include_directories: [ test_build_dir, includes ],
            sources: [ test_application_sources, '@0@-test.c'.format(t) ],
            link_with: [ libfontmanager, vala_test_lib] )
endforeach

