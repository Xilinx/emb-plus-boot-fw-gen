#!/bin/sh
set -e

# Copyright (c) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
#
# SPDX-License-Identifier: MIT

usage() {
    echo "Package APU image into a .deb"
    echo ""
    echo "$(basename "${0}") [OPTION] .."
    echo ""
    echo "Options: "
    echo " -a <apu_file.xsabin>     package a single file"
    echo " -d <dir>/                package all files in dir"
    echo " -v <package_version>"
    echo " -m <package_maintainer>"
    echo " -n <package_name>        Default: xrt-apu"
}

error() {
    echo "ERROR: ${1}" 1>&2
    exit 1
}

if [ "$#" -eq 0 ]; then
    usage
    exit 1
fi

while getopts a:d:v:m:n:h opt; do
    case $opt in 
        (a) APUFILE=$OPTARG ;;
        (d) APUDIR=$OPTARG ;;
        (v) PKGVER=$OPTARG ;;
        (m) MAINTAINER=$OPTARG ;;
        (n) PKGNAME=$OPTARG ;;
        (h) usage
            exit 0 ;;
        (*) usage
            exit 1 ;;
    esac
done

if [ -z "$APUFILE" ] && [ -z "$APUDIR" ]; then
    error "Please provide an APU file (-a) or directory (-d) to packge"
elif [ -n "$APUFILE" ] && [ -n "$APUDIR" ]; then
    error "Please provide either -a <apufile.xsabin> or -d <apu_dir/>"
fi

[ -z "$PKGVER" ] && PKGVER="1.0"
[ -z "$MAINTAINER" ] && MAINTAINER="Unknown"
[ -z "$PKGNAME" ] && PKGNAME="xrt-apu"

BUILDDIR=${PKGNAME}_${PKGVER}
echo "${BUILDDIR}.deb"

[ -f "${BUILDDIR}.deb" ] && error "Output file already exists: ${BUILDDIR}.deb"
[ -d "$BUILDDIR" ] && error "Build dir already exists: $BUILDDIR"

mkdir -p "$BUILDDIR/DEBIAN"

cat <<EOF > "$BUILDDIR/DEBIAN/control"
Package: $PKGNAME
Architecture: all
Version: $PKGVER
Priority: optional
Description: AMD Versal firmware
Maintainer: $MAINTAINER
EOF

mkdir -p "$BUILDDIR/lib/firmware/xilinx/"

if [ -n "$APUFILE" ]; then
    [ "${APUFILE##*.}" != "xsabin" ] && error "$APUFILE does not have .xsabin extension"
    cp "$APUFILE" "$BUILDDIR/lib/firmware/xilinx/"
elif [ -n "$APUDIR" ]; then
    [ -d "$APUDIR" ] || error "$APUDIR is not a valid directory"
    cp -r "$APUDIR/" "$BUILDDIR/lib/firmware/xilinx/"
fi

command -v dpkg-deb >&2 || error "dpkg-deb not found"
dpkg-deb --build "$BUILDDIR"

rm -rf "$BUILDDIR"
