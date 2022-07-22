
font_manager_gresource_xml_file = files('font-manager-gresources.xml')

font_manager_gresources = gnome.compile_resources('font-manager-gresources',
                                                  font_manager_gresource_xml_file)

result = run_command(python, '-c', list_vala_sources, check: true)
font_manager_sources = result.stdout().strip().split('\n')

vala_test_lib = shared_library('vala_test',
                               [ font_manager_sources, font_manager_gresources ],
                               vala_header: 'vala_test.h',
                               dependencies: [ vala_deps, vapi ],
                               include_directories: includes,
                               link_with: libfontmanager,
                               install: false)

includes += include_directories('.')

