# Work in progress - GTK 4 port


To build available widgets:

    meson setup build
    ninja -C build test

Running the test target will open a small launcher application which lists 
available widgets and allows running them.

Note : This branch currently requires GTK >= 4.8 and Vala >= 0.56.3 to build.

