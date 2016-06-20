m4_include([libtool.m4])

AC_DEFUN([CHECK_SNET],
[
    AC_MSG_CHECKING(for snet)
    snetdir="libsnet"
    AC_ARG_WITH(snet,
	    AC_HELP_STRING([--with-snet=DIR], [path to snet]),
	    snetdir="$withval")
    if test -f "$snetdir/snet.h"; then
	found_snet="yes";
	CPPFLAGS="$CPPFLAGS -I$snetdir";
    fi
    if test x_$found_snet != x_yes; then
	AC_MSG_ERROR(cannot find snet libraries)
    else
	LIBS="$LIBS -lsnet";
	LDFLAGS="$LDFLAGS -L$snetdir";
    fi
    AC_MSG_RESULT(yes)
])

AC_DEFUN([CHECK_SSL],
[
    AC_MSG_CHECKING(for ssl)
    ssldirs="/usr/local/openssl /usr/lib/openssl /usr/openssl \
	    /usr/local/ssl /usr/lib/ssl /usr/ssl \
	    /usr/pkg /usr/local /usr"
    AC_ARG_WITH(ssl,
	    AC_HELP_STRING([--with-ssl=DIR], [path to ssl]),
	    ssldirs="$withval")
    for dir in $ssldirs; do
	ssldir="$dir"
	if test -f "$dir/include/openssl/ssl.h"; then
	    found_ssl="yes";
	    CPPFLAGS="$CPPFLAGS -I$ssldir/include";
	    break;
	fi
	if test -f "$dir/include/ssl.h"; then
	    found_ssl="yes";
	    CPPFLAGS="$CPPFLAGS -I$ssldir/include";
	    break
	fi
    done
    if test x_$found_ssl != x_yes; then
	AC_MSG_ERROR(cannot find ssl libraries)
    else
	AC_DEFINE(HAVE_LIBSSL)
	LIBS="$LIBS -lssl -lcrypto";
	LDFLAGS="$LDFLAGS -L$ssldir/lib";
    fi
    AC_MSG_RESULT(yes)
])

AC_DEFUN([CHECK_ZEROCONF],
[
    AC_MSG_CHECKING(for zeroconf)
    zeroconfdirs="/usr /usr/local"
    AC_ARG_WITH(zeroconf,
	    AC_HELP_STRING([--with-zeroconf=DIR], [path to zeroconf]),
	    zeroconfdirs="$withval")
    for dir in $zeroconfdirs; do
	zcdir="$dir"
	if test -f "$dir/include/DNSServiceDiscovery/DNSServiceDiscovery.h"; then
	    found_zeroconf="yes";
	    CPPFLAGS="$CPPFLAGS -I$zcdir/include";
	    break;
	fi
    done
    if test x_$found_zeroconf != x_yes; then
	AC_MSG_RESULT(no)
    else
	AC_DEFINE(HAVE_ZEROCONF)
	AC_MSG_RESULT(yes)
    fi
])

AC_DEFUN([CHECK_PROFILED],
[
    # Allow user to control whether or not profiled libraries are built
    AC_MSG_CHECKING(whether to build profiled libraries)
    PROFILED=true
    AC_ARG_ENABLE(profiled,
      [  --enable-profiled       build profiled libsnet (default=yes)],
      [test x_$enable_profiled = x_no && PROFILED=false]
    )
    AC_SUBST(PROFILED)
    if test x_$PROFILED = x_true ; then
      AC_MSG_RESULT(yes)
    else
      AC_MSG_RESULT(no)
    fi
])

AC_DEFUN([CHECK_SASL],
[
    AC_MSG_CHECKING(for sasl)
    sasldirs="/usr/local/sasl2 /usr/lib/sasl2 /usr/sasl2 \
            /usr/pkg /usr/local /usr"
    AC_ARG_WITH(sasl,
            AC_HELP_STRING([--with-sasl=DIR], [path to sasl]),
            sasldirs="$withval")
    if test x_$withval != x_no; then
	for dir in $sasldirs; do
	    sasldir="$dir"
	    if test -f "$dir/include/sasl/sasl.h"; then
		found_sasl="yes";
		CPPFLAGS="$CPPFLAGS -I$sasldir/include";
		break;
	    fi
	    if test -f "$dir/include/sasl.h"; then
		found_sasl="yes";
		CPPFLAGS="$CPPFLAGS -I$sasldir/include";
		break
	    fi
	done
	if test x_$found_sasl == x_yes; then
	    AC_DEFINE(HAVE_LIBSASL)
	    LIBS="$LIBS -lsasl2";
	    LDFLAGS="$LDFLAGS -L$sasldir/lib";
	    AC_MSG_RESULT(yes)
	else
	    AC_MSG_RESULT(no)
	fi
    else
	AC_MSG_RESULT(no)
    fi
])

AC_DEFUN([CHECK_UNIVERSAL_BINARIES],
[
    AC_ARG_ENABLE(universal_binaries,
        AC_HELP_STRING([--enable-universal_binaries], [build universal binaries (default=no)]),
        ,[enable_universal_binaries=no])
    if test "${enable_universal_binaries}" = "yes"; then
        AC_CANONICAL_SYSTEM
        case "${host_os}" in
          darwin8*)
            macosx_sdk="MacOSX10.4u.sdk"
            ;;

          darwin9*)
            dep_target="-mmacosx-version-min=10.4"
            macosx_sdk="MacOSX10.5.sdk"
            ;;

          *)
            AC_MSG_ERROR([Building universal binaries on ${host_os} is not supported])
            ;;
          esac
        echo ===========================================================
        echo Setting up universal binaries for ${host_os}
        echo ===========================================================
        OPTOPTS="$OPTOPTS -isysroot /Developer/SDKs/$macosx_sdk -arch i386 -arch x86_64 -arch ppc -arch ppc64 $dep_target"
    fi
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
