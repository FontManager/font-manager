
service = ['com.github.FontManager.FontManager',
	   'com.github.FontManager.FontViewer']

appdata_dir = join_paths(datadir, 'metainfo')
dbus_service_dir = join_paths(datadir, 'dbus-1', 'services')
desktop_dir = join_paths(datadir, 'applications')
schema_dir = join_paths(datadir, 'glib-2.0', 'schemas')
search_provider_dir = join_paths(datadir, 'gnome-shell', 'search-providers')

configure_file(
    command: [
        'glib-compile-schemas',
        '--targetdir=' + meson.current_build_dir(),
        meson.current_source_dir()
    ],
    output: 'gschema.compiled'
)

foreach path: service
    if (path == 'com.github.FontManager.FontManager' and not get_option('manager'))
        continue
    endif
    if (path == 'com.github.FontManager.FontViewer' and not get_option('viewer'))
        continue
    endif
    install_data('@0@.gschema.xml'.format(path), install_dir: schema_dir)

    icons = [ 'com.github.FontManager.FontManager.svg' ]
    foreach icon: icons
        icon_dir = join_paths(datadir, 'icons', 'hicolor', 'scalable', 'apps')
        install_data(icon, install_dir: icon_dir, rename: '@0@.svg'.format(path))
    endforeach

    i18n.merge_file(
        input: configure_file(
                    input: '@0@.desktop.in.in'.format(path),
                    output: '@0@.desktop.in'.format(path),
                    configuration: config
                ),
        output: '@0@.desktop'.format(path),
        type: 'desktop',
        po_dir: '../po',
        install: true,
        install_dir: desktop_dir
    )
    i18n.merge_file(
        input: configure_file(
                    input: '@0@.appdata.xml.in.in'.format(path),
                    output: '@0@.appdata.xml.in'.format(path),
                    configuration: config
                ),
        output: '@0@.appdata.xml'.format(path),
        po_dir: '../po',
        install: true,
        install_dir: appdata_dir
    )
endforeach

python_write = '''
with open('@OUTPUT@', 'w') as output:
    output.write(@0@)
'''

dbus_service = '''"""[D-BUS Service]
Name=@0@
Exec=@1@/@2@ --gapplication-service
"""
'''

if get_option('manager')

    custom_target(
        '@0@.service'.format(service[0]),
        output: '@0@.service'.format(service[0]),
        command: [
            python,
            '-c',
            python_write.format(
                dbus_service.format(
                    service[0],
                    join_paths(prefix, get_option('bindir')),
                    meson.project_name()
                )
            )
        ],
        install: true,
        install_dir: dbus_service_dir
    )

    if get_option('search-provider')
        install_data('com.github.FontManager.FontManager.SearchProvider.ini',
        	     install_dir: search_provider_dir)
    endif

    if get_option('app-armor')
    	aa_config_dir = join_paths(get_option('sysconfdir'), 'apparmor.d')
    	aa_profile = join_paths(meson.current_build_dir(), 'font-manager.aap')
    	configure_file(input: 'font-manager.aap.in', output: 'font-manager.aap', configuration: config)
		install_data(aa_profile, install_dir: aa_config_dir, rename: 'font-manager')
	endif

endif

if get_option('viewer')

    custom_target(
        '@0@.service'.format(service[1]),
        output: '@0@.service'.format(service[1]),
        command: [
            python,
            '-c',
            python_write.format(
                dbus_service.format(
                    service[1],
                    pkglibexec_dir,
                    'font-viewer'
                )
            )
        ],
        install: true,
        install_dir: dbus_service_dir
    )

endif
