
result = run_command(python, '-c', list_vala_sources)
font_manager_sources = result.stdout().strip().split('\n')

executable('font-manager',
            [font_manager_sources, config_vapi_file, libvala_headers],
            link_with: libfontmanager,
            include_directories: [default_includes, libvala_includes],
            dependencies: [
                json, gio, glib, gobject, gtk, pango, sqlite, xml,
                common_vapi, unicode_vapi
            ],
            install: true,
            install_rpath: pkglib_dir)
