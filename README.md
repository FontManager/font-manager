
# Font Manager <img src="help/C/media/preferences-desktop-font.png" align="right">

A simple font management application for GTK Desktop Environments

![Main Window](https://github.com/FontManager/resources/blob/master/font-manager.png?raw=true)

Font Manager is intended to provide a way for average users to easily manage desktop fonts, without having to resort to command line tools or editing configuration files by hand. While designed primarily with the Gnome Desktop Environment in mind, it should work well with other GTK desktop environments.

Font Manager is NOT a professional-grade font management solution.

## Features

- Preview and compare font files
- Activate or deactivate installed font families
- Automatic categorization based on font properties
- Integrated character map
- User font collections
- User font installation and removal
- User font directory settings
- User font substitution settings
- Desktop font settings (GNOME Desktop or compatible environments)

## Installation

### Distribution packages

#### Arch User Repository
Arch Linux users can find [`font-manager`](https://aur.archlinux.org/packages/font-manager/) in the AUR

#### Fedora COPR 

<img src="https://copr.fedorainfracloud.org/coprs/jerrycasiano/FontManager/package/font-manager/status_image/last_build.png" />

Fedora packages built from latest revision:

```
dnf copr enable jerrycasiano/FontManager
dnf install font-manager
```

Please note that packages in COPR can conflict with official packages. 
Make sure to purge any previous installation before switching between COPR and official sources.

#### Ubuntu Personal Package Archive
Ubuntu packages built from latest revision:

```
sudo add-apt-repository ppa:font-manager/staging
sudo apt-get update
sudo apt-get install font-manager
```
Please note that packages in the PPA can conflict with official packages. 
Make sure to purge any previous installation before switching between PPA and official sources.


### Building from source

You'll need to ensure the following dependencies are installed:

- `meson`
- `ninja`
- `gtk+-3.0 >= 3.22`
- `json-glib-1.0 >= 0.15`
- `sqlite3 >= 3.8`
- `libxml-2.0 >= 2.9`
- `vala >= 0.42`

To build the application:

```
meson --prefix=/usr --buildtype=release build
cd build
ninja
```

To run the application without installing:

```
src/font-manager/font-manager
```

To install the application:

```
sudo ninja install
```

To uninstall:

```
sudo ninja uninstall
```

## License

[GPL 3](COPYING)

