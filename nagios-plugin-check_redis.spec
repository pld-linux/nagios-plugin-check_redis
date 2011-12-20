%define		plugin	check_redis
%include	/usr/lib/rpm/macros.perl
Summary:	Nagios Plugin for Redis checks
Name:		nagios-plugin-%{plugin}
Version:	0.1
Release:	1
License:	GPL v2
Group:		Networking
# https://farmerluo.googlecode.com/files/check_redis.pl
Source0:	%{plugin}.pl
Source1:	%{plugin}.cfg
URL:		https://code.google.com/p/farmerluo/downloads/detail?name=check_redis.pl
BuildRequires:	rpm-perlprov >= 4.1-13
Requires:	nagios-common
Requires:	nagios-plugins-libs
BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

# for perl plugins:
%define		_noautoreq	perl(utils)

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
