%global MajorVersion 0
%global MinorVersion 8
%global PatchVersion 3
%global build_timestamp %{lua: print(os.date("%Y%m%d"))}
%global DBusName org.gnome.FontManager
%global DBusName2 org.gnome.FontViewer
%global git_archive https://github.com/FontManager/font-manager/archive/master.tar.gz

Name:       font-manager
Version:    %{MajorVersion}.%{MinorVersion}.%{PatchVersion}.%{build_timestamp}
Release:    4
Summary:    A simple font management application for Gtk+ Desktop Environments
License:    GPLv3+
Url:        http://fontmanager.github.io/
Source0:    %{git_archive}

BuildRequires: gettext
BuildRequires: meson
BuildRequires: fontconfig-devel
BuildRequires: freetype-devel
BuildRequires: glib2-devel >= 2.44
BuildRequires: gobject-introspection-devel
BuildRequires: gtk3-devel >= 3.22
BuildRequires: json-glib-devel
BuildRequires: libappstream-glib
BuildRequires: libsoup-devel
BuildRequires: libxml2-devel
BuildRequires: pango-devel
BuildRequires: sqlite-devel
BuildRequires: vala >= 0.42
BuildRequires: webkit2gtk3-devel
BuildRequires: yelp-tools

BuildRequires: nautilus-devel
BuildRequires: nemo-devel
BuildRequires: Thunar-devel

Requires: fontconfig
Requires: %{name}-common
Requires: font-viewer
Requires: freetype
Requires: gtk3 >= 3.22
Requires: libsoup
Requires: sqlite
Requires: webkit2gtk3
Requires: yelp

%description
Font Manager is intended to provide a way for average users to easily
 manage desktop fonts, without having to resort to command line tools
 or editing configuration files by hand. While designed primarily with
 the Gnome Desktop Environment in mind, it should work well with other
 Gtk+ desktop environments.

Font Manager is NOT a professional-grade font management solution.

%package -n %{name}-common
Summary: Common files used by font-manager
%description -n %{name}-common
This package contains common files such as libraries, help files,
 translations, etc.
 These files are required by font-manager and font-viewer.

%package -n font-viewer
Summary: Full featured font file preview application for GTK+ Desktop Environments
Requires: %{name}-common >= %{version}
%description -n font-viewer
This package contains the font-viewer component of font-manager.

%package -n nautilus-%{name}
Summary: Nautilus extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
%description -n nautilus-%{name}
This package provides integration with the Nautilus file manager.

%package -n nemo-%{name}
Summary: Nemo extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
%description -n nemo-%{name}
This package provides integration with the Nemo file manager.

%package -n thunar-%{name}
Summary: Thunar extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
%description -n thunar-%{name}
This package provides integration with the Thunar file manager.

%prep
%autosetup -n %{name}-master

%build
%meson --buildtype=debugoptimized -Dnautilus=True -Dnemo=True -Dthunar=True
%meson_build

%install
%meson_install

%find_lang %{name}

%check
appstream-util validate-relax --nonet %{buildroot}/%{_datadir}/metainfo/*.appdata.xml

%posttrans
/usr/bin/glib-compile-schemas %{_datadir}/glib-2.0/schemas &> /dev/null || :

%files
%{_bindir}/%{name}
%{_datadir}/metainfo/%{DBusName}.appdata.xml
%{_datadir}/applications/%{DBusName}.desktop
%{_datadir}/dbus-1/services/%{DBusName}.service
%{_datadir}/glib-2.0/schemas/%{DBusName}.gschema.xml
%{_datadir}/gnome-shell/search-providers/%{DBusName}.SearchProvider.ini
%{_datadir}/icons/hicolor/128x128/apps/%{DBusName}.png
%{_datadir}/icons/hicolor/256x256/apps/%{DBusName}.png
%{_mandir}/man1/%{name}.*

%files -n %{name}-common -f %{name}.lang
%license COPYING
%{_libdir}/%{name}
%{_datadir}/help/*/%{name}

%files -n font-viewer
%{_libexecdir}/%{name}/font-viewer
%{_datadir}/metainfo/%{DBusName2}.appdata.xml
%{_datadir}/applications/%{DBusName2}.desktop
%{_datadir}/dbus-1/services/%{DBusName2}.service
%{_datadir}/glib-2.0/schemas/%{DBusName2}.gschema.xml
%{_datadir}/icons/hicolor/128x128/apps/%{DBusName2}.png
%{_datadir}/icons/hicolor/256x256/apps/%{DBusName2}.png

%files -n nautilus-%{name}
%{_libdir}/nautilus/extensions-3.0/nautilus-%{name}.so

%files -n nemo-%{name}
%{_libdir}/nemo/extensions-3.0/nemo-%{name}.so

%files -n thunar-%{name}
%{_libdir}/thunarx-3/thunar-%{name}.so

%changelog
* Tue Dec 1 2020 JerryCasiano <JerryCasiano@gmail.com> 0.8.3-4
- Refer to https://github.com/FontManager/font-manager/commits/master for changes.
