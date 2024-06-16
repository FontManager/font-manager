
fontconfig_sources = []
fontconfig_headers = []
fontconfig_includes = include_directories('.')

result = run_command(python, '-c', list_sources, check: true)

foreach f: result.stdout().strip().split('\n')
    fontconfig_sources += files(f)
endforeach

result = run_command(python, '-c', list_headers, check: true)

foreach f: result.stdout().strip().split('\n')
    fontconfig_headers += files(f)
endforeach

