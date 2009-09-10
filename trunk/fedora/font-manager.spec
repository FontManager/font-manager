Name:           font-manager
Version:        0.2
Release:        1%{?dist}
Summary:        A font management application for the GNOME desktop environment

Group:          Applications/Publishing
License:        GPLv3

Source0:        %{name}-%{version}.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:		noarch
BuildRequires:	autoconf
BuildRequires:  automake
BuildRequires:	pygtk2
Requires:  		pygtk2
Requires:  		libxml2-python
Requires: 		fontconfig

%description
Font Manager is an application that allows users to easily manage fonts on their system.

Although designed with the GNOME desktop environment in mind, it should work well with most major desktop environments such as XFCE, Enlightenment, and even KDE.

%prep
%setup -q

%build
autoreconf -i
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

* Tue Aug 18 2009 JC
- Update to 0.2
- Fix - Properly handle font names containing illegal characters.
- Fix - Return only the first result when detailed info is requested
- New feature - Added option to select different directories to scan for fonts
- New feature - Added option to export collections to an archive ( requires file-roller )
- New feature - Added a category for fonts not present in user collections
- New feature - Added preferences dialog

* Tue Aug 11 2009 JC
- Initial build.


