
gettext_info = '''

    Install the gettext package and try again.

    For more information see https://www.gnu.org/software/gettext/
'''

#       Check for programs required by i18n.gettext       #
#       Display a friendlier message if not present       #

nls = find_program('msgfmt', required: false)

if not nls.found()
    dependency('gettext', not_found_message: gettext_info)
endif

#                                                         #

PODIR = join_paths(meson.source_root(), 'po')

POTFILES = '''
from glob import glob

data = [
    'data/org.gnome.FontManager.appdata.xml.in.in',
    'data/org.gnome.FontManager.desktop.in.in',
    'data/org.gnome.FontViewer.appdata.xml.in.in',
    'data/org.gnome.FontViewer.desktop.in.in'
]

def filelist (ext):
    for f in sorted(glob('@0@/**/*.{}*'.format(ext), recursive=True)):
        yield f

with open('@1@/POTFILES', 'w') as POTFILES:
    for f in data:
        POTFILES.write('{}\n'.format(f))
    for ext in [ 'c', 'vala', 'ui' ]:
        for f in filelist(ext):
            f = f.replace('@2@/', '')
            skip = False
            for d in [ 'build', 'tests' ]:
                if f.startswith(d):
                    skip = True
                    break
            if skip:
                continue
            if not f.endswith(ext) and not f.endswith('.in'):
                continue
            POTFILES.write('{}\n'.format(f))
'''.format(meson.source_root(), PODIR, meson.source_root())

configure_file(
    command: [python, '-c', POTFILES],
    output: 'POTFILES'
)

gettext_args = [
    '--package-name=@0@'.format(meson.project_name()),
    '--package-version=@0@'.format(meson.project_version()),
    '--msgid-bugs-address=https://github.com/FontManager/master/issues',
    '--copyright-holder=Jerry Casiano'
]

i18n.gettext(meson.project_name(), preset: 'glib', args: gettext_args)

