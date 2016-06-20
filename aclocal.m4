AC_DEFUN([CHECK_SSL],
[
    AC_MSG_CHECKING(for ssl)
    ssldirs="/usr/local/openssl /usr/lib/openssl /usr/openssl \
        /usr/local/ssl /usr/lib/ssl /usr/ssl \
        /usr/pkg /usr/local /usr"
    AC_ARG_WITH(ssl,
        AC_HELP_STRING([--with-ssl=DIR], [path to ssl]),
        ssldirs="$withval")
    AC_CACHE_VAL(ac_cv_path_ssl,[
        for ssldir in $ssldirs; do
            if test -f "$ssldir/include/openssl/ssl.h"; then
                ac_cv_path_ssl=$ssldir;
                break;
            fi
            if test -f "$ssldir/include/ssl.h"; then
                ac_cv_path_ssl=$ssldir;
                break
            fi
        done
    ])
    if test ! -e "$ac_cv_path_ssl" ; then
        AC_MSG_ERROR(cannot find ssl libraries)
    fi
    case "X$host_os" in 
    Xaix*)
	ADDLIBS="-lssl -lcrypto";
	AC_SUBST(ADDLIBS)
	ADDLDFLAGS="-L$ac_cv_path_ssl/lib";
	AC_SUBST(ADDLDFLAGS)
    ;;
    esac

    CPPFLAGS="$CPPFLAGS -I$ac_cv_path_ssl/include";
    AC_DEFINE(HAVE_LIBSSL)
    LIBS="$LIBS -lssl -lcrypto";
    LDFLAGS="$LDFLAGS -L$ac_cv_path_ssl/lib";
    AC_MSG_RESULT($ac_cv_path_ssl)
])

AC_DEFUN([CHECK_LIBKRB],
[
    AC_MSG_CHECKING(for krb)

    if test -d $enableval; then
	echo "using krb as '$enableval'";
	if test -f "$enableval/include/krb5.h"; then
	    ac_cv_path_krb=$enableval
	    krb_include="$enableval/include"
	elif test -f "$enableval/include/kerberosV/krb5.h"; then
	    # handle NetBSD's krb5 pathing
	    ac_cv_path_krb=$enableval
	    krb_include="$enableval/include/kerberosV"
	fi
    else
	krbdirs="/usr/local/kerberos /usr/lib/kerberos /usr/kerberos \
		/usr/local/krb5 /usr/lib/krb /usr/krb \
		/usr/pkg /usr/local /usr"
	AC_CACHE_VAL(ac_cv_path_krb,[
	    for krbdir in $krbdirs; do
		if test -f "$krbdir/include/krb5.h"; then
		    ac_cv_path_krb=$krbdir
		    krb_include="$krbdir/include"
		    break;
		elif test -f "$krbd/include/kerberosV/krb5.h"; then
		    ac_cv_path_krb=$krbdir
		    krb_include="$krbdir/include/kerberosV"
		    break;
		fi
	    done
	])
    fi
    if test ! -e "$ac_cv_path_krb" ; then
        AC_MSG_ERROR(cannot find krb libraries)
    fi
    KRBCGI="cosign.cgi"
    AC_SUBST(KRBCGI)
    KINC="-I$krb_include";
    AC_SUBST(KINC)
    KLIBS="-lkrb5 -lk5crypto -lcom_err";
    AC_SUBST(KLIBS)
    KLDFLAGS="-L$ac_cv_path_krb/lib";
    AC_SUBST(KLDFLAGS)
    AC_DEFINE(KRB)
    AC_MSG_RESULT(Kerberos found at $ac_cv_path_krb)
])

AC_DEFUN([CHECK_APACHE2],
[
    AC_MSG_CHECKING(for apache 2)
 
    if test -f "$enableval"; then
	echo "using apxs2 as '$enableval'"
	ac_cv_path_apxs2="$enableval"
    fi

    APXS2="$ac_cv_path_apxs2"

    if test ! -e "$ac_cv_path_apxs2" ; then
        AC_MSG_ERROR(cannot find apache 2)
    fi

    FILTERS="$FILTERS filters/apache2"
    APXS2_TARGET="`$APXS2 -q TARGET`"
    APXS2_SBINDIR="`$APXS2 -q SBINDIR`"
    if test x_$APXS2_TARGET = x_httpd ; then
	APACHECTL2="${APXS2_SBINDIR}/apachectl"
    else
	APACHECTL2="${APXS2_SBINDIR}/${APXS2_TARGET}ctl"
    fi
    APXS2_INCLUDEDIR="`${APXS2} -q INCLUDEDIR`"
    if test -f "$APXS2_INCLUDEDIR/ap_regex.h"; then
	AC_DEFINE(HAVE_AP_REGEX_H)
    fi
    APACHE2_MINOR_VERSION="`${APXS2_SBINDIR}/${APXS2_TARGET} -v | \
	    sed -e '/^Server version:/!d' \
	        -e 's/.*Apache\/2\.\(@<:@0-9@:>@\)\..*/\1/g'`"
    if test -n "${APACHE2_MINOR_VERSION}"; then
	if test "${APACHE2_MINOR_VERSION}" -gt 0; then
	    AC_DEFINE(HAVE_MOD_AUTHZ_HOST)
	    if test "${APACHE2_MINOR_VERSION}" -gt 2; then
		AC_DEFINE(HAVE_APACHE_CONN_CLIENT_IP)
	    fi
	fi
    fi
    AC_SUBST(APXS2)
    AC_SUBST(APACHECTL2)
    AC_DEFINE(APACHE2)
    AC_MSG_RESULT(apache 2 filter will be built)

])

AC_DEFUN([CHECK_GSS],
[
    AC_MSG_CHECKING(for gss)
    if test ! -e "$ac_cv_path_krb" ; then
        AC_MSG_ERROR(gss require krb5 libraries)
    fi
    GSSINC="-I$ac_cv_path_krb/include";
    AC_SUBST(GSSINC)
    GSSLIBS="-lgssapi_krb5 -lkrb5 -lk5crypto -lcom_err";
    AC_SUBST(GSSLIBS)
    GSSLDFLAGS="-L$ac_cv_path_krb/lib";
    AC_SUBST(GSSLDFLAGS)
    AC_DEFINE(GSS)
    AC_MSG_RESULT($ac_cv_path_krb)
])

AC_DEFUN([CHECK_APACHE_1],
[

    AC_MSG_CHECKING([for apache 1.3])

    if test -f "$enableval"; then
        echo "using apxs as '$enableval'"
        ac_cv_path_apxs="$enableval"
    fi

    APXS="$ac_cv_path_apxs"

    if test ! -e "$ac_cv_path_apxs" ; then
        AC_MSG_ERROR(cannot find apache 1.3)
    fi

    FILTERS="$FILTERS filters/apache"
    APXS_TARGET="`$APXS -q TARGET`"
    if test x_$APXS_TARGET = x_httpd ; then
	APACHECTL="${APXS_SBINDIR}/apachectl"
    else
	APACHECTL="${APXS_SBINDIR}/${APXS_TARGET}ctl"
    fi
    AC_SUBST(APXS)
    AC_SUBST(APACHECTL)
    AC_DEFINE(APACHE1)
    AC_MSG_RESULT(apache 1.3 filter will be built)

])

AC_DEFUN([CHECK_LIBMYSQL],
[
    AC_MSG_CHECKING(for mysql)

    if test -d "$enableval"; then
	if test -f "$enableval/include/mysql/mysql.h"; then
	    ac_cv_path_mysql=$enableval
	fi
    else
	mysqldirs="/usr /usr/local/mysql /usr/lib/mysql /usr/mysql \
		/usr/pkg /usr/local /usr"
	AC_CACHE_VAL(ac_cv_path_mysql,[
	    for mysqldir in $mysqldirs; do
		if test -f "$mysqldir/include/mysql/mysql.h"; then
		    ac_cv_path_mysql=$mysqldir
		    break;
		fi
	    done
	])
	if test ! -e "$ac_cv_path_mysql" ; then
	    AC_MSG_ERROR(cannot find mysql libraries)
	fi
    fi
    MYSQLINC="-I$ac_cv_path_mysql/include/mysql";
    AC_SUBST(MYSQLINC)
    MYSQLLIBS="-lmysqlclient";
    AC_SUBST(MYSQLLIBS)
    MYSQLLDFLAGS="-L$ac_cv_path_mysql/lib/mysql -R$ac_cv_path_mysql/lib/mysql";
    AC_SUBST(MYSQLLDFLAGS)
    AC_DEFINE(HAVE_MYSQL)
    AC_DEFINE(SQL_FRIEND)
    AC_MSG_RESULT($ac_cv_path_mysql)
])

AC_DEFUN([CHECK_LIBPAM],
[
    AS_IF([test x"$enableval" = x"no"], [AC_MSG_RESULT( pam not enabled)])

    AS_IF([test x"$enableval" = x"yes"], [
	AC_SEARCH_LIBS([pam_start], [pam],
	    [
		AC_DEFINE(HAVE_LIBPAM)
		AC_CHECK_HEADERS([pam/pam_appl.h security/pam_appl.h],
		    [
			pam_headers_found="yes"; break;
		    ])
	    ],
	    [
		AC_MSG_ERROR(cannot find pam library)
	    ])

	AS_IF([test x"$pam_headers_found" != x"yes"],
		[AC_MSG_ERROR(cannot find pam headers)])
    ])
])

AC_DEFUN([SET_NO_SASL],
[
    ac_configure_args="$ac_configure_args --with-sasl=no";
    AC_MSG_RESULT(Disabled SASL)
])

AC_DEFUN([SET_NO_ZLIB],
[
    ac_configure_args="$ac_configure_args --with-zlib=no";
    AC_MSG_RESULT(Disabled ZLIB)
])

AC_DEFUN([SET_ENABLE_SHARED],
[
    ac_configure_args="$ac_configure_args --enable-shared";
    AC_MSG_RESULT(Enabled Shared)
])

AC_DEFUN([CHECK_UNIVERSAL_BINARIES],
[
    AC_ARG_ENABLE(universal_binaries,
        AC_HELP_STRING([--enable-universal-binaries], [build universal binaries (default=no)]),
        ,[enable_universal_binaries=no])
    if test "${enable_universal_binaries}" = "yes"; then
        case "${host_os}" in
	  darwin8*)
            macosx_sdk="MacOSX10.4u.sdk"
            ;;

          darwin9*)
            dep_target="-mmacosx-version-min=10.4"
            macosx_sdk="MacOSX10.5.sdk"
	    ;;

          *)
            AC_MSG_ERROR([Building universal binaries on ${host_os} is not suppo
rted])
            ;;
        esac

        echo ===========================================================
        echo Setting up universal binaries for ${host_os}
        echo ===========================================================
	FILTER_LINKER_OPTS="-Wl,\"-isysroot /Developer/SDKs/$macosx_sdk\" -Wl,\"-arch i386\" -Wl,\"-arch x86_64\" -Wl,\"-arch ppc\" -Wl,\"-arch ppc64\" -Wl,\"$dep_target\""
	FILTER_COMPILER_OPTS="-Wc,\"-isysroot /Developer/SDKs/$macosx_sdk\" -Wc,\"-arch i386\" -Wc,\"-arch x86_64\" -Wc,\"-arch ppc\" -Wc,\"-arch ppc64\" -Wc,\"$dep_target\""
	UNIVERSAL_OPTOPTS="-isysroot /Developer/SDKs/$macosx_sdk -arch i386 -arch x86_64 -arch ppc -arch ppc64 $dep_target"
    fi
])

AC_DEFUN([MACOSX_MUTE_DEPRECATION_WARNINGS],
[
    dnl Lion deprecates a system-provided OpenSSL. Build output
    dnl is cluttered with useless deprecation warnings.

    AS_IF([test x"$CC" = x"gcc"], [
	case "${host_os}" in
	darwin11*)
	    AC_MSG_NOTICE([muting deprecation warnings from compiler])
	    OPTOPTS="$OPTOPTS -Wno-deprecated-declarations"
	    ;;

	*)
	    ;;
	esac
    ])
])

AC_DEFUN([CHECK_LIGHTTPD],
[
    AC_MSG_CHECKING(for lighttpd)
 
    if test -d "$enableval"; then
        echo "$enableval"
        ac_cv_path_lighttpd="$enableval"
    fi

    if test ! -e "$ac_cv_path_lighttpd"; then
	AC_MSG_ERROR(cannot find lighttpd)
    fi

    lighttpdincdirs="include src"
    for incdir in $lighttpdincdirs; do
	if test -e "$ac_cv_path_lighttpd/$incdir/base.h"; then
	    LIGHTTPDINC="-I$ac_cv_path_lighttpd/$incdir"
	    break
	fi
    done

    if test -z "$LIGHTTPDINC"; then
	AC_MSG_ERROR(cannot find lighttpd)
    fi
	
    LIGHTTPD_COSIGN_SRCDIR=`pwd`

    AC_SUBST(LIGHTTPD_COSIGN_SRCDIR)
    AC_DEFINE(HAVE_LIGHTTPD)
    FILTERS="$FILTERS filters/lighttpd"
    AC_MSG_RESULT(lighttpd filter will be built)
])

dnl Much of the pthreads detection comes from the Heimdal autoconf, which 
dnl does a great job ferreting out the native vs. non-native pthreads 
dnl implementations.

AC_DEFUN([CHECK_PTHREADS], [
AC_MSG_CHECKING(for pthreads support)

AC_ARG_ENABLE(pthread-support,
	AS_HELP_STRING([--enable-pthreads],
			[if you want EXPERIMENTAL thread safe libraries]),
	[],[enable_pthread_support=maybe])

case "$host" in 
*-*-solaris2*)
	native_pthread_support=yes
	if test "$GCC" = yes; then
		PTHREADS_CFLAGS=-pthreads
		PTHREADS_LIBS=-pthreads
	else
		PTHREADS_CFLAGS=-mt
		PTHREADS_LIBS=-mt
	fi
	;;
*-*-netbsd[12]*)
	native_pthread_support="if running netbsd 1.6T or newer"
	dnl heim_threads.h knows this
	PTHREADS_LIBS="-lpthread"
	;;
*-*-netbsd[3456789]*)
	native_pthread_support="netbsd 3 uses explict pthread"
	dnl heim_threads.h knows this
	PTHREADS_LIBS="-lpthread"
	;;
*-*-freebsd5*)
	native_pthread_support=yes
	;;
*-*-openbsd*)
	native_pthread_support=yes
	PTHREADS_CFLAGS=-pthread
	PTHREADS_LIBS=-pthread
	;;
*-*-linux* | *-*-linux-gnu)
	case `uname -r` in
	2.*)
		native_pthread_support=yes
		PTHREADS_CFLAGS=-pthread
		PTHREADS_LIBS=-pthread
		;;
	esac
	;;
*-*-kfreebsd*-gnu*)
	native_pthread_support=yes
	PTHREADS_CFLAGS=-pthread
	PTHREADS_LIBS=-pthread
	;;
*-*-aix*)
	dnl AIX is disabled since we don't handle the utmp/utmpx
        dnl problems that aix causes when compiling with pthread support
	native_pthread_support=no
	;;
mips-sgi-irix6.[[5-9]])  # maybe works for earlier versions too
	native_pthread_support=yes
	PTHREADS_LIBS="-lpthread"
	;;
*-*-darwin*)
	native_pthread_support=yes
	;;
*)
	native_pthread_support=no
	;;
esac

if test "$enable_pthread_support" = maybe ; then
	enable_pthread_support="$native_pthread_support"
fi
	
if test "$enable_pthread_support" != no; then
    AC_DEFINE(ENABLE_PTHREAD_SUPPORT, 1,
	[Define if you want have a thread safe libraries])
    dnl This sucks, but libtool doesn't save the depenecy on -pthread
    dnl for libraries.
    LIBS="$PTHREADS_LIBS $LIBS"
else
  PTHREADS_CFLAGS=""
  PTHREADS_LIBS=""
fi

AC_SUBST(PTHREADS_CFLAGS)
AC_SUBST(PTHREADS_LIBS)

AC_MSG_RESULT($enable_pthread_support)
])
