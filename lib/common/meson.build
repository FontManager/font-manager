
common_sources = []
common_headers = []
common_includes = include_directories('.')

result = run_command(python, '-c', list_sources, check: true)

foreach f: result.stdout().strip().split('\n')
    common_sources += files(f)
endforeach

result = run_command(python, '-c', list_headers, check: true)

foreach f: result.stdout().strip().split('\n')
    common_headers += files(f)
endforeach

