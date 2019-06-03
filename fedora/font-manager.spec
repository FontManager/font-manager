%global MajorVersion 0
%global MinorVersion 7
%global PatchVersion 5
%global build_timestamp %{lua: print(os.date("%Y%m%d"))}
%global DBusName org.gnome.FontManager
%global DBusName2 org.gnome.FontViewer
%global git_archive https://github.com/FontManager/font-manager/archive/master.tar.gz

# Disable automatic compilation of Python files in extra directories
%undefine __brp_python_bytecompile
%global _python_bytecompile_extra 0

Name:       font-manager
Version:    %{MajorVersion}.%{MinorVersion}.%{PatchVersion}.%{build_timestamp}
Release:    1
Summary:    A simple font management application for Gtk+ Desktop Environments
License:    GPLv3+
Url:        http://fontmanager.github.io/
Source0:    %{git_archive}

BuildRequires: gettext
BuildRequires: meson
BuildRequires: fontconfig-devel
BuildRequires: freetype-devel
BuildRequires: glib2-devel
BuildRequires: gobject-introspection-devel
BuildRequires: gtk3-devel >= 3.22
BuildRequires: json-glib-devel
BuildRequires: libappstream-glib
BuildRequires: libxml2-devel
BuildRequires: pango-devel
BuildRequires: sqlite-devel
BuildRequires: vala >= 0.42
BuildRequires: yelp-tools
BuildRequires: /usr/bin/python
BuildRequires: python2-devel python3-devel

Requires: fontconfig
Requires: %{name}-common
Requires: font-viewer
Requires: freetype
Requires: gtk3 >= 3.22
Requires: sqlite
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
BuildArch: noarch
Summary: Nautilus extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
Requires: nautilus-python
Requires: dbus-python
%description -n nautilus-%{name}
This package provides integration with the Nautilus file manager.

%package -n nemo-%{name}
BuildArch: noarch
Summary: Nemo extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
Requires: nemo-python
Requires: dbus-python
%description -n nemo-%{name}
This package provides integration with the Nemo file manager.

%package -n thunarx-%{name}
BuildArch: noarch
Summary: Thunar extension for Font Manager
Requires: font-viewer >= %{version}
Requires: %{name}-common >= %{version}
Requires: thunarx-python
Requires: dbus-python
%description -n thunarx-%{name}
This package provides integration with the Thunar file manager.

%prep
%autosetup -n %{name}-master

%build
%meson --buildtype=debugoptimized -Ddisable_pycompile=True -Dnautilus=True -Dnemo=True -Dthunarx=True
%meson_build

%install
%meson_install
%py_byte_compile %{__python} %{buildroot}%{_datadir}/nautilus-python/extensions/
%py_byte_compile %{__python} %{buildroot}%{_datadir}/nemo-python/extensions/
%py_byte_compile %{__python} %{buildroot}%{_datadir}/thunarx-python/extensions/
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

%files -n nautilus-%{name}
%{_datadir}/nautilus-python/extensions/%{name}.py*

%files -n nemo-%{name}
%{_datadir}/nemo-python/extensions/%{name}.py*

%files -n thunarx-%{name}
%{_datadir}/thunarx-python/extensions/%{name}.py*

%changelog
* Sat May 11 2019 JerryCasiano <JerryCasiano@gmail.com> 0.7.5-1
- Refer to https://github.com/FontManager/font-manager/commits/master for changes.

