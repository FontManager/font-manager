
nautilus_info = '''

    Install the libnautilus-extension package and try again.

    For more information see https://wiki.gnome.org/Apps/Files
'''

nautilus = dependency('libnautilus-extension', required: false)
nautilus4 = dependency('libnautilus-extension-4', required: false)

if nautilus.found() or nautilus4.found()

    result = run_command(python, '-c', list_sources)
    nautilus_extension_sources = result.stdout().strip().split('\n')
    result = run_command(python, '-c', list_headers)
    nautilus_extension_headers = result.stdout().strip().split('\n')

    if nautilus.found()
        args = []
        nautilus_version = '3.0'
        nautilus_deps = [nautilus, base_deps]
    else
        args = ['-DNAUTILUS_4']
        nautilus_version = '4'
        nautilus_deps = [nautilus4, base_deps]

    endif

    nautilus_extension_dir = join_paths(get_option('libdir'), 'nautilus', 'extensions-@0@'.format(nautilus_version))

    nautilus_font_manager = shared_module('nautilus-font-manager',
                                          [nautilus_extension_sources, nautilus_extension_headers],
                                          dependencies: nautilus_deps,
                                          c_args: args,
                                          link_with: libfontmanager,
                                          name_prefix: '',
                                          install: true,
                                          install_dir: nautilus_extension_dir,
                                          install_rpath: pkglib_dir)

else

    message(nautilus_info)

endif
