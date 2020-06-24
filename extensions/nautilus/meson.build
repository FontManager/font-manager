
nautilus_info = '''

    Install the libnautilus-extension package and try again.

    For more information see https://wiki.gnome.org/Apps/Files
'''

nautilus = dependency('libnautilus-extension', not_found_message: nautilus_info)

result = run_command(python, '-c', list_sources)
nautilus_extension_sources = result.stdout().strip().split('\n')
result = run_command(python, '-c', list_headers)
nautilus_extension_headers = result.stdout().strip().split('\n')

nautilus_extension_dir = join_paths(get_option('libdir'), 'nautilus', 'extensions-3.0')

nautilus_font_manager = shared_module('nautilus-font-manager',
                                      [nautilus_extension_sources, nautilus_extension_headers],
                                      dependencies: [nautilus, base_deps],
                                      name_prefix: '',
                                      install: true,
                                      install_dir: nautilus_extension_dir)
