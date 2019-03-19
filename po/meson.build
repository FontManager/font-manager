
configure_file(
    input: 'POTFILES.in',
    output: 'POTFILES',
    copy: true
)

gettext_args = [
    '--package-name=@0@'.format(meson.project_name()),
    '--package-version=@0@'.format(meson.project_version()),
    '--msgid-bugs-address=https://github.com/FontManager/master/issues',
    '--copyright-holder=Jerry Casiano'
]

i18n.gettext(meson.project_name(), preset: 'glib', args: gettext_args)
