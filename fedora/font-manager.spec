%global MajorVersion 0
%global MinorVersion 9
%global PatchVersion 0
%global build_timestamp %{lua: print(os.date("%Y%m%d"))}
%global DBusName com.github.FontManager.FontManager
%global DBusName2 com.github.FontManager.FontViewer
%global git_archive https://github.com/FontManager/font-manager/archive/master.tar.gz

%bcond adwaita 1
%bcond nautilus 1
%bcond nemo 1
%bcond thunar 1
%bcond webkit 1

Name:       font-manager
Version:    %{MajorVersion}.%{MinorVersion}.%{PatchVersion}.%{build_timestamp}
Release:    1
Summary:    A simple font management application for Gtk+ Desktop Environments
License:    GPLv3+
Url:        http://fontmanager.github.io/
Source0:    %{git_archive}

BuildRequires: gettext
BuildRequires: meson
BuildRequires: fontconfig-devel >= 2.12
BuildRequires: freetype-devel >= 2.10
BuildRequires: glib2-devel >= 2.62
BuildRequires: gobject-introspection-devel
BuildRequires: gtk4-devel >= 4.12
BuildRequires: json-glib-devel >= 1.5
BuildRequires: libappstream-glib
BuildRequires: libxml2-devel >= 2.9.10
BuildRequires: pango-devel >= 1.45
BuildRequires: sqlite-devel >= 3.35
BuildRequires: vala >= 0.42
BuildRequires: yelp-tools
%if %{with webkit}
BuildRequires: libsoup3-devel >= 3.2
BuildRequires: webkitgtk6.0-devel >= 2.4
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
Requires: gtk4 >= 4.12
Requires: sqlite
Requires: yelp
%if %{with webkit}
Requires: libsoup3
Requires: webkitgtk6.0
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
    -Dadwaita=%{?with_adwaita:true}%{!?with_adwaita:false} \
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
%{_datadir}/gnome-shell/search-providers/%{DBusName}.SearchProvider.ini
%{_datadir}/icons/hicolor/scalable/apps/%{DBusName}.svg
%{_datadir}/icons/hicolor/symbolic/apps/%{DBusName}.svg
%{_mandir}/man1/%{name}.*

%files -n %{name}-common -f %{name}.lang
%license COPYING
%{_libdir}/%{name}
%{_datadir}/help/*/%{name}
%{_datadir}/glib-2.0/schemas/%{DBusName}.gschema.xml

%files -n font-viewer
%{_libexecdir}/%{name}/font-viewer
%{_datadir}/metainfo/%{DBusName2}.appdata.xml
%{_datadir}/applications/%{DBusName2}.desktop
%{_datadir}/dbus-1/services/%{DBusName2}.service
%{_datadir}/glib-2.0/schemas/%{DBusName2}.gschema.xml
%{_datadir}/icons/hicolor/scalable/apps/%{DBusName2}.svg
%{_datadir}/icons/hicolor/symbolic/apps/%{DBusName2}.svg

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
* Tue Jun 4 2024 JerryCasiano <JerryCasiano@gmail.com> 0.9.0-1
- Refer to https://github.com/FontManager/font-manager/commits/master for changes.

