#!/bin/sh
set -e

# Copyright (c) 2023 - 2024 Advanced Micro Devices, Inc. All Rights Reserved.
#
# SPDX-License-Identifier: MIT

usage() {
	echo "Package APU/OSPI image into a .deb"
	echo ""
	echo "$(basename "${0}") [OPTION] .."
	echo ""
	echo "Options: "
	echo " -a <apu_file.xsabin>         package a single file"
	echo " -d <apu_dir>/                package all files in apu dir"
	echo " -e <boot_file.xsabin>        package a single file"
	echo " -f <boot_dir>/               package all files in ospi dir"
	echo " -g <partition metadata file> used for extracting uuid"
	echo " -v <package_version>"
	echo " -m <package_maintainer>"
	echo " -n <package_name>"
}

error() {
	echo "ERROR: ${1}" 1>&2
	exit 1
}

if [ "$#" -eq 0 ]; then
	usage
	exit 1
fi

while getopts a:d:e:f:g:v:m:n:h opt; do
	case $opt in
	a) APUFILE=$OPTARG ;;
	d) APUDIR=$OPTARG ;;
	e) BOOTFILE=$OPTARG ;;
	f) BOOTDIR=$OPTARG ;;
	g) PARTMETA=$OPTARG ;;
	v) PKGVER=$OPTARG ;;
	m) MAINTAINER=$OPTARG ;;
	n) PKGNAME=$OPTARG ;;
	h)
		usage
		exit 0
		;;
	*)
		usage
		exit 1
		;;
	esac
done

echo "Packaging into deb file started..."

if [ -z "$APUFILE" ] && [ -z "$APUDIR" ] && [ -z "$BOOTFILE" ] && [ -z "$BOOTDIR" ]; then
	error "Please provide an APU file (-a) or APU directory (-d) or BOOT file (-e) or BOOT directory to packge"
elif [ -n "$APUFILE" ] && [ -n "$APUDIR" ] && [ -n "$BOOTFILE" ] && [ -n "$BOOTDIR" ]; then
	error "Please provide either -a <apu_file.xsabin> or -d <apu_dir/> or -e <boot_file.xsabin> or -f <boot_dir/>"
fi

if [ -z "$APUFILE" ] && [ -z "$APUDIR" ]; then
	#Check if partition metadata file provided
	if [ -z "$PARTMETA" ]; then
		error "Please provide partition metadata file"
	fi
	command -v jq >&2 || error "jq not found"
	EXTRACTUUID=$(jq ".partition_metadata.logic_uuid" "$PARTMETA")
	UUID=$(echo "$EXTRACTUUID" | tr -d '"')
	[ -z "$PKGVER" ] && PKGVER="1.0" && echo "Using default PKGVER: $PKGVER"
	[ -z "$MAINTAINER" ] && MAINTAINER="Unknown" && echo "Using default MAINTAINER: $MAINTAINER"
	[ -z "$PKGNAME" ] && PKGNAME="xrt-boot" && echo "Using default PKGNAME: $PKGNAME"
elif [ -z "$BOOTFILE" ] && [ -z "$BOOTDIR" ]; then
	[ -z "$PKGVER" ] && PKGVER="1.0" && echo "Using default PKGVER: $PKGVER"
	[ -z "$MAINTAINER" ] && MAINTAINER="Unknown" && echo "Using default MAINTAINER: $MAINTAINER"
	[ -z "$PKGNAME" ] && PKGNAME="xrt-apu" && echo "Using default PKGNAME: $PKGNAME"
fi

BUILDDIR=${PKGNAME}_${PKGVER}
echo "${BUILDDIR}.deb"

[ -f "${BUILDDIR}.deb" ] && error "Output file already exists: ${BUILDDIR}.deb"
[ -d "$BUILDDIR" ] && error "Build dir already exists: $BUILDDIR"

mkdir -p "$BUILDDIR/DEBIAN"

cat <<EOF >"$BUILDDIR/DEBIAN/control"
Package: $PKGNAME
Architecture: all
Version: $PKGVER
Priority: optional
Description: AMD Versal firmware
Maintainer: $MAINTAINER
EOF

if [ -z "$APUFILE" ] && [ -z "$APUDIR" ]; then
	mkdir -p "$BUILDDIR/lib/firmware/xilinx/$UUID"
elif [ -z "$BOOTFILE" ] && [ -z "$BOOTDIR" ]; then
	mkdir -p "$BUILDDIR/lib/firmware/xilinx/"
fi

if [ -n "$APUFILE" ]; then
	[ "${APUFILE##*.}" != "xsabin" ] && error "$APUFILE does not have .xsabin extension"
	cp "$APUFILE" "$BUILDDIR/lib/firmware/xilinx/"
elif [ -n "$APUDIR" ]; then
	[ -d "$APUDIR" ] || error "$APUDIR is not a valid directory"
	cp -r "$APUDIR/" "$BUILDDIR/lib/firmware/xilinx/"
elif [ -n "$BOOTFILE" ]; then
	[ "${BOOTFILE##*.}" != "xsabin" ] && error "$BOOTFILE does not have .xsabin extension"
	cp "$BOOTFILE" "$BUILDDIR/lib/firmware/xilinx/$UUID"
elif [ -n "$BOOTDIR" ]; then
	[ -d "$BOOTDIR" ] || error "$BOOTDIR is not a valid directory"
	cp -r "$BOOTDIR/" "$BUILDDIR/lib/firmware/xilinx/$UUID"
fi

command -v dpkg-deb >&2 || error "dpkg-deb not found"
dpkg-deb --build "$BUILDDIR"

rm -rf "$BUILDDIR"
