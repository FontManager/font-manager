%global MajorVersion 0
%global MinorVersion 8
%global PatchVersion 8
%global build_timestamp %{lua: print(os.date("%Y%m%d"))}
%global DBusName org.gnome.FontManager
%global DBusName2 org.gnome.FontViewer
%global git_archive https://github.com/FontManager/font-manager/archive/master.tar.gz

%bcond nautilus 1
%bcond nemo 1
%bcond thunar 1
%bcond webkit 1

Name:       font-manager
Version:    %{MajorVersion}.%{MinorVersion}.%{PatchVersion}.%{build_timestamp}
Release:    9
Summary:    A simple font management application for Gtk+ Desktop Environments
License:    GPLv3+
Url:        http://fontmanager.github.io/
Source0:    %{git_archive}

BuildRequires: gettext
BuildRequires: meson
BuildRequires: fontconfig-devel >= 2.12
BuildRequires: freetype-devel
BuildRequires: glib2-devel >= 2.44
BuildRequires: gobject-introspection-devel
BuildRequires: gtk3-devel >= 3.22
BuildRequires: json-glib-devel
BuildRequires: libappstream-glib
BuildRequires: libxml2-devel
BuildRequires: pango-devel
BuildRequires: sqlite-devel
BuildRequires: vala >= 0.42
BuildRequires: yelp-tools
%if %{with webkit}
BuildRequires: libsoup3-devel
BuildRequires: webkit2gtk4.1-devel
%endif

%if %{with nautilus}
BuildRequires: nautilus-devel
%endif
%if %{with nemo}
BuildRequires: nemo-devel
%endif
%if %{with thunar}
BuildRequires: Thunar-devel
%endif

Requires: fontconfig
Requires: %{name}-common
Requires: font-viewer
Requires: freetype
Requires: gtk3 >= 3.22
Requires: sqlite
Requires: yelp
%if %{with webkit}
Requires: libsoup3
Requires: webkit2gtk4.1
%endif

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

%if %{with nautilus}
%package -n nautilus-%{name}
Summary: Nautilus extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
%description -n nautilus-%{name}
This package provides integration with the Nautilus file manager.
%endif

%if %{with nemo}
%package -n nemo-%{name}
Summary: Nemo extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
%description -n nemo-%{name}
This package provides integration with the Nemo file manager.
%endif

%if %{with thunar}
%package -n thunar-%{name}
Summary: Thunar extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
%description -n thunar-%{name}
This package provides integration with the Thunar file manager.
%endif

%prep
%autosetup -n %{name}-master

%build
%meson --buildtype=release \
    -Dnautilus=%{?with_nautilus:true}%{!?with_nautilus:false} \
    -Dnemo=%{?with_nemo:true}%{!?with_nemo:false} \
    -Dthunar=%{?with_thunar:true}%{!?with_thunar:false} \
    -Dwebkit=%{?with_webkit:true}%{!?with_webkit:false} \
    -Dreproducible=true
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

%if %{with nautilus}
%files -n nautilus-%{name}
%{_libdir}/nautilus/extensions*/nautilus-%{name}.so
%endif

%if %{with nemo}
%files -n nemo-%{name}
%{_libdir}/nemo/extensions-3.0/nemo-%{name}.so
%endif

%if %{with thunar}
%files -n thunar-%{name}
%{_libdir}/thunarx-3/thunar-%{name}.so
%endif

%changelog
* Sat Feb 4 2023 JerryCasiano <JerryCasiano@gmail.com> 0.8.8-9
- Refer to https://github.com/FontManager/font-manager/commits/master for changes.
