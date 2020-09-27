
subdir('unicode')
subdir('common')

libfontmanager = shared_library('fontmanager',
                                version: meson.project_version(),
                                link_whole: [
                                    libunicode.get_static_lib(),
                                    libcommon.get_static_lib()
                                ],
                                dependencies: project_deps,
                                install: true,
                                install_dir: pkglib_dir)

libfontmanager_deps = declare_dependency(
    dependencies:[base_deps, common_vapi, unicode_vapi],
    link_with: libfontmanager,
    include_directories: include_directories('.')
)

if get_option('gtk-doc')
    subdir('docs')
endif
