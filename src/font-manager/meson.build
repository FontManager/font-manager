
font_manager_gresource_xml_file = files('font-manager-gresources.xml')

font_manager_gresources = gnome.compile_resources('font-manager-gresources',
                                                  font_manager_gresource_xml_file)

result = run_command(python, '-c', list_vala_sources)
font_manager_sources = result.stdout().strip().split('\n')

executable('font-manager',
            [font_manager_sources, font_manager_gresources, config_vapi_file],
            dependencies: libfontmanager_deps,
            install: true,
            install_rpath: pkglib_dir)
