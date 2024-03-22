# rave-boot-fw-gen
This repo is for tracking and maintaining the RAVE platform OSPI boot FW generation sources including generation scripts and platform meta-data.  

## gen_fpt_bin.py
This script is provided to generate the Flash Partition Table (FPT) binaries from the provided metadata 

    $ ./gen_fpt_bin.py --fpt <path/to/metadata.json> --out <path/to/output.bin>

For example, to generate the RAVE metadata (main FPT and extension FPT):

    $ ./gen_fpt_bin.py --fpt metadata/rave_ivh/main_fpt.json --out main_fpt.bin
    $ ./gen_fpt_bin.py --fpt metadata/rave_ivh/ext_fpt.json --out ext_fpt.bin

## package_deb.sh
This script is used to package apu/boot.xsabin's into a Debian packages (.deb) for installation in the required directory

For usage instaructions

    $ ./package_deb.sh --help

Example usage:

    $ ./package_deb.sh -a <path/to/apu.xsabin>
    $ ./package_deb.sh -b <path/to/boot.xsabin> -f <path/to/partition_metadata.json> -g <path/to/platform.json> -i <silicon_type:es1/prod> -j <package_version> -k <maintainer_name> -m <build_date>
    $ ./package_deb.sh -b <path/to/boot.xsabin> -f <path/to/partition_metadata.json> -g <path/to/platform.json> -i es1 -j 2.0 -k AMD,Inc -m 03192024

Optionally, the package version, maintainer and name can be set when creating the package
