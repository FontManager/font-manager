
unicode_sources = []
unicode_headers = []
unicode_includes = include_directories('.')

result = run_command(python, '-c', list_sources, check: true)

foreach f: result.stdout().strip().split('\n')
    unicode_sources += files(f)
endforeach

result = run_command(python, '-c', list_headers, check: true)

foreach f: result.stdout().strip().split('\n')
    unicode_headers += files(f)
endforeach

