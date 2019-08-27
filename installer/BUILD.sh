#!/bin/bash
# ../installer/BUILD.sh
#
# Copyright 2018, 2019 Giorgi Tavkelishvili
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Last updated 2019-01-04 by Giorgi T.

set -e
set -o pipefail
if ${VERBOSE:-true}; then
  set -x
fi
set -u

myWorkDir="$PWD"
myName=$(basename "$0")
myFullName=$(readlink -f "$0") # canonicalized path
myBinDir=$(dirname "$myFullName") # canonicalized path

export SCRIPTDIR=${myBinDir}
source ${SCRIPTDIR}/common/installer.include

export PACKAGE=gearge-luks-user-passphrase-change
source ${SCRIPTDIR}/common/${PACKAGE}/${PACKAGE}.info
export  MAJOR MINOR VERSION \
        PROGNAME INSTALLDIR PROGPATH \
        MENUNAME MENUGENERICNAME \
        SHORTDESC FULLDESC \
        MAINTNAME MAINTMAIL \
        PRODUCTURL PRODUCTLICENSE PRODUCTCOPYRIGHT \
        COMPANYFULLNAME
export PACKAGERELEASE=$(get_version_info ${VERSION})
export VERSIONFULL=${VERSION}-${PACKAGERELEASE}
export DATERPMDEV=$(date +'%a %b %d %Y') # for RHEL/Fedora %changelog section
# Note: To get the changelog entry in the required format,
# you can use the rpmdev-bumpspec utility.
# https://docs.fedoraproject.org/en-US/Fedora_Draft_Documentation/0.1/html/
# Packagers_Guide/sect-Packagers_Guide-Creating_a_Basic_Spec_File.html
export DATERFC5322=$(date -R) # for Debian/Ubuntu changelog file
# Note: command dch (debchange) may be used to edit changelog.
# It will update the date automatically.
# http://packaging.ubuntu.com/html/debian-dir-overview.html

# --- prep ---------------------------------------------------------------------

export TMPFILEDIR=$(python -c 'import sys; import tempfile; \
print tempfile.mkdtemp(prefix=sys.argv[1]+".", dir="/var/tmp")' ${PACKAGE})

install -m 0755 -d \
  ${TMPFILEDIR}/etc/xdg/autostart \
  ${TMPFILEDIR}/usr/share/applications \
  ${TMPFILEDIR}${INSTALLDIR}

~/.local/bin/j2 \
  -o ${TMPFILEDIR}${INSTALLDIR}/common.include \
  ${SCRIPTDIR}/../${PACKAGE}/common.include.j2
boolAutostart=true ~/.local/bin/j2 \
  -o ${TMPFILEDIR}/etc/xdg/autostart/${PACKAGE}-autostart.desktop \
  ${SCRIPTDIR}/common/${PACKAGE}.desktop.j2
boolAutostart=false ~/.local/bin/j2 \
  -o ${TMPFILEDIR}/usr/share/applications/${PACKAGE}.desktop \
  ${SCRIPTDIR}/common/${PACKAGE}.desktop.j2

cp ${SCRIPTDIR}/../${PACKAGE}/as-* ${TMPFILEDIR}${INSTALLDIR}/
cp ${SCRIPTDIR}/../${PACKAGE}/get-* ${TMPFILEDIR}${INSTALLDIR}/
cp ${SCRIPTDIR}/../${PACKAGE}/*.py ${TMPFILEDIR}${INSTALLDIR}/
cp ${SCRIPTDIR}/../${PACKAGE}/*.png ${TMPFILEDIR}${INSTALLDIR}/

# --- rpm ----------------------------------------------------------------------

export targetPackage=rpm
export ARCHITECTURE=noarch

install -m 0755 -d ${TMPFILEDIR}/${targetPackage}

BUILDDIR=${SCRIPTDIR}/../../build/rpmbuild
mkdir -p ${BUILDDIR}/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
mkdir -p ${BUILDDIR}/RPMS/${ARCHITECTURE}

test -e ${BUILDDIR}/SPECS/${PACKAGE}.spec && \
  rm -f ${BUILDDIR}/SPECS/${PACKAGE}.spec
sed '/^---$/d' ${SCRIPTDIR}/rpm/DEPENDS.yml | \
  ~/.local/bin/j2 --format=yaml --import-env= \
  -o ${BUILDDIR}/SPECS/${PACKAGE}.spec \
  ${SCRIPTDIR}/rpm/${PACKAGE}.spec.j2

pushd ${BUILDDIR}/SPECS
rpmbuild --target ${ARCHITECTURE} -bb ${PACKAGE}.spec
popd

# --- debian -------------------------------------------------------------------

export targetPackage=debian
export ARCHITECTURE=all
export DISTRIBUTION=bionic # or UNRELEASED?

install -m 0755 -d ${TMPFILEDIR}/${targetPackage}

BUILDDIR=${SCRIPTDIR}/../../build/debbuild
mkdir -p ${BUILDDIR}/{BUILD,BUILDROOT,DEBS,SOURCES}
mkdir -p ${BUILDDIR}/DEBS/${ARCHITECTURE}

STAGEDIR=${BUILDDIR}/BUILDROOT/${PACKAGE}-${VERSIONFULL}.${ARCHITECTURE}
test -e ${STAGEDIR} && rm -Rf ${STAGEDIR}
mkdir ${STAGEDIR}

# Setup the installation directory hierachy in the package staging area.
# prep_staging_debian() {}
install -m 0755 -d ${STAGEDIR}/DEBIAN

~/.local/bin/j2 \
  -o ${TMPFILEDIR}/${targetPackage}/prep.include \
  ${SCRIPTDIR}/common/prep.j2
source ${TMPFILEDIR}/${targetPackage}/prep.include

# Put the package contents in the staging area.
# stage_install_debian() {}
for filename in preinst postinst prerm postrm; do
  ~/.local/bin/j2 \
    -o ${STAGEDIR}/DEBIAN/${filename} \
    ${SCRIPTDIR}/common/${filename}.j2
done
chmod 0555 ${STAGEDIR}/DEBIAN/{preinst,postinst,prerm,postrm}

~/.local/bin/j2 \
  -o ${STAGEDIR}/DEBIAN/copyright \
  ${SCRIPTDIR}/debian/copyright.j2
chmod 0555 ${STAGEDIR}/DEBIAN/copyright

# Create the Debian control file needed by dpkg-deb.
# gen_control() {}
sed '/^---$/d' ${SCRIPTDIR}/debian/DEPENDS.yml | \
  ~/.local/bin/j2 --format=yaml --import-env= \
  -o ${STAGEDIR}/DEBIAN/control \
  ${SCRIPTDIR}/debian/control.j2
chmod 0644 ${STAGEDIR}/DEBIAN/control

pushd ${STAGEDIR}/..
dpkg-deb --build $(basename ${STAGEDIR})
mv $(basename ${STAGEDIR}).* ${BUILDDIR}/DEBS/${ARCHITECTURE}/
popd

rm -Rf ${STAGEDIR} ${TMPFILEDIR}

save_version_info
