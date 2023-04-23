
font_manager_gresource_xml_file = files('font-manager-gresources.xml')

font_manager_gresources = gnome.compile_resources('font-manager-gresources',
                                                  font_manager_gresource_xml_file)

result = run_command(python, '-c', list_vala_sources, check: true)
font_manager_sources = result.stdout().strip().split('\n')

dependencies = [ vapi, vala_deps ]

if get_option('webkit')
    dependencies += soup
    dependencies += webkit
endif

vala_test_lib = shared_library('vala_test',
                               [ font_manager_sources, font_manager_gresources, config_vapi ],
                               vala_header: 'vala_test.h',
                               dependencies: dependencies,
                               include_directories: includes,
                               link_with: libfontmanager,
                               install: false)

includes += include_directories('.')

