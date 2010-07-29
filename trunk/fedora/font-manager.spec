Name:           font-manager
Version:        0.5.5
Release:        3%{?dist}
Summary:        A font management application for the GNOME desktop environment
Group:          Applications/Publishing
License:        GPLv3+
URL:            http://code.google.com/p/font-manager
Source0:        http://font-manager.googlecode.com/files/%{name}-%{version}.tar.bz2

BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

# Explicit dependencies required because there is no automatic dependencies
# resolution for the python modules.
Requires:       fontconfig libxml2-python pygtk2 freetype pango
BuildRequires:  python desktop-file-utils fontconfig-devel glib2-devel python-devel pango-devel

%description
Font Manager is an application that allows users to easily manage fonts
on their system.

Although designed with the GNOME desktop environment in mind, it should
work well with most major desktop environments such as XFCE,
Enlightenment, and even KDE.

%prep
%setup -q

%build
%configure --enable-debuginfo
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
desktop-file-validate $RPM_BUILD_ROOT%{_datadir}/applications/font-manager.desktop

# Make file executable to be picked up by find-debuginfo.sh
chmod +x $RPM_BUILD_ROOT%{_libdir}/font-manager/_fontutils.so

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc AUTHORS ChangeLog COPYING NEWS README TODO
%{_bindir}/font-manager
%{_bindir}/font-sampler
%{_libdir}/font-manager/
%{_datadir}/font-manager/
%{_datadir}/applications/*.desktop

%changelog
* Fri Jul 29 2010 Jerry Casiano <JerryCasiano@gmail.com> - 0.5.5-5
- Update to latest

* Wed Jun  9 2010 Jerry Casiano <JerryCasiano@gmail.com> - 0.5.4-5
- Provide an --enable-debuginfo switch for packagers
- Include all desktop files

* Tue Jun  8 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.5.4-4
- Fix library issue
- Fix compilation issue with Fedora
- Fix the creation of a useful debuginfo package

* Thu Jun  3 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.5.4-3
- Include some fixes by upstream for the compilation error on x86_64

* Thu Jun  3 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.5.4-2
- Fix the compilation error on x86_64
- Fix some BuildRequires for the new version

* Wed Jun  2 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.5.4-1
- Update to new upstream version

* Wed Apr 14 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.4.4-1
- Update to new upstream version

* Sun Jan 17 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.4.3-1
- Update to new upstream version
- Remove patches as they are not necessary anymore
- Adjust python optimization

* Wed Jan  6 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.4.2-5
- Fix license string
- Fix upstream Makefile to include *.py file with *.pyc and *.pyo

* Sun Jan  3 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.4.2-4
- Fix permission problem on .desktop file directly with a patch

* Sun Jan  3 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.4.2-3
- Fix permission problem on .desktop file
- Fix wildcards problem in file section

* Sun Jan  3 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.4.2-2
- Fix as per the recommendations on bug #551878

* Sat Jan  2 2010 Jean-Francois Saucier <jfsaucier@infoglobe.ca> - 0.4.2-1
- Initial build for Fedora
