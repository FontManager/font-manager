
font_viewer_gresource_xml_file = files('font-viewer-gresources.xml')

font_viewer_gresources = gnome.compile_resources('font-viewer-gresources',
                                                 font_viewer_gresource_xml_file)

result = run_command(python, '-c', list_vala_sources, check: true)
font_viewer_sources = result.stdout().strip().split('\n')

executable('font-viewer',
            [font_viewer_sources, font_viewer_gresources, config_vapi_file],
            dependencies: [ vapi, vala_deps ],
            include_directories: includes,
            link_with: libfontmanager,
            install: true,
            install_dir: pkglibexec_dir,
            install_rpath: pkglib_dir)

