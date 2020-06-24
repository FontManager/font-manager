
nemo_info = '''

    Install the libnemo-extension package and try again.

    For more information see https://github.com/linuxmint/nemo
'''

nemo = dependency('libnemo-extension', not_found_message: nemo_info)

result = run_command(python, '-c', list_sources)
nemo_extension_sources = result.stdout().strip().split('\n')
result = run_command(python, '-c', list_headers)
nemo_extension_headers = result.stdout().strip().split('\n')

nemo_extension_dir = join_paths(get_option('libdir'), 'nemo', 'extensions-3.0')

nemo_font_manager = shared_module('nemo-font-manager',
                                  [nemo_extension_sources, nemo_extension_headers],
                                  dependencies: [nemo, base_deps],
                                  name_prefix: '',
                                  install: true,
                                  install_dir: nemo_extension_dir)
