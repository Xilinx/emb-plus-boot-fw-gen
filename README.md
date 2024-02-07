# rave-boot-fw-gen
This repo is for tracking and maintaining the RAVE platform OSPI boot FW generation sources including generation scripts and platform meta-data.  

## gen_fpt_bin.py
This script is provided to generate the Flash Partition Table (FPT) binaries from the provided metadata 

    $ ./gen_fpt_bin.py --fpt <path/to/metadata.json> --out <path/to/output.bin>

For example, to generate the RAVE metadata (main FPT and extension FPT):

    $ ./gen_fpt_bin.py --fpt metadata/rave_ivh/main_fpt.json --out main_fpt.bin
    $ ./gen_fpt_bin.py --fpt metadata/rave_ivh/ext_fpt.json --out ext_fpt.bin

## package_apu_deb.sh
This script is used to package an APU image (.xsabin) into a Debian package (.deb) for installation in the required directory

For usage instaructions

    $ ./package_deb.sh --help

Example usage:

    $ ./package_deb.sh -a <path/to/apu.xsabin>
    $ ./package_deb.sh -e <path/to/boot.xsabin> -g <path/to/partition_metadata.json>
    $ ./package_deb.sh -e <path/to/boot.xsabin> -g <path/to/partition_metadata.json> -v 2.0 -m AMD,Inc.

Optionally, the package version, maintainer and name can be set when creating the package
