
result = run_command(python, '-c', list_sources)

common_sources = result.stdout().strip().split('\n')

result = run_command(python, '-c', list_headers)

common_headers = result.stdout().strip().split('\n')

HEADER = join_paths(meson.current_build_dir(), 'font-manager.h')

WRITE_HEADER = '''
from glob import glob

def filelist (ext):
    for f in sorted(glob('@0@/*.{}*'.format(ext), recursive=True)):
        yield f

with open('@1@', 'w') as H:
    H.write('#pragma once\n')
    for f in filelist('h'):
        f = f.replace('@2@/', '')
        H.write('#include "{}"\n'.format(f))
'''.format(meson.current_source_dir(), HEADER, meson.current_source_dir())

configure_file(
    command: [python, '-c', WRITE_HEADER],
    output: 'font-manager.h'
)

libfontmanager_gtk = both_libraries('fontmanager-gtk',
				    common_sources,
				    dependencies: base_deps)

