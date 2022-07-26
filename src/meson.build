
vala_file_list_template = '''
from glob import glob
for f in sorted(glob('**/*.@0@', recursive=True)):
    print(f)
'''

list_vala_sources = vala_file_list_template.format('vala')

if get_option('manager')
    subdir('font-manager')
endif

if get_option('viewer')
    subdir('font-viewer')
endif

