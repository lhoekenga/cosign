%define httpdver apache2
%define _moddir %{_libdir}/httpd/modules
%define _cgibindir /var/www/cgi-bin
%define _crondir %{_sysconfdir}/cron.hourly
%if 0%{?rhel} >= 7
%define _httpdconfmodulesddir %{_sysconfdir}/httpd/conf.modules.d
%define _apxs %{_bindir}/apxs
%else
%define _httpdconfmodulesddir %{_sysconfdir}/httpd/conf.d
%define _apxs %{_sbindir}/apxs
%endif

%define _httpdbuildver %( rpm -q --qf '[%{VERSION}]' httpd-devel )

Name:     httpd-cosign
Version:  3.2.0
Release:  9%{?dist}
Summary:  Secure, Intra-Institutional Web Authentication

Group:    Applications/System
License:  University of Michigan
Vendor:   University of Michigan
URL: http://weblogin.org/

Source0: cosign-%{version}.tar.gz
Source1: cosign.cron
Source2: cosign.conf
Source3: cgi-bin.logout.pl
Patch0: cosign_script_path.patch
Patch1: apache24cosign320.patch

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%if 0%{?rhel} >= 7
BuildRequires: apr-devel >= 1, apr-devel < 2, httpd-devel >= 2.4, httpd-devel < 2.5, openssl-devel >= 0.9.7a, cyrus-sasl-devel, krb5-devel
Requires: httpd = %{_httpdbuildver}
%else
BuildRequires: apr-devel >= 1, apr-devel < 2, httpd-devel >= 2.2, httpd-devel < 2.3, openssl-devel >= 0.9.7a, cyrus-sasl-devel, krb5-devel
Requires: httpd = %{_httpdbuildver}
%endif

%description
An open source project originally designed to provide the University of Michigan with a secure single sign-on web authentication system. Cosign is part of the National Science Foundation Middleware Initiative (NMI) EDIT software release.

%prep
%setup -q -n cosign-%{version}


# Change the paths in the perl/python scripts to /usr/bin from /usr/local/bin
%patch0 -p1

%if 0%{?rhel} >= 7
# Change mod_cosign to work with Apache 2.4.
%patch1 -p1
%endif

%build
%{__mkdir_p} .tmpdoc
%{__cp} -pr --parents scripts/cron   .tmpdoc/
%{__cp} -pr --parents scripts/logout .tmpdoc/

%configure --enable-krb --with-filterdb=%{_localstatedir}/cosign/filter --with-ticketcache=%{_localstatedir}/cosign/ticket --with-proxydb=%{_localstatedir}/cosign/proxy --with-gss --with-ssl=/usr --enable-%{httpdver}=%{_apxs}

make %{?_smp_mflags}
#%{__make}

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%{__mkdir_p} %{buildroot}%{_moddir}
install -m 0755 filters/%{httpdver}/.libs/mod_cosign.so %{buildroot}%{_moddir}/
find %{buildroot}%{_libdir} -type f -name lib\*.so.\* -exec chmod 755 {} \;

%{__mkdir_p} %{buildroot}%{_crondir}
install -m 0755 %{SOURCE1} %{buildroot}%{_crondir}/httpd-cosign

%{__mkdir_p} %{buildroot}%{_httpdconfmodulesddir}
install -m 0644 %{SOURCE2} %{buildroot}%{_httpdconfmodulesddir}/cosign.conf

%{__mkdir_p} %{buildroot}%{_cgibindir}
install -m 0755 %{SOURCE3} %{buildroot}%{_cgibindir}/logout

# create the filter cache directory
%{__mkdir_p} %{buildroot}%{_localstatedir}/cosign/filter

# create the krb5 ticket cache directory
%{__mkdir_p} %{buildroot}%{_localstatedir}/cosign/ticket

# create the proxy cache directory
%{__mkdir_p} %{buildroot}%{_localstatedir}/cosign/proxy

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

%pre
if [ $1 -gt 1 ] ; then
	/usr/sbin/semanage fcontext -d -t httpd_sys_content_t '%{_localstatedir}/cosign(/.*)?' 2>/dev/null || :
	/usr/sbin/semanage fcontext -d -t httpd_tmp_t '%{_localstatedir}/cosign/.+' 2>/dev/null || :
fi

%post

/usr/sbin/semanage fcontext -a -t httpd_tmp_t '%{_localstatedir}/cosign/.+' 2>/dev/null || :
/sbin/restorecon -R %{_localstatedir}/cosign || :

/usr/sbin/setsebool -P httpd_can_network_connect=1 || :

%postun

# final removal
if [ $1 -eq 0 ] ; then
	/usr/sbin/semanage fcontext -d -t httpd_tmp_t '%{_localstatedir}/cosign/.+' 2>/dev/null || :
	/sbin/restorecon -R %{_localstatedir}/cosign || :

	/usr/sbin/setsebool -P httpd_can_network_connect=0 || :
fi

%files
%defattr(-,root,root)
%{_moddir}/mod_cosign.so
%{_crondir}/httpd-cosign
%{_httpdconfmodulesddir}/cosign.conf
%{_cgibindir}/logout
%attr(0700,apache,root) %dir %{_localstatedir}/cosign/filter
%attr(1733,root,root) %dir %{_localstatedir}/cosign/ticket
#%doc README README.scripts LICENSE Contributors
%doc CHANGELOG LICENSE README README.basicauth README.weblogin VERSION
%doc .tmpdoc/scripts/

%changelog
* Fri Feb 03 2017 Kelly L. Stam <kstam@umich.edu> - 3.2.0-9
- added scripts doc directory back in

* Wed Feb 01 2017 Kelly L. Stam <kstam@umich.edu> - 3.2.0-8
- Updating to add conditionals based on rhel, amazon, etc

* Wed Apr 27 2016 Kelly L. Stam <kstam@umich.edu> - 3.2.0-7
- Moved cosign.conf to conf.modules.d where the LoadModule configs go.

* Thu May 07 2015 Kelly L. Stam <kstam@umich.edu> - 3.2.0-6
- Reworked to pass rpmlint and run through mock framework

* Wed Dec 10 2014 Kelly L. Stam <kstam@umich.edu> - 3.2.0-5
- Fixed /var/cosign/ticket ownership/permissions to align with typical ticket
  safety setup.
- Updated SElinux contexts for RHEL7.

* Wed Jul 23 2014 Kelly L. Stam <kstam@umich.edu> - 3.2.0-4
- Added configure options for filter directory and proxy directory, since
  they are also founded in the same directory as the kerberos ticket directory
- added proxydb directory to install

* Thu Mar 29 2012 Kelly L. Stam <kstam@umich.edu> - 3.2.0-3
- Removed previously included host script since it doesn't make sense to
  include with cosign, since it is more of a website helper.  Put into
  own package httpd-umscripts.
- Moved cron back to cron.hourly after understanding that the moving
  24-hour window should be granular to an hour to be optimal.
- Created _crondir var at the top and replaced references to it since
  this is a recurring location in the spec file.

* Fri Mar 23 2012 Kelly L. Stam <kstam@umich.edu> - 3.2.0-2
- Renamed to be httpd-cosign which makes far more sense since all apache
  modular RPMs are named after the primary after this manner.
- Updated to fix apache2 references as some were parameterized and some
  were hardcoded.
- Removed certificate and placed in its own package.
- Updated cosign configuration to include typical WebHosting parameters.
- Updated cron job to use more common linux find syntax, keep more than
  one day's worth of filter files, moved to cron.daily, and changed name
  to httpd-cosign to differentiate if/when cosign server RPM is built
  so it can live aside mod_cosign, since server would deploy both.
- Removed -fPIC x86_64 special mod since latest source make already includes
  that as part of the build process.
- Added a "Requires:" directive due to apache modules typically being
  very specific to the apache version they were compiled against.
- Added a conf.d cosign conf to include the LoadModule statement for cosign
- added /var/www/cgi-bin/logout and host scripts, based on cosign and
  WebHosting scripts of the same name.

* Mon Mar 19 2012 Mark Montague <markmont@umich.edu> - 3.2.0-1
- Updated to cosign 3.2.0
- Added UMWebCA certificate so cosign can verify the cert used by the U-M
  central weblogin servers.  This should not, strictly speaking, be in this
  RPM since it makes the RPM UM-specific:  the package should either be renamed
  to be "UM-mod_cosign-apache2" or the cert should be broken out into another
  package.  However, I want to keep things simple, it's unlikely that this
  RPM would be distributed outside U-M, and the previous solution (making this
  RPM depend on a U-M specific certificate RPM) was more complicated and did
  not avoid the problem.

* Tue Nov 8 2011 Mark Montague <markmont@umich.edu> - 3.1.2-2
- Fixed path in cronjob for RHEL5 systems.

* Mon Nov 7 2011 Mark Montague <markmont@umich.edu> - 3.1.2-1
- Updated to cosign 3.1.2
- Added RHEL 6 support
- Removed RHEL 4 support
- Removed Apache HTTP Server 1.3.x support
- Removed requirement for UM_cosign_certs package: cosign should almost
  always use the same certificate chain that the web server uses for HTTPS.
- Added cron job to delete old session and ticket files after 24 hours.
  Too many admins don't realize that cosign will never remove session files
  itself, old files build up, accesses to /var/cosign/filter slow down,
  and sometimes the filesystem runs out of inodes.
- Merged mod_cosign-apache2-selinux package into the mod_cosign-apache2
  package: all webservers should have SELinux installed, so there is no
  longer any sense of having a separate package just to set file contexts.
- Renamed package from "cosign" to "mod_cosign-apache2" and eliminated
  the "mod_cosign-apache2" sub-package so that the debuginfo package gets
  created with the right name.  This is possible because we no longer have
  the mod_cosign-apache1 and mod_cosign-apache1-selinux subpackages.

* Thu Apr 16 2009 Jeremy Hallum <jhallum@umich.edu> - 3.0.0-7
- Selinux out of beta

* Tue Apr 14 2009 Jeremy Hallum <jhallum@umich.edu> - 3.0.0-6
- added a context change for the /var/cosign/filter dir

* Tue Apr 14 2009 Jeremy Hallum <jhallum@umich.edu> - 3.0.0-5
- Added a dependency for the UM issued cosign certificates package, that way people don't have to do it by hand

* Mon Apr 13 2009 Jeremy Hallum <jhallum@umich.edu> - 3.0.0-4
- CAcerts don't come with the source anymore

* Mon Apr 13 2009 Jeremy Hallum <jhallum@umich.edu> - 3.0.0-2
- new version.  No need for the libsnet packages, as they are now statically linked inside the app.
- also repackaged to make it easier for mock to handle.
* Wed Aug 15 2007 Roy Bonser <rbonser@umich.edu> 2.0.2a-3
- Fix for el5, apr-config command name changed to apr-1-config. grrr!
* Fri Aug 10 2007 Roy Bonser <rbonser@umich.edu> 2.0.2a-2
- tweaked to build on apache2
* Fri Aug 10 2007 Roy Bonser <rbonser@umich.edu> 2.0.2a-1
- new release (2.0.2a)
- switched back to using provided libsnet libs due to an incompatibility
* Tue Jul 11 2006 Roy Bonser <rbonser@umich.edu> 2.0.1-1
- new upstream version (2.0.1)
- libsnet is now a seperate package. Removed dependance on internal version.
* Fri Jun 30 2006 Roy Bonser <rbonser@umich.edu> 2.0.0-1
- Initial release (2.0.0)
