
tests = [
    'character-map',
    'font-scale',
    'license-page',
    'place-holder',
    'preference-row',
    'preview-controls',
    'preview-page',
    'properties-page'
]

foreach t: tests
    library(t,
            name_prefix: '',
            dependencies: base_deps,
            include_directories: test_build_dir,
            sources: [ test_application_sources, '@0@-test.c'.format(t) ],
            link_with: [ libfontmanager_gtk, libunicode ])
endforeach


