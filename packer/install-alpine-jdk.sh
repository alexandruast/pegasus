#!/bin/sh
set -ex
JAVA_VERSION_MAJOR=`echo ${1} | cut -d'.' -f1`
JAVA_VERSION_MINOR=`echo ${1} | cut -d'.' -f2`
JAVA_VERSION_BUILD=`echo ${1} | cut -d'.' -f3`
ASSETS_DEST=${2}
JAVA_HOME=${3}
JAVA_PACKAGE=jdk
GLIBC_VERSION="2.23-r3"
LANG=C.UTF-8

echo "Received arguments: ${*}"
if [ "${#}" -ne 3 ]; then echo "Missing arguments!"; exit 1; fi

echo "This will install Oracle ${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}"
echo "This will install glibc version ${GLIBC_VERSION}"

apk upgrade --update
apk add --update libstdc++ curl ca-certificates bash unzip

for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do
  curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o ${ASSETS_DEST}/${pkg}.apk
done

apk add --allow-untrusted ${ASSETS_DEST}/*.apk
rm -v ${ASSETS_DEST}/*.apk
( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true )
echo "export LANG=C.UTF-8" > /etc/profile.d/locale
/usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib
mkdir /opt

if ! ls  ${ASSETS_DEST}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz 1> /dev/null 2>&1; then
  curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" \
    -o ${ASSETS_DEST}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
    http://download.oracle.com/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz
fi

gunzip ${ASSETS_DEST}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz
tar -C /opt -xf ${ASSETS_DEST}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar
ln -s ${JAVA_HOME}1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} ${JAVA_HOME}

sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ $JAVA_HOME/jre/lib/security/java.security
apk del curl glibc-i18n
rm -rf ${JAVA_HOME}/*src.zip \
       ${JAVA_HOME}/lib/missioncontrol \
       ${JAVA_HOME}/lib/visualvm \
       ${JAVA_HOME}/lib/*javafx* \
       ${JAVA_HOME}/jre/plugin \
       ${JAVA_HOME}/jre/bin/javaws \
       ${JAVA_HOME}/jre/bin/jjs \
       ${JAVA_HOME}/jre/bin/orbd \
       ${JAVA_HOME}/jre/bin/pack200 \
       ${JAVA_HOME}/jre/bin/policytool \
       ${JAVA_HOME}/jre/bin/rmid \
       ${JAVA_HOME}/jre/bin/rmiregistry \
       ${JAVA_HOME}/jre/bin/servertool \
       ${JAVA_HOME}/jre/bin/tnameserv \
       ${JAVA_HOME}/jre/bin/unpack200 \
       ${JAVA_HOME}/jre/lib/javaws.jar \
       ${JAVA_HOME}/jre/lib/deploy* \
       ${JAVA_HOME}/jre/lib/desktop \
       ${JAVA_HOME}/jre/lib/*javafx* \
       ${JAVA_HOME}/jre/lib/*jfx* \
       ${JAVA_HOME}/jre/lib/amd64/libdecora_sse.so \
       ${JAVA_HOME}/jre/lib/amd64/libprism_*.so \
       ${JAVA_HOME}/jre/lib/amd64/libfxplugins.so \
       ${JAVA_HOME}/jre/lib/amd64/libglass.so \
       ${JAVA_HOME}/jre/lib/amd64/libgstreamer-lite.so \
       ${JAVA_HOME}/jre/lib/amd64/libjavafx*.so \
       ${JAVA_HOME}/jre/lib/amd64/libjfx*.so \
       ${JAVA_HOME}/jre/lib/ext/jfxrt.jar \
       ${JAVA_HOME}/jre/lib/ext/nashorn.jar \
       ${JAVA_HOME}/jre/lib/oblique-fonts \
       ${JAVA_HOME}/jre/lib/plugin.jar \
       ${ASSETS_DEST:?}/* /var/cache/apk/*
echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf
echo "export PATH=${PATH}:${JAVA_HOME}/bin" >> /etc/profile
echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/profile.d/java
. /etc/profile
java -version
