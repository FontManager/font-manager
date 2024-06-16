
subdir('unicode')

gtk_sources = []
gtk_headers = []
gtk_includes = [
    include_directories('.'),
    unicode_includes
]

result = run_command(python, '-c', list_sources, check: true)

foreach f: result.stdout().strip().split('\n')
    gtk_sources += files(f)
endforeach

result = run_command(python, '-c', list_headers, check: true)

foreach f: result.stdout().strip().split('\n')
    gtk_headers += files(f)
endforeach

