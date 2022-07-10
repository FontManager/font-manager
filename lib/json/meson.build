
json_sources = []
json_headers = []
json_includes = include_directories('.')

result = run_command(python, '-c', list_sources, check: true)

foreach f: result.stdout().strip().split('\n')
    json_sources += files(f)
endforeach

result = run_command(python, '-c', list_headers, check: true)

foreach f: result.stdout().strip().split('\n')
    json_headers += files(f)
endforeach

