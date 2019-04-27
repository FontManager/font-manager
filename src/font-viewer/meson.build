
font_viewer_gresource_xml_file = files('font-viewer-gresources.xml')

font_viewer_gresources = gnome.compile_resources('font-viewer-gresources', font_viewer_gresource_xml_file)

result = run_command(python, '-c', list_vala_sources)
font_viewer_sources = result.stdout().strip().split('\n')

executable('font-viewer',
            [font_viewer_sources, font_viewer_gresources, config_vapi_file, libvala_headers],
            link_with: libfontmanager,
            include_directories: [default_includes, libvala_includes],
            dependencies: [
                json, gio, glib, gobject, gtk, pango, sqlite, xml,
                common_vapi, unicode_vapi
            ],
            install: true,
            install_dir: pkglibexec_dir,
            install_rpath: pkglib_dir)

