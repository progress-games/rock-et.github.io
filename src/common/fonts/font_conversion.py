#!/usr/bin/env python

import sys
import argparse
from pathlib import Path

from fontTools.ttLib import TTFont


# Fixes the scaling on PixelForge TTF fonts
def fix_pixelforge_ttf_scaling(font_in_path, font_out_path, scale=0.75):
    font_in_path = Path(font_in_path)
    font_out_path = Path(font_out_path)
    
    font = TTFont(font_in_path)
    
    head = font['head']
    head.unitsPerEm = round(head.unitsPerEm * scale)
    
    font.save(font_out_path)


# Parse arguments
def parse_args(args):
    parser = argparse.ArgumentParser(
        description="Fixes the Units Per Em (UPEM) value of a TTF file exported from PixelForge to make the suggested font sizes accurate.\n"
                    "Basically, there is a bug in PixelForge that makes the UPEM 133.33% larger than it should be.\n"
                    "This simply scales the UPEM down by 75%.",
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("-i", "--input", dest="input_font", type=str, required=True,
                        help=f"the path to the TTF to convert"
                       )
    
    parser.add_argument("-o", "--output", dest="output_font", type=str, required=True,
                        help=f"the path and filename of the desired output TTF file"
                       )

    parsed_args = parser.parse_args(args)
    
    # Interpret string arguments
    input_font = Path(parsed_args.input_font)
    if not input_font.is_file():
        parser.error(f"the file \"{input_font}\" does not exist")
    parsed_args.input_font = input_font
    
    output_font = Path(parsed_args.output_font)
    if input_font.resolve(strict=False) == output_font.resolve(strict=False):
        parser.error("the output font file must be different than the input one")
    parsed_args.output_font = output_font
    
    return parsed_args


def main(args):
    print()
    parsed_args = parse_args(args)
    
    fix_pixelforge_ttf_scaling(parsed_args.input_font, parsed_args.output_font)
    print(f"Saved fixed TTF to \"{parsed_args.output_font}\"")


if __name__ == "__main__":
    main(sys.argv[1:])