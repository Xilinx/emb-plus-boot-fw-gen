# rave-boot-fw-gen
This repo is for tracking and maintaining the RAVE platform OSPI boot FW generation sources including generation scripts and platform meta-data.  

## gen_fpt_bin.py
This script is provided to generate the Flash Partition Table (FPT) binaries from the provided metadata 

    $ ./gen_fpt_bin.py --fpt <path/to/metadata.json> --out <path/to/output.bin>

For example, to generate the RAVE metadata (main FPT and extension FPT):

    $ ./gen_fpt_bin.py --fpt metadata/rave_ivh/main_fpt.json --out main_fpt.bin
    $ ./gen_fpt_bin.py --fpt metadata/rave_ivh/ext_fpt.json --out ext_fpt.bin
