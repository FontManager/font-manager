
tests = [
    'category-list',
    'character-map',
    'dialog',
    'font-scale',
    'font-list',
    'font-list-selection',
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
            include_directories: [ includes, test_build_dir ],
            sources: [ test_application_sources, '@0@-test.c'.format(t) ],
            link_with: [ libfontmanager, vala_test_lib ] )
endforeach

