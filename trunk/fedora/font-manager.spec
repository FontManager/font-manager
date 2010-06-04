# Disable the generation of useless debuginfo for the context of this
# generally noarch package (at least to me)
%global         debug_package %{nil}

Name:           font-manager
Version:        0.5.4
Release:        3%{?dist}
Summary:        A font management application for the GNOME desktop environment
Group:          Applications/Publishing
License:        GPLv3+
URL:            http://code.google.com/p/font-manager
Source0:        http://font-manager.googlecode.com/files/%{name}-%{version}.tar.bz2

BuildRoot:      %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

# Explicit dependencies required because there is no automatic dependencies
# resolution for the python modules.
Requires:       fontconfig libxml2-python pygtk2 freetype
BuildRequires:  python desktop-file-utils fontconfig-devel glib2-devel python-devel

%description
Font Manager is an application that allows users to easily manage fonts
on their system.

Although designed with the GNOME desktop environment in mind, it should
work well with most major desktop environments such as XFCE,
Enlightenment, and even KDE.

%prep
%setup -q

%build
%configure
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT
desktop-file-validate $RPM_BUILD_ROOT%{_datadir}/applications/font-manager.desktop

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc AUTHORS ChangeLog COPYING NEWS README TODO
%{_bindir}/font-manager
%{_bindir}/font-sampler
%{_libdir}/font-manager/
%{_datadir}/font-manager/
%{_datadir}/applications/font-manager.desktop

%changelog
* Fri Jun 4 2010 Jerry Casiano <JerryCasiano@gmail.com> - 0.5.4
- Jack the upstream spec for testing
