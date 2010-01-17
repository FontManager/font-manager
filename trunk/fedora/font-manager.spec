Name:           font-manager
Version:        0.4.3
Release:        1%{?dist}
Summary:        A font management application for the GNOME desktop environment

Group:          Applications/Publishing
License:        GPLv3

Source0:        %{name}-%{version}.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:      noarch
BuildRequires:  make
BuildRequires:  python
Requires:       pygtk2
Requires:       libxml2-python
Requires:       fontconfig
Requires:       xorg-x11-font-utils

%description
Font Manager is an application that allows users to easily manage fonts on their system.

Although designed with the GNOME desktop environment in mind, it should work well with most major desktop environments such as XFCE, Enlightenment, and even KDE.

%prep
%setup -q

%build
%configure --prefix=/usr
make

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
# no translations yet
# %find_lang %{name}

%clean
rm -rf $RPM_BUILD_ROOT

#%files -f %{name}.lang
%files
%defattr(-,root,root,-)
%doc
%{_bindir}/*
%dir %{_datadir}/font-manager
%{_datadir}/font-manager/*
%{_datadir}/applications/*


%changelog
* Sun Jan 17 2010 JC

- Update to 0.4.3

- Added the following options

  Start application at login
  Start application minimized
  Include pangram in sample sheets
  Set default font size for sample sheets

- Removed unnecessary, possibly confusing, confirmation dialog 
  when removing collections.

- Correct permissions for installed files.

- Some code cleanup

- Clean up obsolete files.

* Wed Nov 25 2009 JC

- Update to 0.4.2

- Fix tray icon behavior, clicking it should always have an effect

- Fix homepage link in about dialog

- Don't allow exporting of empty collections, duh

- Include AFM files when exporting Type 1 fonts, oops, must
  not be a lot of use for this function or maybe Type 1 fonts,
  or someone would have mentioned it... oh, well it's useful to me. ;-)

- Ask for confirmation before exporting a collection
  Fix http://code.google.com/p/font-manager/issues/detail?id=6 by
  allowing user to specify where exported collection is to be saved,
  whether it should be compressed or not, and whether to include
  a sample sheet in the archive or folder.

- This last feature only works if ReportLab is installed and then
  only for Truetype and Type 1 fonts. Open Type supposedly works
  but I don't have any that do.

* Wed Sep 23 2009 JC

- Update to 0.4.1

- Restart application instead of attempting to reload in place.

* Mon Sep 21 2009 JC

- Update to 0.4

- Re-factored user interface to have a more flexible layout and take up
  less space while displaying the same amount of information.

- Added font installation/removal.

- Various bug fixes.

* Mon Sep 7 2009 JC

- Update to 0.3

- Added the ability to compare fonts, thanks to gnome-specimen.

- When detailed info is requested it now brings up the selected style.

- Changed the way font information is loaded, this allows the application
  to have a map of exactly which files belong to which font family.
  It unfortunately also means that loading fonts is significantly slower,
  to compensate for this, results are now cached and re-used.

  Startup times on an X2 5600+ :

  First run  - 6300 fonts = 3m30.738s - Ouch!
  Second run - same fonts = 0m4.969s

  Also added a basic splash screen to provide some feedback in case
  someone actually has that many active fonts on their system.

- Various bug fixes.

- Code cleanup.

* Tue Aug 18 2009 JC

- Update to 0.2

- Properly handle font names containing illegal characters.

- Return only the first result when detailed info is requested

- Added option to select different directories to scan for fonts

- Added option to export collections to an archive ( requires file-roller )

- Added a category for fonts not present in user collections

- Added preferences dialog

* Tue Aug 11 2009 JC

- Initial build.


