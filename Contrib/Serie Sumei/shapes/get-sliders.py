#!/usr/bin/env python
# get-sliders.py
# SPDX-License-Identifier: MIT
# Copyright 2021 Serie Sumei

# Extract interesting attributes from exported shape XML files.

# Export avatar appearance via Firestorm's menu
# Developer -> Avatar -> Character Tests -> Appearance To XML

# Run this to extract the slider values for the basic types: shape, hair, eyes
# shape can also be split into head and body to simplify copying only a head
# or body sliders to a new shape.

# The resulting XML files can be imported on top of an existing or a new shape.

# The --text option will display the slider values as showin in the edit
# dialogs.  This is useful for just getting the numbers.

import argparse
import logging
import sys
import traceback
from xml.dom import minidom

from lxml import etree

CONSOLE_MESSAGE_FORMAT = '%(levelname)s: %(name)s %(message)s'
DEFAULT_VERBOSE_LEVEL = 1

_logger = logging.getLogger(__name__)

# --debug sets this True
dump_stack_trace = False

MALE_TORSO = [
    678,    # Torso Muscles (male)
    683,    # Neck Thickness
    756,    # Neck Length
    36,     # Shoulders
    685,    # Pectorals
    693,    # Arm Length
    675,    # Hand Size
    38,     # Torso Length
    676,    # Love Handles
    157,    # Belly Size
]
MALE_LEGS = [
    152,    # Leg Muscles
    692,    # Leg Length
    37,     # Hip Width
    842,    # Hip Length
    151,    # Butt Size
    879,    # Package
    753,    # Saddle Bags
    841,    # Knee Angle
    515,    # Foot Size
]
MALE_FACIAL = [
    752,    # Hair Thickness
    166,    # Sideburns
    167,    # Moustache
    169,    # Chin Curtains
    168,    # Soulpatch
]

BODY_SLIDERS = {
    "body": [
        33,     # Height
        34,     # Body Thickness
        637,    # Body Fat
        11001,  # Hover
    ],
    "torso": [
        649,    # Torso Muscles (female)
        683,    # Neck Thickness
        756,    # Neck Length
        36,     # Shoulders
        105,    # Breast Size
        507,    # Breast Buoyancy
        684,    # Breast Cleavage
        693,    # Arm Length
        675,    # Hand Size
        38,     # Torso Length
        676,    # Love Handles
        157,    # Belly Size
    ],
    "legs": [
        152,    # Leg Muscles
        692,    # Leg Length
        37,     # Hip Width
        842,    # Hip Length
        151,    # Butt Size
        753,    # Saddle Bags
        841,    # Knee Angle
        515,    # Foot Size
    ],
}

HEAD_SLIDERS = {
    "head": [
        682,    # Head Size
        647,    # Head Stretch
        193,    # Head Shape
        186,    # Egg Head 646?
        773,    # Head Length
        662,    # Face Shear
        629,    # Forehead Angle
        1,      # Brow Size
        18,     # Upper Cheeks
        10,     # Lower Cheeks
        14,     # Cheek Bones
    ],
    "eyes": [
        690,    # Eye Size
        24,     # Eye Opening
        196,    # Eye Spacing
        650,    # Outer Eye Corner
        880,    # Inner Eye Corner
        769,    # Eye Depth
        21,     # Upper Eyelid Fold
        23,     # Eye Bags
        765,    # Puffy Eyelids
        518,    # Eyelash Length
        664,    # Eye Pop
    ],
    "ears": [
        35,     # Ear Size
        15,     # Ear Angle
        22,     # Attached Earlobes
        796,    # Ear Tips
    ],
    "nose": [
        2,      # Nose Size
        517,    # Nose Width
        4,      # Nostril Width
        759,    # Nosrtil Division
        20,     # Nose Thickness
        11,     # Upper Bridge
        758,    # Lower Bridge
        27,     # Bridge Width
        19,     # Nose Tip Angle
        6,      # Nose Tip Shape
        656,    # Crooked Nose
    ],
    "mouth": [
        155,    # Lip Width
        653,    # Lip Fullness
        505,    # Lip Thickness
        799,    # Lip Ratio
        506,    # Mouth Position
        659,    # Mouth Corner
        764,    # Lip Cleft Depth
        25,     # Lip Cleft
        663,    # Shift Mouth
    ],
    "chin": [
        7,      # Chin Angle
        17,     # Jaw Shape
        185,    # Chin Depth
        760,    # Jaw Angle
        665,    # Jaw Jut
        12,     # Jowls
        5,      # Chin Cleft
        13,     # Upper Chin Cleft
        8,      # Chin-Neck
    ],
}

HAIR_SLIDERS = {
    "color": [
        115,    # White Hair
        112,    # Rainbow Color
        114,    # Blonde Hair
        113,    # Red Hair
    ],
    "style": [
        763,    # Hair: Volume
        133,    # Hair: Front
        134,    # Hair: Sides
        135,    # Hair: Back
        181,    # Big Hair: Front
        182,    # Big Hair: Top
        183,    # Big Hair: Back
        130,    # Front Fringe
        131,    # Side Fringe
        132,    # Back Fringe
        143,    # Full Hair Sides
        136,    # Hair Sweep
        762,    # Shear Front
        674,    # Shear Back
        755,    # Taper Front
        754,    # Taper Back
        177,    # Rumpled Hair
        785,    # Pigtails
        789,    # Ponytail
        184,    # Spiked Hair
        137,    # Hair Tilt
        140,    # Middle Part
        141,    # Right Part
        142,    # Left Part
        192,    # Part Bangs
    ],
    "eyebrows": [
        119,    # Eyebrow Size
        750,    # Eyebrow Density
        757,    # Eyebrow Height
        31,     # Eyebrow Arc
        16,     # Eyebrow Points
    ],
    "facial": [
    ],
}

EYE_SLIDERS = {
    "eyes": [
        99,     # Eye Color
        98,     # Eye Lightness
    ]    
}

def is_male(doc):
    male = doc.find('.//param[@id="80"][@wearable="shape"]')
    return (male.get("u8") == "255")

def do_shape(opts):
    name = opts.rest[0]
    root = etree.parse(name)
    etree.indent(root, space=" ")

    # Make adjustments for gender attributes
    male_shape = is_male(root)
    if male_shape:
        # Stuff the male attributes into the dicts
        BODY_SLIDERS['torso'] = MALE_TORSO
        BODY_SLIDERS['legs'] = MALE_LEGS
        HAIR_SLIDERS['facial'] = MALE_FACIAL

    if opts.body:
        wearable = "shape"
        sliders = BODY_SLIDERS
    elif opts.eyes:
        wearable = "eyes"
        sliders = EYE_SLIDERS
    elif opts.hair:
        wearable = "hair"
        sliders = HAIR_SLIDERS
    elif opts.head:
        wearable = "shape"
        sliders = HEAD_SLIDERS
    elif opts.shape:
        wearable = "shape"
        sliders = HEAD_SLIDERS
        sliders.update(BODY_SLIDERS)
    else:
        wearable = "shape"
        sliders = HEAD_SLIDERS
        sliders.update(BODY_SLIDERS)
        sliders.update(HAIR_SLIDERS)
        sliders.update(EYE_SLIDERS)

    # Create the new output document
    doc = etree.Element('linden_genepool', {'version': '1.0'})
    etree.indent(doc, space="  ")
    archetype = etree.SubElement(doc, 'archetype', {'name': '???'})

    # Get all of the param elements
    for element in root.findall('.//param'):
        # Check shape params by id
        id = int(element.get("id"))
        if id == 80:
            # Keep the gender element
            if opts.body or opts.shape:
                archetype.append(element)
        if [True for values in sliders.keys() if id in sliders[values]]:
            archetype.append(element)

    if opts.text:
        # Show the lists of slider values
        for k in sliders.keys():
            str = k + ":"
            for v in sliders[k]:
                e = doc.find(".//param[@id='%s']" % v)
                if e is not None:
                    # The 'u8' attribute is a scaled 8 bit (0-255)
                    # The slider numbers are scaled 0-100
                    str += " %d," % int(round(int(e.get('u8')) / 2.55))
            print(str)
    else:
        buff = etree.tostring(doc, xml_declaration=True, encoding="utf-8")
        prettybuff = minidom.parseString(buff)
        sys.stdout.write(prettybuff.toprettyxml(indent="  ", newl=''))

def base_parser(parser):
    """Set up some of the common CLI options
    These are the basic options that match the library CLIs so
    command-line/environment setups for those also work with these
    demonstration programs.
    """

    element_group = parser.add_mutually_exclusive_group()
    element_group.add_argument(
        '--body',
        default=False,
        action='store_true',
        dest='body',
        help='Include body elements',
    )
    element_group.add_argument(
        '--eyes',
        default=False,
        action='store_true',
        dest='eyes',
        help='Include eye elements',
    )
    element_group.add_argument(
        '--hair',
        default=False,
        action='store_true',
        dest='hair',
        help='Include hair elements',
    )
    element_group.add_argument(
        '--head',
        default=False,
        action='store_true',
        dest='head',
        help='Include head elements',
    )
    element_group.add_argument(
        '--shape',
        default=False,
        action='store_true',
        dest='shape',
        help='Include shape elements (head+body)',
    )
    parser.add_argument(
        '--text',
        default=False,
        action='store_true',
        dest='text',
        help='Output text instead of XML',
    )

    # Global arguments
    parser.add_argument(
        '-v', '--verbose',
        action='count',
        dest='verbose_level',
        default=1,
        help='Increase verbosity of output. Can be repeated.',
    )
    parser.add_argument(
        '--debug',
        default=False,
        action='store_true',
        help='show tracebacks on errors',
    )
    parser.add_argument(
        'rest',
        nargs='*',
        help='the rest of the args',
    )
    return parser


def configure_logging(opts):
    """Typical app logging setup
    Based on OSC/cliff
    """

    global dump_stack_trace

    root_logger = logging.getLogger('')

    # Requests logs some stuff at INFO that we don't want
    # unless we have DEBUG
    requests_log = logging.getLogger("requests")
    requests_log.setLevel(logging.ERROR)

    # Other modules we don't want DEBUG output for so
    # don't reset them below
    iso8601_log = logging.getLogger("iso8601")
    iso8601_log.setLevel(logging.ERROR)

    # Always send higher-level messages to the console via stderr
    console = logging.StreamHandler(sys.stderr)
    formatter = logging.Formatter(CONSOLE_MESSAGE_FORMAT)
    console.setFormatter(formatter)
    root_logger.addHandler(console)

    # Set logging to the requested level
    dump_stack_trace = False
    if opts.verbose_level == 0:
        # --quiet
        root_logger.setLevel(logging.ERROR)
    elif opts.verbose_level == 1:
        # This is the default case, no --debug, --verbose or --quiet
        root_logger.setLevel(logging.WARNING)
    elif opts.verbose_level == 2:
        # One --verbose
        root_logger.setLevel(logging.INFO)
    elif opts.verbose_level >= 3:
        # Two or more --verbose
        root_logger.setLevel(logging.DEBUG)
        requests_log.setLevel(logging.DEBUG)

    if opts.debug:
        # --debug forces traceback
        dump_stack_trace = True
        root_logger.setLevel(logging.DEBUG)
        requests_log.setLevel(logging.DEBUG)

    return


def run(opts):
    """Default run command"""

    if opts.debug:
        # Do some basic testing here
        sys.stdout.write("Default run command\n")
        sys.stdout.write("Verbose level: %s\n" % opts.verbose_level)
        sys.stdout.write("Debug: %s\n" % opts.debug)
        sys.stdout.write("dump_stack_trace: %s\n" % dump_stack_trace)
        sys.stdout.write("args: %s\n" % opts.rest)

    do_shape(opts)


def setup():
    """Parse command line and configure logging"""
    opts = base_parser(
        argparse.ArgumentParser(description='template')
    ).parse_args()
    configure_logging(opts)
    return opts


def main(opts, run):
    try:
        return run(opts)
    except Exception as e:
        if dump_stack_trace:
            _logger.error(traceback.format_exc(e))
        else:
            _logger.error('Exception raised: ' + str(e))
        return 1


if __name__ == "__main__":
    opts = setup()
    sys.exit(main(opts, run))
