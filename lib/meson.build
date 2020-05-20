
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
                                dependencies: project_deps,
                                install: true,
                                install_dir: pkglib_dir)

libfontmanager_deps = declare_dependency(
    link_with: libfontmanager,
    include_directories: include_directories('.')
)
