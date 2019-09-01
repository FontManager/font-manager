
if nautilus.found()

    result = run_command(python, '-c', list_sources)
    nautilus_extension_sources = result.stdout().strip().split('\n')
    result = run_command(python, '-c', list_headers)
    nautilus_extension_headers = result.stdout().strip().split('\n')

    nautilus_extension_dir = join_paths(get_option('libdir'), 'nautilus', 'extensions-3.0')

    nautilus_font_manager = shared_module('nautilus-font-manager',
                                          [nautilus_extension_sources, nautilus_extension_headers],
                                          dependencies: nautilus,
                                          name_prefix: '',
                                          install: true,
                                          install_dir: nautilus_extension_dir,
                                          include_directories: default_includes)

endif
