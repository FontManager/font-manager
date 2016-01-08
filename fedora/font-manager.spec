%define MajorVersion 0
%define MinorVersion 7
%define MicroVersion 3
%define DBusName org.gnome.FontManager
%define DownloadURL https://github.com/FontManager/master/releases/download

Name:       font-manager
Version:    %{MajorVersion}.%{MinorVersion}.%{MicroVersion}
Release:    3
Summary:    A simple font management application for Gtk+ Desktop Environments
License:    GPLv3+
Url:        http://fontmanager.github.io/
Source0:    %{DownloadURL}/%{version}/%{name}-%{version}.tar.bz2

BuildRequires: cairo-devel
BuildRequires: file-roller
BuildRequires: fontconfig-devel
BuildRequires: freetype-devel
BuildRequires: glib2-devel
BuildRequires: gobject-introspection-devel
BuildRequires: gtk3-devel >= 3.12
BuildRequires: gucharmap-devel
BuildRequires: intltool
BuildRequires: json-glib-devel
BuildRequires: libappstream-glib
BuildRequires: libgee-devel
BuildRequires: libxml2-devel
BuildRequires: nautilus-python-devel
BuildRequires: nemo-python-devel
BuildRequires: pango-devel
BuildRequires: sqlite-devel
BuildRequires: vala >= 0.24
BuildRequires: yelp-tools

Requires: fontconfig
Requires: file-roller
Requires: font-manager-common
Requires: font-viewer
Requires: freetype
Requires: gtk3 >= 3.12
Requires: gucharmap-libs
Requires: json-glib
Requires: libgee
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
This package contains common files such as libraries, help files, translations, etc.
These files are required by font-manager and font-viewer.

%package -n font-viewer
Summary: Full featured font file preview application for GTK+ Desktop Environments
Requires: font-manager-common >= %{MajorVersion}.%{MinorVersion}.%{MicroVersion}
%description -n font-viewer
This package contains the font-viewer component of font-manager.

%package -n nautilus-font-manager
BuildArch: noarch
Summary: Nautilus extension for font-manager
Requires: font-viewer >= %{MajorVersion}.%{MinorVersion}.%{MicroVersion}
Requires: font-manager-common >= %{MajorVersion}.%{MinorVersion}.%{MicroVersion}
Requires: nautilus-python
%description -n nautilus-font-manager
This package provides integration with the Nautilus file manager.

%package -n nemo-font-manager
BuildArch: noarch
Summary: Nemo extension for Font Manager
Requires: font-manager nemo-python
%description -n nemo-font-manager
This package provides integration with the Nemo file manager.

%prep
%setup -q

%build
%configure --disable-schemas-compile --with-nautilus --with-nemo
make

%check
appstream-util validate-relax --nonet %{buildroot}/%{_datadir}/appdata/*.appdata.xml

%install
%make_install
%find_lang %name

%posttrans
/usr/bin/glib-compile-schemas %{_datadir}/glib-2.0/schemas &> /dev/null || :

%files
%{_bindir}/%{name}
%{_datadir}/appdata/%{DBusName}.appdata.xml
%{_datadir}/applications/%{DBusName}.desktop
%{_datadir}/dbus-1/services/%{DBusName}.service
%{_datadir}/glib-2.0/schemas/%{DBusName}.gschema.xml

%files -n %{name}-common -f %{name}.lang
%doc README
%{_libdir}/%{name}
%{_datadir}/help/C/%{name}

%files -n font-viewer
%{_libexecdir}/%{name}/font-viewer
%{_datadir}/applications/org.gnome.FontViewer.desktop
%{_datadir}/dbus-1/services/org.gnome.FontViewer.service
%{_datadir}/glib-2.0/schemas/org.gnome.FontViewer.gschema.xml

%files -n nautilus-font-manager
%{_datadir}/nautilus-python/extensions/%{name}.py*

%files -n nemo-font-manager
%{_datadir}/nemo-python/extensions/%{name}.py*

%changelog
* Wed Jan 06 2016 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-3
- Update to latest git to include bug fixes.
* Wed Dec 23 2015 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-2
- Leigh Scott enabled nemo extension for actual Fedora package
- Must *work* on Cinnamon...
* Tue Dec 8 2015 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-1
- Update to testing branch 0.7.3
* Sat Jun 06 2015 JerryCasiano <JerryCasiano@gmail.com> 0.7.2-5
- Add missing Requires for Nautilus extension.
* Sat Jun 06 2015 JerryCasiano <JerryCasiano@gmail.com> 0.7.2-4
- Add missing BuildRequires for file-roller. Fails to mock.
* Tue Jun 02 2015 JerryCasiano <JerryCasiano@gmail.com> 0.7.2-3
- Adhere to https://fedoraproject.org/wiki/Packaging:AppData
* Thu May 28 2015 JerryCasiano <JerryCasiano@gmail.com> 0.7.2-2
- Add missing Requires
* Sun Jan 25 2015 JerryCasiano <JerryCasiano@gmail.com> 0.7.2-1
- Update to 0.7.2
* Sat Dec 13 2014 JerryCasiano <JerryCasiano@gmail.com> 0.7.1-1
- Initial build.


