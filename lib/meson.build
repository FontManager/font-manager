
subdir('unicode')
subdir('common')
subdir('vala')

libfontmanager = shared_library('fontmanager',
                                version: meson.project_version(),
                                link_whole: [
                                    libvala,
                                    libunicode.get_static_lib(),
                                    libcommon.get_static_lib()
                                ],
                                dependencies: [
                                    fontconfig, freetype, json, gio, glib,
                                    gobject, gtk, m_dep, pango, pangoft2,
                                    sqlite, xml
                                ],
                                include_directories: default_includes,
                                install: true,
                                install_dir: pkglib_dir)

