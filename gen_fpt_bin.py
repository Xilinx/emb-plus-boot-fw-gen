#!/usr/bin/env python3

# Copyright (c) 2023 Advanced Micro Devices, Inc. All Rights Reserved.
# Author: Sharath
#
# SPDX-License-Identifier: MIT

import argparse
import json
import sys
from binascii import crc32

fpt_dct = {'FPT': 0xFFFF, 'FPT_RAVE': 6, 'ACTIVE': 1, 'RECOVERY_FPT': 0xFFFE, 'PDI_BOOT': 0x0E00,
           'PDI_META': 0x0E05, 'PDI_BOOT_BACKUP': 0x0E01, 'PDI_META_BACKUP': 0x0E06, 'NONE': 0,
           'NA': 0, 'EXTENSION_FPT': 0xFFFD, 'PDI_XSABIN_META': 0x0E02}

def generate_fpt_binary(in_file, out_file):
    ''' Generate an FPT binary from the input JSON data '''

    # Opening JSON file
    with open(in_file) as f:
        json_obj = json.load(f)

    header_size = json_obj['fpt_header(0)']['fpt_header_size']
    entry_size = json_obj['fpt_header(0)']['fpt_entry_size']

    # Open the binary file to write
    fpw_bin = open(out_file, "wb+")

    for i in json_obj:
        print("Processing", i)
        if i == 'fpt_header(0)':
            for j in json_obj[i]:
                if j == 'magic_word':
                    fpw_bin.write(int(json_obj[i][j], 16).to_bytes(4, 'little'))
                else:
                    fpw_bin.write((json_obj[i][j]).to_bytes(1, 'little'))
            for _ in range(header_size - 8):
                fpw_bin.write(b'\x00')
        else:
            num_entry = 0
            for j in json_obj[i]:
                num_entry = num_entry + 1
                if j in ['type', 'subtype', 'common_flags', 'specific_flags']:
                    if isinstance(json_obj[i][j], list):
                        fpw_bin.write((fpt_dct[json_obj[i][j][0]]).to_bytes(4, 'little'))
                    else:
                        fpw_bin.write((fpt_dct[json_obj[i][j]]).to_bytes(4, 'little'))
                elif j in ['base_addr', 'partition_size', 'img_version', 'img_size', 'img_checksum']:
                    fpw_bin.write(int(json_obj[i][j], 16).to_bytes(4, 'little'))
                else:
                    fpw_bin.write((json_obj[i][j]).to_bytes(4, 'little'))

            for _ in range(entry_size - num_entry*4):
                fpw_bin.write(b'\x00')

    # Entries checksum
    fpw_bin.seek(128, 0)
    entries_checksum = crc32(fpw_bin.read(768))
    fpw_bin.seek(8, 0)
    fpw_bin.write(entries_checksum.to_bytes(4, 'little'))

    # Header checksum
    fpw_bin.seek(0, 0)
    header_checksum = crc32(fpw_bin.read(124))
    fpw_bin.seek(124, 0)
    fpw_bin.write(header_checksum.to_bytes(4, 'little'))

    # Closing file
    fpw_bin.close()

def main():
    ''' Main function '''

    parser = argparse.ArgumentParser(
        description='RAVE FPT to binary conversion script')
    parser.add_argument('--fpt', dest='fpt_file',
                        help='Pass an FPT JSON file to convert to binary')
    parser.add_argument('--output', dest='outfile',
                        help='Destination file after an input file(s) processed')

    # If nothing is input to this script, print usage
    if len(sys.argv[1:]) == 0:
        parser.print_help()
        parser.exit()

    args = parser.parse_args()

    print("***** FPT JSON to Binary Conversion Started *****")

    generate_fpt_binary(args.fpt_file, args.outfile)

    print("***** FPT JSON to Binary Conversion Done *****")


if __name__ == '__main__':
    main()
