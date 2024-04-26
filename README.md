# Work in progress - GTK 4 port

To build:

    meson setup build
    ninja -C build
    ./build/tests/updatedb

    ./build/src/font-manager/font-manager

    or

    ./build/src/font-viewer/font-viewer

Keep in mind that while close not everything is complete. 
Most things work but something not working is not necessarily a bug,
it's most likely just not ported/implemented yet.

If in doubt please ask in issue #286 before filing a bug report.

Note : This branch currently requires GTK >= 4.10 and Vala >= 0.56.3 to build.

