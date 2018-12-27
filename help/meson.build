
result = run_command(python, '-c', file_list_template.format('page'))

help_files = []

foreach f: result.stdout().strip().split('\n')
    help_files += f.split('/')[1]
endforeach

help_media = [
    'media/character-map.png',
    'media/license.png',
    'media/list-add-symbolic.svg',
    'media/list-remove-symbolic.svg',
    'media/main-window.png',
    'media/metadata.png',
    'media/orthographies.png',
    'media/preferences-desktop-font.png',
    'media/preferences-desktop-font-16.png',
    'media/preferences-system-symbolic.svg'
]

gnome.yelp(meson.project_name(), sources: help_files, media: help_media)

install_man(
    configure_file(
        input: '@0@.1.in'.format(meson.project_name()),
        output: '@0@.1'.format(meson.project_name()),
        configuration: config
    )
)
