#!/bin/sh
set -e

# Copyright (c) 2023 - 2024 Advanced Micro Devices, Inc. All Rights Reserved.
# Author: Sharath Dasari
#
# SPDX-License-Identifier: MIT

usage() {
	echo "Package APU/OSPI image into a .deb"
	echo ""
	echo "$(basename "${0}") [OPTION] .."
	echo ""
	echo "Options: "
	echo " -a <apu.xsabin>                 package apu xsabin file"
	echo " -b <boot.xsabin>                package boot xsabin file"
	echo " -f <partition.json>             passed as addition argument"
	echo " -g <platform.json>              passed as addition argument"
	echo " -i <device_type>"
	echo " -j <package_version>"
	echo " -k <package_maintainer>"
	echo " -l <package_name>"
	echo " -m <optional_tag>"
}

error() {
	echo "ERROR: ${1}" 1>&2
	exit 1
}

if [ "$#" -eq 0 ]; then
	usage
	exit 1
fi

while getopts a:b:f:g:i:j:k:l:m:h opt; do
	case $opt in
	a) APU=$OPTARG ;;
	b) BASE=$OPTARG ;;
	f) PARTITION=$OPTARG ;;
	g) PLATFORM=$OPTARG ;;
	i) DEVTYPE=$OPTARG ;;
	j) PKGVER=$OPTARG ;;
	k) MAINTAINER=$OPTARG ;;
	l) PKGNAME=$OPTARG ;;
	m) OPTAG=$OPTARG ;;
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

#Check at-least one option is passed
if [ -z "$APU" ] && [ -z "$BASE" ]; then
	error "Please provide an APU xsabin (-a) or BASE xsabin (-b) to packge"
fi

#Check the silicon type es1 or prod
if [ "${DEVTYPE}" = "es1" ]; then
	DEVICE="-es1"
else
	DEVICE=""
fi

#Check if optional tag is passed
if [ -n "$OPTAG" ]; then
	TAG="_$OPTAG"
else
	TAG=""
fi

if [ -n "$BASE" ]; then
	#Check if partition metadata json file provided
	if [ -z "$PARTITION" ]; then
		error "Please provide partition metadata json file"
	fi
	#Check if platform json file provided
	if [ -z "$PLATFORM" ]; then
		error "Please provide platform json file"
	fi
	#Check if jq package installed
	command -v jq >&2 || error "jq not found"
	#Extract UUID from partition metadata json file
	EXTRACTUUID=$(jq ".partition_metadata.logic_uuid" "$PARTITION")
	UUID=$(echo "$EXTRACTUUID" | tr -d '"')
	#Use default package name/version, maintainer if not provided
	[ -z "$PKGNAME" ] && PKGNAME="xrt-emb-plus-ve2302-base$DEVICE" && echo "Using default PKGNAME: $PKGNAME"
	[ -z "$PKGVER" ] && PKGVER="1.0" && echo "Using default PKGVER: $PKGVER"
	[ -z "$MAINTAINER" ] && MAINTAINER="Unknown" && echo "Using default MAINTAINER: $MAINTAINER"
elif [ -n "$APU" ]; then
	#Use default package name/version, maintainer if not provided
	[ -z "$PKGVER" ] && PKGVER="1.0" && echo "Using default PKGVER: $PKGVER"
	[ -z "$MAINTAINER" ] && MAINTAINER="Unknown" && echo "Using default MAINTAINER: $MAINTAINER"
	[ -z "$PKGNAME" ] && PKGNAME="xrt-apu-linux-ve2302" && echo "Using default PKGNAME: $PKGNAME"
fi

#Debian package name creation
BUILDDIR=${PKGNAME}_${PKGVER}${TAG}
echo "${BUILDDIR}.deb"

#Check if Debian file already exists
[ -f "${BUILDDIR}.deb" ] && error "Output file already exists: ${BUILDDIR}.deb"
mkdir -p "$BUILDDIR/DEBIAN"

#Debian package control file creation
cat <<EOF >"$BUILDDIR/DEBIAN/control"
Package: $PKGNAME
Architecture: all
Version: $PKGVER
Priority: optional
Description: AMD Versal firmware
Maintainer: $MAINTAINER
EOF

if [ -n "$BASE" ]; then
	#Create a directory path for boot xsabin to be present
	mkdir -p "$BUILDDIR/lib/firmware/xilinx/$UUID"
	mkdir -p "$BUILDDIR/opt/xilinx/firmware/emb_plus/ve2302_pcie_qdma$DEVICE/base/test"
elif [ -n "$APU" ]; then
	#Create a directory path for apu xsabin to be present
	mkdir -p "$BUILDDIR/lib/firmware/xilinx/"
fi

if [ -n "$APU" ]; then
	#Check for xsabin extension
	[ "${APU##*.}" != "xsabin" ] && error "$APU does not have .xsabin extension"
	#Rename APU to xrt-versal-apu xsabin and copy
	cp "$APU" "$BUILDDIR/lib/firmware/xilinx/xrt-versal-apu.xsabin"
elif [ -n "$BASE" ]; then
	#Check for xsabin extension
	[ "${BASE##*.}" != "xsabin" ] && error "$BASE does not have .xsabin extension"
	[ "${PLATFORM##*.}" != "json" ] && error "$PLATFORM does not have .json extension"
	#Rename BASE to partition xsabin and copy
	cp "$BASE" "$BUILDDIR/lib/firmware/xilinx/$UUID/partition.xsabin"
	#Rename PLATFORM to platform json and copy
	cp "$PLATFORM" "$BUILDDIR/opt/xilinx/firmware/emb_plus/ve2302_pcie_qdma$DEVICE/base/test/platform.json"
	#Create a symlink partition xsabin
	ln -s "/lib/firmware/xilinx/$UUID/partition.xsabin" "$BUILDDIR/opt/xilinx/firmware/emb_plus/ve2302_pcie_qdma$DEVICE/base/partition.xsabin"
fi

#Check if dpkg-deb package installed
command -v dpkg-deb >&2 || error "dpkg-deb not found"
dpkg-deb --build "$BUILDDIR"

#Remove debian package directory
rm -rf "$BUILDDIR"
