
gresources = gnome.compile_resources('gresources', 'gresources.xml', c_name: 'test')

updatedb = executable('updatedb',
                      dependencies: [ vala_deps, vapi ],
                      link_with: vala_test_lib,
                      include_directories: includes,
                      sources: [ 'updatedb.vala' ])

list_tests = '''
import json
with open('tests.json', 'r') as data:
    test_list = json.loads(data.read())
for test in test_list:
    print(test['name'])
'''

test_list = run_command(python, '-c', list_tests, check: true)
tests = test_list.stdout().strip().split('\n')

subdir('application')
subdir('tests')

