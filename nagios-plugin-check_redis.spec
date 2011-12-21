%define		plugin	check_redis
%include	/usr/lib/rpm/macros.perl
Summary:	Nagios Plugin for Redis checks
Name:		nagios-plugin-%{plugin}
Version:	0.2
Release:	1
License:	GPL v2
Group:		Networking
Source0:	check_redis.pl
Source1:	%{plugin}.cfg
BuildRequires:	rpm-perlprov >= 4.1-13
Requires:	nagios-common
BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%define		_sysconfdir	/etc/nagios/plugins
%define		plugindir	%{_prefix}/lib/nagios/plugins

%description
Nagios plugin to check Redis servers.

%prep
%setup -qcT
cp -p %{SOURCE0} .

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT{%{_sysconfdir},%{plugindir}}
install -p %{plugin}.pl $RPM_BUILD_ROOT%{plugindir}/%{plugin}
cp -p %{SOURCE1} $RPM_BUILD_ROOT%{_sysconfdir}/%{plugin}.cfg

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(644,root,root,755)
%attr(640,root,nagios) %config(noreplace) %verify(not md5 mtime size) %{_sysconfdir}/%{plugin}.cfg
%attr(755,root,root) %{plugindir}/%{plugin}
