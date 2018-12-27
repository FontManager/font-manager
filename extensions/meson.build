
with_nautilus = get_option('nautilus')
with_thunar = get_option('thunarx')
with_nemo = get_option('nemo')

if with_nautilus
    install_data('Nautilus/@0@.py'.format(meson.project_name()),
                 install_dir: join_paths(datadir, 'nautilus-python', 'extensions'))
endif

if with_thunar
    install_data('Thunar/@0@.py'.format(meson.project_name()),
                 install_dir: join_paths(datadir, 'thunarx-python', 'extensions'))
endif

if with_nemo
    install_data('Nemo/@0@.py'.format(meson.project_name()),
                 install_dir: join_paths(datadir, 'nemo-python', 'extensions'))
endif

if with_nautilus or with_thunar or with_nemo and not get_option('disable_pycompile')
    meson.add_install_script('meson_post_install.py')
endif

