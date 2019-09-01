
if nemo.found()

    result = run_command(python, '-c', list_sources)
    nemo_extension_sources = result.stdout().strip().split('\n')
    result = run_command(python, '-c', list_headers)
    nemo_extension_headers = result.stdout().strip().split('\n')

    nemo_extension_dir = join_paths(get_option('libdir'), 'nemo', 'extensions-3.0')

    nemo_font_manager = shared_module('nemo-font-manager',
                                      [nemo_extension_sources, nemo_extension_headers],
                                      dependencies: nemo,
                                      name_prefix: '',
                                      install: true,
                                      install_dir: nemo_extension_dir,
                                      include_directories: default_includes)

endif
