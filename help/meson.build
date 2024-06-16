
list_help_files = '''
from glob import glob
for f in sorted(glob('**/*.page', recursive=False)):
    print(f)
'''

if get_option('manager')

    install_man(
        configure_file(
            input: '@0@.1.in'.format(meson.project_name()),
            output: '@0@.1'.format(meson.project_name()),
            configuration: config
        )
    )

endif

yelp_tools_info = '''

    Install the yelp-tools package and try again.

    https://gitlab.gnome.org/GNOME/yelp-tools

    For more information see http://yelp.io/
'''

if get_option('yelp-doc')

    #          Check for programs required by gnome.yelp           #
    #          Display a friendlier message if not present         #

    yelp_tools = find_program('yelp-build', required: false)

    if not yelp_tools.found()
        dependency('yelp-tools', not_found_message: yelp_tools_info)
    endif

    #                                                              #

    result = run_command(python, '-c', list_help_files, check: true)

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
        'media/open-menu.svg',
        'media/orthographies.png',
        'media/com.github.FontManager.FontManager-48.png',
        'media/com.github.FontManager.FontManager-64.png'
    ]

    gnome.yelp(meson.project_name(), sources: help_files, media: help_media)

endif
