
dependencies = [ base_deps ]

if get_option('webkit')
    dependencies += soup
    dependencies += webkit
endif

foreach t: tests
    if not get_option('webkit') and t.contains('google')
        continue
    endif
    library(t,
            name_prefix: '',
            dependencies: dependencies,
            include_directories: [ includes, test_build_dir ],
            sources: [ test_application_sources, '@0@-test.c'.format(t) ],
            link_with: [ libfontmanager, vala_test_lib ] )
endforeach

