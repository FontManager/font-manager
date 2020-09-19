
thunarx_info = '''

    Install the thunar package and try again.

    For more information see https://docs.xfce.org/xfce/thunar/start
'''

thunar = dependency('thunarx-3', not_found_message: thunarx_info)

result = run_command(python, '-c', list_sources)
thunarx_extension_sources = result.stdout().strip().split('\n')
result = run_command(python, '-c', list_headers)
thunarx_extension_headers = result.stdout().strip().split('\n')

thunarx_extension_dir = join_paths(get_option('libdir'), 'thunarx-3')

thunarx_font_manager = shared_module('thunar-font-manager',
                                    [thunarx_extension_sources, thunarx_extension_headers],
                                    dependencies: [thunar, base_deps ],
                                    link_with: libfontmanager,
                                    name_prefix: '',
                                    install: true,
                                    install_dir: thunarx_extension_dir,
                                    install_rpath: pkglib_dir)
