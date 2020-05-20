
service = ['org.gnome.FontManager', 'org.gnome.FontViewer']

appdata_dir = join_paths(datadir, 'metainfo')
dbus_service_dir = join_paths(datadir, 'dbus-1', 'services')
desktop_dir = join_paths(datadir, 'applications')
schema_dir = join_paths(datadir, 'glib-2.0', 'schemas')

configure_file(
    command: [
        'glib-compile-schemas',
        '--targetdir=' + meson.current_build_dir(),
        meson.current_source_dir()
    ],
    output: 'gschema.compiled'
)

foreach path: service
	if (path == 'org.gnome.FontManager' and not get_option('manager'))
		continue
	endif
	if (path == 'org.gnome.FontViewer' and not get_option('viewer'))
		continue
	endif
    install_data('@0@.gschema.xml'.format(path), install_dir: schema_dir)
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
