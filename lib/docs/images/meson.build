
list_assets = file_list_template.format('png')

html_assets = []

result = run_command(python, '-c', list_assets)

foreach f: result.stdout().strip().split('\n')
    html_assets += files(f)
endforeach
