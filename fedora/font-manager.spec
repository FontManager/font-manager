%define MajorVersion 0
%define MinorVersion 7
%define MicroVersion 3
%define DBusName org.gnome.FontManager
%define DBusName2 org.gnome.FontViewer
%define DownloadURL https://github.com/FontManager/master/releases/download

Name:       font-manager
Version:    %{MajorVersion}.%{MinorVersion}.%{MicroVersion}
Release:    9
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
Requires: font-manager-common >= %{version}
%description -n font-viewer
This package contains the font-viewer component of font-manager.

%package -n nautilus-font-manager
BuildArch: noarch
Summary: Nautilus extension for font-manager
Requires: font-viewer >= %{version}
Requires: font-manager-common >= %{version}
Requires: nautilus-python
Requires: dbus-python
%description -n nautilus-font-manager
This package provides integration with the Nautilus file manager.

%package -n nemo-font-manager
BuildArch: noarch
Summary: Nemo extension for Font Manager
Requires: font-viewer >= %{version}
Requires: font-manager-common >= %{version}
Requires: nemo-python
Requires: dbus-python
%description -n nemo-font-manager
This package provides integration with the Nemo file manager.

%package -n thunarx-font-manager
BuildArch: noarch
Summary: Thunar extension for Font Manager
Requires: font-viewer >= %{version}
Requires: font-manager-common >= %{version}
Requires: thunarx-python
Requires: dbus-python
%description -n thunarx-font-manager
This package provides integration with the Thunar file manager.

%prep
%setup -q

%build
%configure --disable-schemas-compile --with-file-roller --with-nautilus --with-nemo --with-thunarx
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
%{_mandir}/man1/%{name}.*

%files -n %{name}-common -f %{name}.lang
%doc README
%{_libdir}/%{name}
%{_datadir}/help/*/%{name}

%files -n font-viewer
%{_libexecdir}/%{name}/font-viewer
%{_datadir}/applications/%{DBusName2}.desktop
%{_datadir}/dbus-1/services/%{DBusName2}.service
%{_datadir}/glib-2.0/schemas/%{DBusName2}.gschema.xml

%files -n nautilus-font-manager
%{_datadir}/nautilus-python/extensions/%{name}.py*

%files -n nemo-font-manager
%{_datadir}/nemo-python/extensions/%{name}.py*

%files -n thunarx-font-manager
%{_datadir}/thunarx-python/extensions/%{name}.py*

%changelog
* Sun Oct 16 2016 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-9
- Fix extension requirements
* Sat Jun 4 2016 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-8
- Fix initial window size issue on Gtk+ > 3.18
* Wed Jun 1 2016 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-7
- Add Polish translation provided by Piotr Strębski
* Thu May 26 2016 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-6
- Add manual page
* Thu Apr 21 2016 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-5
- Drop build deps for python extensions
- Enable all extensions
- Update to latest git
* Sat Mar 5 2016 JerryCasiano <JerryCasiano@gmail.com> 0.7.3-4
- Update to latest git to include new features.
- Added preference pane.
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


