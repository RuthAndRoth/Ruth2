// ru2HUD_control.lsl - Ruth2 v3 HUD Controller
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2017 Shin Ingen
// Copyright 2019 Serie Sumei

// ss-a 29Dec2018 <seriesumei@avimail.org> - Make alpha hud link-order independent
// ss-b 30Dec2018 <seriesumei@avimail.org> - Auto-adjust position on attach
// ss-c 31Dec2018 <seriesumei@avimail.org> - Combined HUD
// ss-d 03Jan2019 <seriesumei@avimail.org> - Add skin panel
// ss-d.2 06Jan2019 <seriesumei@avimail.org> - Fix OpenSim compatibility
// ss-e 04Jan2019 <seriesumei@avimail.org> - New skin panel
// ss-f 26Jan2019 <seriesumei@avimail.org> - New Options panel
// ss-g 29Jan2019 <seriesumei@avimail.org> - Add toenail color to Options panel
// ss-h 03Feb2019 <seriesumei@avimail.org> - Reset script on ownership change
// ss-i 08Feb2019 <seriesumei@avimail.org> - Fix alpha reset to not fiddle with HUD links
// ss-j 09Feb2019 <seriesumei@avimail.org> - Add XTEA support
// ss-k 10Feb2019 <seriesumei@avimail.org> - Adjust rotations for build script
// ss-l 24Mar2019 <seriesumei@avimail.org> - Read skins from Omega-compatible notecard
// ss-m 08Sep2019 <seriesumei@avimail.org> - change minimize behaviour
// ss-n 24Jan2020 <seriesumei@avimail.org> - Add hand poses
// ss-o 15Mar2020 <seriesumei@avimail.org> - Add ankle lock
// ss-p 20Mar2020 <seriesumei@avimail.org> - Add foot poses
// ss-q 21Mar2020 <seriesumei@avimail.org> - Add skin panel
// ss-r 24Mar2020 <seriesumei@avimail.org> - Rework doll datastructures
// ss-s 26Mar2020 <seriesumei@avimail.org> - New simpler alpha HUD

// This is a heavily modified version of Shin's RC3 HUD scripts for alpha
// and skin selections.

// The app ID is used on calculating the actual channel number used for communication
// and must match in both the HUD and receivers.
integer APP_ID = 20181024;

vector alphaOnColor = <0.000, 0.000, 0.000>;
vector buttonOnColor = <0.000, 1.000, 0.000>;
vector offColor = <1.000, 1.000, 1.000>;

vector tglOnColor = <0.000, 1.000, 0.000>;
vector tglOffColor = <1.000, 1.000, 1.000>;

// Which API version do we implement?
integer API_VERSION = 2;

list fingernails = [
    "fingernailsshort::fingernails",
    "fingernailsmedium::fingernails",
    "fingernailslong::fingernails",
    "fingernailsoval::fingernails",
    "fingernailspointed::fingernails"
];

list fingernail_colors = [
    <0.80, 0.78, 0.74>,
    <0.76, 0.69, 0.57>,
    <0.97, 0.57, 0.97>,
    <0.86, 0.14, 0.63>,
    <0.78, 0.19, 0.41>,
    <1.00, 0.00, 0.00>,
    <0.75, 0.00, 0.00>,
    <0.50, 0.00, 0.00>,
    <0.25, 0.00, 0.00>,
    <0.12, 0.12, 0.11>
];

// Keep a mapping of link number to prim name
list prim_map = [];

integer num_links = 0;

// HUD Positioning offsets
float bottom_offset = 1.36;
float left_offset = -0.22;
float right_offset = 0.22;
float top_offset = 0.46;
integer last_attach = 0;

vector MIN_BAR = <0.0, 0.0, 0.0>;
vector OPTION_HUD = <PI_BY_TWO, 0.0, 0.0>;
vector SKIN_HUD = <PI, 0.0, 0.0>;
vector ALPHA_HUD = <-PI_BY_TWO, 0.0, 0.0>;
vector alpha_rot;
vector last_rot;

integer VERBOSE = FALSE;

// Memory limit
integer MEM_LIMIT = 64000;

// Ruth link messages
integer LINK_RUTH_HUD = 40;
integer LINK_RUTH_APP = 42;

// The name of the XTEA script
string XTEA_NAME = "r2_xtea";

// Set to encrypt 'message' and re-send on channel 'id'
integer XTEAENCRYPT = 13475896;

// Set in the reply to a received XTEAENCRYPT if the passed channel is 0 or ""
integer XTEAENCRYPTED = 8303877;

// Set to decrypt 'message' and reply vi llMessageLinked()
integer XTEADECRYPT = 4690862;

// Set in the reply to a received XTEADECRYPT
integer XTEADECRYPTED = 3450924;

integer haz_xtea = FALSE;

integer r2channel;
integer visible_fingernails = 0;

// *****
// New alpha part management

// Enumerate the body region types as of Bakes on Mesh
// We added our fingernail and toenail types at the end
// The index of this list is the value of <body-region> in the element_map

list regions = [
    "head",
    "upper",
    "lower",
    "eyes",
    "skirt",
    "hair",
    "leftarm",
    "leftleg",
    "aux1",
    "aux2",
    "aux3",
    "fingernails",
    "toenails"
];

// <prim-name>, <face>, <button-group>, <body-region>

integer element_stride = 4;
list element_map = [
    "body", 3, "head", 0,
    "body", 4, "neck", 1,
    "body", 6, "arms", 1,
    "body", 1, "hands", 1,
    "fingernails", -1, "hands", 11,
    "body", 7, "torso", 2,
    "body", 5, "legs", 2,
    "body", 0, "feet", 2,
    "body", 2, "hair", 5,
    "toenails", -1, "feet", 12,
    "lefteye", -1, "eyes", 3,
    "righteye", -1, "eyes", 3
];

// A JSON buffer to save the alpha values of elements:
// key - element name
// value - 16-bit alpha values, 1 bit per face: 0 == visible, 1 == invisible
// Note this representation is opposite of the usage in the rest of this script where
// alpha values are integer representations of the actual face alpha float
string current_alpha = "{}";

// Alpha HUD button map
list alpha_buttons = [
    // alpha0
    "",
    "head",
    "neck",
    "arms",
    "hands",
    "fingernails",
    "",
    "hide",
    // alpha1
    "",
    "",
    "torso",
    "legs",
    "feet",
    "toenails",
    "",
    "show"
];


// *****

// ***
// Hand pose
string gcPrevRtAnim = "";     //the previously selected animation on the right side
string gcPrevLfAnim = "";     //the previously selected animation on the left side
string gcWhichSide = "";      //Whether the currently selected animation is a right or left hand
integer gnButtonNo = 0;       //The number of the button pressed by the user
integer gnPrimNo;             //The prim which contains the button pressed
integer gnPrimFace;           //The face of the prim containing the button pressed
integer gnButtonStart;        //The starting number of a group of buttons
vector gvONColor =  <0.224, 0.800, 0.800>;  //Teal color to indicate the button has been pressed
vector gvOFFColor = <1.0, 1.0, 1.0>;  //white color to indicate the button has not been pressed

integer hp_index = 0;
integer do_hp = FALSE;
// ***

// ***
// Foot pose
integer fp_offset = 30;     // Add to the fp1 index (face) to get the actual anim in inventory
string PrevFootAnim = "";
string AnkleLockAnim = "30_anklelock";      // The index value must match the fp_offset above
integer AnkleLockEnabled = FALSE;
integer AnkleLockLink = 0;
integer AnkleLockFace = 4;
integer fp_index = 0;
integer do_fp = FALSE;
// ***

// ***
// Skin / Bakes on Mesh
integer SkinLink = 0;
integer BoMEnabled = FALSE;
integer BoMLink = 0;
integer BoMTexLink = 0;
integer BoMFace = 4;
integer ShowBoMPreview = FALSE;
// ***

log(string msg) {
    if (VERBOSE == 1) {
        llOwnerSay(msg);
    }
}

// See if the notecard is present in object inventory
integer can_haz_notecard(string name) {
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    while (count--) {
        if (llGetInventoryName(INVENTORY_NOTECARD, count) == name) {
            log("Found notecard: " + name);
            return TRUE;
        }
    }
    llOwnerSay("Notecard " + name + " not found");
    return FALSE;
}

// See if the XTEA script is present in object inventory
integer can_haz_script(string name) {
    integer count = llGetInventoryNumber(INVENTORY_SCRIPT);
    while (count--) {
        if (llGetInventoryName(INVENTORY_SCRIPT, count) == name) {
            log("Found script: " + name);
            return TRUE;
        }
    }
    llOwnerSay("Script " + name + " not found");
    return FALSE;
}

send(string msg) {
    if (haz_xtea) {
        llMessageLinked(LINK_THIS, XTEAENCRYPT, msg, (string)r2channel);
    } else {
        llSay(r2channel, msg);
    }
    if (VERBOSE == 1) {
        llOwnerSay("S: " + msg);
    }
}

send_csv(list msg) {
    send(llList2CSV(msg));
}

// Calculate a channel number based on APP_ID and owner UUID
integer keyapp2chan(integer id) {
    return 0x80000000 | ((integer)("0x" + (string)llGetOwner()) ^ id);
}

vector get_size() {
    return llList2Vector(llGetPrimitiveParams([PRIM_SIZE]), 0);
}

adjust_pos() {
    integer current_attach = llGetAttached();

    // See if attachpoint has changed
    if ((current_attach > 0 && current_attach != last_attach) ||
            (last_attach == 0)) {
        vector size = get_size();

        // Nasty if else block
        if (current_attach == ATTACH_HUD_TOP_LEFT) {
            llSetPos(<0.0, left_offset - size.y / 2, top_offset - size.z / 2>);
        }
        else if (current_attach == ATTACH_HUD_TOP_CENTER) {
            llSetPos(<0.0, 0.0, top_offset - size.z / 2>);
        }
        else if (current_attach == ATTACH_HUD_TOP_RIGHT) {
            llSetPos(<0.0, right_offset + size.y / 2, top_offset - size.z / 2>);
        }
        else if (current_attach == ATTACH_HUD_BOTTOM_LEFT) {
            llSetPos(<0.0, left_offset - size.y / 2, bottom_offset + size.z / 2>);
        }
        else if (current_attach == ATTACH_HUD_BOTTOM) {
            llSetPos(<0.0, 0.0, bottom_offset + size.z / 2>);
        }
        else if (current_attach == ATTACH_HUD_BOTTOM_RIGHT) {
            llSetPos(<0.0, right_offset + size.y / 2, bottom_offset + size.z / 2>);
        }
        else if (current_attach == ATTACH_HUD_CENTER_1) {
        }
        else if (current_attach == ATTACH_HUD_CENTER_2) {
        }
        last_attach = current_attach;
    }
}


// *****
// get/set alpha values in JSON buffer

// j - JSON value storage
// name - prim_name
// face - integer face, -1 returns the unmasked 16 bit value
// Internal JSON values are ones complement, ie a 1 bit means the face is not visible
integer json_get_alpha(string j, string name, integer face) {
    integer cur_val = llList2Integer(llJsonGetValue(j, [name]), 0);
    if (face < 0) {
        // All faces, return aggregate value masked to 16 bits
        cur_val = ~cur_val & 0xffff;
    } else {
        cur_val = (cur_val & (1 << face)) == 0;
    }
    return cur_val;
}

// j - JSON value storage
// name - prim_name
// face - integer face, -1 sets all 16 bits in the value
// value - alpha boolean, 0 = invisible, 1 = visible
// Internal JSON values are ones complement, ie a 1 bit means the face is not visible
string json_set_alpha(string j, string name, integer face, integer value) {
    value = !value;  // logical NOT for internal storage
    integer cur_val = llList2Integer(llJsonGetValue(j, [name]), 0);
    integer mask;
    integer cmd;
    if (face < 0) {
        // All faces
        mask = 0x0000;
        // One's complement
        cmd = -value;
    } else {
        mask = ~(1 << face);
        cmd = (value << face);
    }
    // Mask final value to 16 bits
    cur_val = ((cur_val & mask) | cmd) & 0xffff;
    return llJsonSetValue(j, [name], (string)(cur_val));
}
// *****


// Set the alpha val of all links matching name
set_alpha(string name, integer face, float alpha) {
    log("set_alpha(): name="+name+" face="+(string)face+" alpha="+(string)alpha);
    send_csv(["ALPHA", name, face, alpha]);
    current_alpha = json_set_alpha(current_alpha, name, face, (integer)alpha);
    integer link;
    for (; link < num_links; ++link) {
        // Set color for all matching link names
        if (llList2String(prim_map, link) == name) {
            // Reset links that appear in the list of body parts
            if (alpha == 0) {
                llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, face, alphaOnColor, 1.0]);
            } else {
                llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, face, offColor, 1.0]);
            }
        }
    }
}

// alpha = -1 toggles the current saved value
set_alpha_group(string group_name, integer alpha) {
    integer i;
    list groups = llList2ListStrided(llDeleteSubList(element_map, 0, 1), 0, -1, element_stride);
    integer len = llGetListLength(groups);
    for (i = 0; i <= len; ++i) {
        if (llList2String(groups, i) == group_name) {
            // process matching group entry
            string prim_name = llList2String(element_map, i * element_stride);
            integer doll_face = llList2Integer(element_map, (i * element_stride) + 1);
            if (alpha < 0) {
                // Toggle the current value
                log("json: " + current_alpha);
                alpha = !json_get_alpha(current_alpha, prim_name, doll_face);
                log("val: " + (string)alpha);
            }
            set_alpha(prim_name, doll_face, alpha);
        }
    }
}

reset_alpha(float alpha) {
    // Reset body and HUD doll
    list seen = [];
    list groups = llList2ListStrided(llDeleteSubList(element_map, 0, 1), 0, -1, element_stride);
    integer len = llGetListLength(groups);
    integer i;
    for (i = 0; i < len; ++i) {
        string prim_name = llList2String(element_map, i * element_stride);
        if (llListFindList(seen, [prim_name]) < 0) {
            seen += [prim_name];
            set_alpha(prim_name, -1, alpha);
        }
    }

    // Reset HUD buttons
    for(i = 0; i <= 1; ++i) {
        set_alpha("alpha" + (string)i, -1, alpha);
    }
}

// Send to listening Omega-compatible relay scripts
apply_texture(string button) {
    llMessageLinked(LINK_THIS, 411, button + "|apply", "");
}

// Literal API for TEXTURE v2 command
texture_v2(string name, string tex, integer face, vector color) {
    string cmd = llList2CSV(["TEXTURE", name, tex, face, color]);
    log(cmd);
    send(cmd);
}

integer is_ankle_lock_running() {
    return (
        llListFindList(
            llGetAnimationList(llGetOwner()),
            [llGetInventoryKey(AnkleLockAnim)]
        ) >= 0
    );
}

set_ankle_color(integer link) {
    if (AnkleLockEnabled) {
        llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, AnkleLockFace, <0.0, 1.0, 0.0>, 1.0]);
    } else {
        llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, AnkleLockFace, <1.0, 1.0, 1.0>, 1.0]);
    }
}

set_bom_color(integer link) {
    if (BoMEnabled) {
        llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, BoMFace, <0.0, 1.0, 0.0>, 1.0]);
        if (ShowBoMPreview) {
            llSetLinkPrimitiveParamsFast(BoMTexLink, [
                PRIM_COLOR, 0, <1.0, 1.0, 1.0>, 1.0,
                PRIM_TEXTURE, 0, IMG_USE_BAKED_HEAD, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, 1, <1.0, 1.0, 1.0>, 1.0,
                PRIM_TEXTURE, 1, IMG_USE_BAKED_UPPER, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, 2, <1.0, 1.0, 1.0>, 1.0,
                PRIM_TEXTURE, 2, IMG_USE_BAKED_LOWER, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, 3, <1.0, 1.0, 1.0>, 1.0,
                PRIM_TEXTURE, 3, IMG_USE_BAKED_LEFTARM, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, 4, <1.0, 1.0, 1.0>, 1.0,
                PRIM_TEXTURE, 4, IMG_USE_BAKED_LEFTLEG, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, 5, <1.0, 1.0, 1.0>, 1.0,
                PRIM_TEXTURE, 5, IMG_USE_BAKED_EYES, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);
        }
    } else {
        llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, BoMFace, <1.0, 1.0, 1.0>, 1.0]);
        llSetLinkPrimitiveParamsFast(BoMTexLink, [
            PRIM_COLOR, 0, <1.0, 1.0, 1.0>, 0.0,
            PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
        ]);
    }
}

init() {
    // Initialize attach state
    last_attach = llGetAttached();
    log("state_entry() attached=" + (string)last_attach);

    r2channel = keyapp2chan(APP_ID);
    llListen(r2channel+1, "", "", "");
    llMessageLinked(LINK_THIS, LINK_RUTH_APP,  llList2CSV(["appid", APP_ID]), "");
    send_csv(["STATUS", API_VERSION]);

    // Create map of all links to prim names
    integer i;
    num_links = llGetNumberOfPrims() + 1;
    for (; i < num_links; ++i) {
        list p = llGetLinkPrimitiveParams(i, [PRIM_NAME]);
        string name = llList2String(p, 0);
        prim_map += [name];
        if (name == "fp0") {
            AnkleLockLink = i;
        }
        if (name == "bom0") {
            BoMLink = i;
        }
        if (name == "bom1") {
            BoMTexLink = i;
        }
        if (name == "sk0") {
            SkinLink = i;
        }
    }

    alpha_rot = ALPHA_HUD;
    last_rot = OPTION_HUD;

    log("Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);

    haz_xtea = can_haz_script(XTEA_NAME);

    AnkleLockEnabled = is_ankle_lock_running();
    set_ankle_color(AnkleLockLink);
}

default {
    state_entry() {
        init();
    }

    listen(integer channel, string name, key id, string message) {
        if (llGetOwnerKey(id) == llGetOwner()) {
            if (channel == r2channel+1) {
                log("R: " + message);
                list cmdargs = llCSV2List(message);
                string command = llToUpper(llList2String(cmdargs, 0));

                if (command == "STATUS") {
                    llOwnerSay(
                        "STATUS: " +
                        "API v" + llList2String(cmdargs, 1) + ", " +
                        "Type " + llList2String(cmdargs, 2) + ", " +
                        "Attached " + llList2String(cmdargs, 3)
                    );
                }
            }
        }
    }

    touch_start(integer total_number) {
        integer link = llDetectedLinkNumber(0);
        integer face = llDetectedTouchFace(0);
        vector pos = llDetectedTouchST(0);
        string name = llGetLinkName(link);
        string message;

        log("link=" + (string)link + " face=" + (string)face + " name=" + name);

        if (name == "rotatebar") {
            if(face == 1||face == 3||face == 5||face == 7) {
                rotation localRot = llList2Rot(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_ROT_LOCAL]), 0);
                llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_ROT_LOCAL, llEuler2Rot(<0.0, -PI_BY_TWO, 0.0>)*localRot]);
            } else {
                rotation localRot = llList2Rot(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_ROT_LOCAL]), 0);
                llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_ROT_LOCAL, llEuler2Rot(<0.0, PI_BY_TWO, 0.0>)*localRot]);
            }
            // Save current alpha rotation
            alpha_rot = llRot2Euler(llList2Rot(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_ROT_LOCAL]), 0));
        }
        else if (name == "minbar" || name == "alphabar" || name == "optionbar" || name == "skinbar") {
            integer bx = (integer)(pos.x * 10);
            integer by = (integer)(pos.y * 10);
            log("x,y="+(string)bx+","+(string)by);

            if (bx == 0 || bx == 1 || bx == 8 || name == "minbar") {
                // min
                vector next_rot = MIN_BAR;

                if (last_rot == MIN_BAR) {
                    // Save current rotation for later
                    last_rot = llRot2Euler(llList2Rot(llGetLinkPrimitiveParams(LINK_ROOT,[PRIM_ROT_LOCAL]),0));
                } else {
                    // Restore last rotation
                    next_rot = last_rot;
                    last_rot = MIN_BAR;
                }
                llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_ROT_LOCAL,llEuler2Rot(next_rot)]);
            }
            else if (bx == 2 || bx == 3) {
                // alpha
                llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_ROT_LOCAL,llEuler2Rot(alpha_rot)]);
                last_rot = MIN_BAR;
            }
            else if (bx == 4 || bx == 5) {
                // skin
                llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_ROT_LOCAL,llEuler2Rot(SKIN_HUD)]);
                last_rot = MIN_BAR;
            }
            else if (bx == 6 || bx == 7) {
                // options
                llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_ROT_LOCAL,llEuler2Rot(OPTION_HUD)]);
                last_rot = MIN_BAR;
            }
            else if (bx == 9) {
                log("DETACH!");
                llRequestPermissions(llDetectedKey(0), PERMISSION_ATTACH);
            }
        }
        else if (name == "alphadoll") {
            // Handle the doll before the buttons
            integer bx = (integer)(pos.x * 10);
            integer by = (integer)(pos.y * 10);
            if ((pos.x > 0.475 && pos.x < 0.525) && (pos.y > 0.775 && pos.y < 0.8)) {
                // neck
                set_alpha_group("neck", -1);
            }
            else if (bx == 4 || bx == 5) {
                if (by == 8) {
                    // head
                    set_alpha_group("head", -1);
                }
                else if (by == 6 || by == 7) {
                    // torso (except neck)
                    set_alpha_group("torso", -1);
                }
                else if (by > 1 && by < 6) {
                    // legs
                    set_alpha_group("legs", -1);
                }
                else if (by == 1) {
                    // feet
                    set_alpha_group("feet", -1);
                }
            }
            else if ((bx == 3 || bx == 6) && (by == 6 || by == 7)) {
                // arms
                set_alpha_group("arms", -1);
            }
            else if ((bx == 3 || bx == 6) && by == 5) {
                // hands
                set_alpha_group("hands", -1);
            }
        }
        else if (llGetSubString(name, 0, 4) == "alpha") {
            integer b = ((integer)llGetSubString(name, 5, -1));
            if (b == 0 && face == 7) {
                // Hide all
                reset_alpha(0.0);
            }
            else if (b == 1 && face == 7) {
                // Show all
                reset_alpha(1.0);
            }
            else {
                set_alpha_group(llList2String(alpha_buttons, (b * 8) + face), -1);

                // Set button color
                vector face_color = llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_NAME, PRIM_COLOR, face]), 1);
                if (face_color == offColor) {
                    llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, face, buttonOnColor, 1.0]);
                } else {
                    llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, face, offColor, 1.0]);
                }
            }
        }
        else if (name == "bom0") {
            // Bakes on Mesh
            BoMEnabled = TRUE;
            set_bom_color(BoMLink);
            apply_texture("bom");
        }
        else if (llGetSubString(name, 0, 1) == "sk") {
            // Skin appliers
            BoMEnabled = FALSE;
            set_bom_color(BoMLink);
            apply_texture((string)face);
        }
        else if (llGetSubString(name, 0, 2) == "fnc") {
            // Fingernail color
            integer b = (integer)llGetSubString(name, 3, -1);
            integer index = (b * 5) + face;
            if (index >= 0 && index <= 9) {
                texture_v2(
                    "fingernails",
                    "",
                    ALL_SIDES,
                    llList2Vector(fingernail_colors, index)
                );
            }
        }
        else if (llGetSubString(name, 0, 2) == "fns") {
            // Fingernail shape
            list nail_types = [
                "fingernailsshort",
                "fingernailsmedium",
                "fingernailslong",
                "fingernailspointed",
                "fingernailsnone",
                "fingernailsoval"
            ];
            integer b = (integer)llGetSubString(name, 2, -1);
            if (face >= 0 && face <= 4) {
                integer num = llGetListLength(nail_types);
                integer i = 0;
                visible_fingernails = face;
                for (; i < num; ++i) {
                    if (i == face) {
                        send_csv(["ALPHA", llList2String(nail_types, i), ALL_SIDES, 1.0]);
                    } else {
                        send_csv(["ALPHA", llList2String(nail_types, i), ALL_SIDES, 0.0]);
                    }
                }
            }
        }
        else if (llGetSubString(name, 0, 2) == "tnc") {
            // Toenail color
            integer b = (integer)llGetSubString(name, 3, -1);
            integer index = (b * 5) + face;
            if (index >= 0 && index <= 9) {
                texture_v2(
                    "toenails",
                    "",
                    ALL_SIDES,
                    llList2Vector(fingernail_colors, index)
                );
            }
        }
        else if (llGetSubString(name, 0, 1) == "hp") {
            // Hand poses
            integer b = ((integer)llGetSubString(name, 2, -1));
            // 4 buttons per link
            if (b == 0) {
                // Stop
                hp_index = 0;
            } else {
                list facemap = [2, 4, 6, 8, 1, 3, 5, 7];
                // Calculate which column
                hp_index = ((b - 1) * 8) + llList2Integer(facemap, face);
            }
            log("index: " + (string)hp_index);
            do_hp = TRUE;
            llRequestPermissions(llDetectedKey(0), PERMISSION_TRIGGER_ANIMATION);
        }
        else if (llGetSubString(name, 0, 1) == "fp") {
            // Foot poses
            if (name == "fp0") {
                // Ankle Lock
                AnkleLockEnabled = !AnkleLockEnabled;
                log("ankle lock: " + (string)AnkleLockEnabled);
                fp_index = face;
                set_ankle_color(link);
                do_fp = TRUE;
                llRequestPermissions(llDetectedKey(0), PERMISSION_TRIGGER_ANIMATION);
            } else {
                fp_index = face + 1;
                log("index: " + (string)face);
                do_fp = TRUE;
                llRequestPermissions(llDetectedKey(0), PERMISSION_TRIGGER_ANIMATION);
            }
        }
        else {
            // Do nothing here
        }
    }

    link_message(integer sender_number, integer number, string message, key id) {
        log("l_m: num: " + (string)number + " msg: " + message + " id: " + (string)id);
        if (number == LINK_RUTH_HUD) {
            // <command>,<arg1>,...
            list cmdargs = llCSV2List(message);
            string command = llToUpper(llList2String(cmdargs, 0));
            if (command == "STATUS") {
                log("Loaded notecard: " + llList2String(cmdargs, 1));
            }
            else if (command == "THUMBNAILS") {
                log("Loaded notecard: " + llList2String(cmdargs, 1));
                integer len = llGetListLength(cmdargs);
                integer i;
                for (i = 2; i <= len; ++i) {
                    llSetLinkPrimitiveParamsFast(SkinLink, [
                        PRIM_COLOR, i-2, <1.0, 1.0, 1.0>, 1.0,
                        PRIM_TEXTURE, i-2, llList2String(cmdargs, i), <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
                    ]);
                }
            }
        }
    }

    run_time_permissions(integer perm) {
        if (perm & PERMISSION_ATTACH) {
            llDetachFromAvatar();
        }
        if (perm & PERMISSION_TRIGGER_ANIMATION) {
            if (do_hp && hp_index == 0) {
                // Stop all animations
                list anims = llGetAnimationList(llGetPermissionsKey());
                integer len = llGetListLength(anims);
                integer i;
                for (i = 0; i < len; ++i) {
                    llStopAnimation(llList2Key(anims, i));
                }
                // removing all anims can create problems - this sorts things out
                llStartAnimation("stand");
                llOwnerSay("All finished: " + (string)len + llGetSubString(" animations",0,-1 - (len == 1))+" stopped.\n");
                do_hp = FALSE;
            }
            else if (do_hp && hp_index > 0) {
                // Locate and play a pose animation
                integer nCounter = -1;
                integer lFlag = FALSE;
                integer nTotCount = llGetInventoryNumber(INVENTORY_ANIMATION);
                integer nItemNo;
                string anim = "";
                do {
                    nCounter++;
                    anim = llGetInventoryName(INVENTORY_ANIMATION, nCounter);
                    nItemNo = (integer)anim;
                    if (nItemNo == hp_index) {
                        //When the Animation number matches the button number
                        if (anim != "") {
                            log("hp anim: " + anim);
//                            ColorButton();
                            //it also returns a value for gcWhichSide

                            if ((hp_index % 2) == 1) {
                                log(" left");
                                // Left side is odd
                                if (gcPrevLfAnim != "") {
                                    llStopAnimation(gcPrevLfAnim);
                                }
                                gcPrevLfAnim = anim;
                            } else {
                                log(" right");
                                // Right side
                                if (gcPrevRtAnim != "") {
                                    llStopAnimation(gcPrevRtAnim);
                                }
                                gcPrevRtAnim = anim;
                            }
                            llStartAnimation(anim);
                            //llOwnerSay("We started: "+anim+"  gcPrevLfAnim is: "+gcPrevLfAnim+"  " + "gcPrevRtAnim is: "+gcPrevRtAnim);
                            lFlag = TRUE; //We found the animation
                        }
                    }
                }
                while (nCounter < nTotCount && !lFlag);

                if (!lFlag) {
                    //Error messages - explanations of common problems a user might have if they assemble the HUD or add their own animations
                    if (nItemNo == 0) {
                        llOwnerSay("There's a problem.  First check to make sure you've loaded all of the hand animations in the HUD inventory.  There should be 24 of them.  If that's not the problem, you may have used an incorrect name for one of the prims making up the HUD. Finally, double check to make sure that the backboard of the HUD is the last prim you linked (the root prim).\n");
                    }
                    else {
                        llOwnerSay("Animation # "+(string)nItemNo + " was not found.  Check the animations in the inventory of the HUD.  When numbering the animations, you may have left this number out.\n");
                    }
                }
                do_hp = FALSE;
            }
            if (do_fp) {
                fp_index += fp_offset;
                if (fp_index == fp_offset) {
                    // Handle ankle lock
                    if (AnkleLockEnabled) {
                        log(" start " + AnkleLockAnim);
                        llStartAnimation(AnkleLockAnim);
                    } else {
                        log(" stop " + AnkleLockAnim);
                        llStopAnimation(AnkleLockAnim);
                    }
                } else {
                    // Handle foot poses
                    integer nCounter = -1;
                    integer nTotCount = llGetInventoryNumber(INVENTORY_ANIMATION);
                    string anim = "";
                    // Adjust for the foot pose animation index
                    do {
                        nCounter++;
                        anim = llGetInventoryName(INVENTORY_ANIMATION, nCounter);
                        if ((integer)anim == fp_index) {
                            log("fp anim: " + anim);
                            if (PrevFootAnim != "") {
                                log(" stopping: " + PrevFootAnim);
                                llStopAnimation(PrevFootAnim);
                            }
                            PrevFootAnim = anim;
                            llStartAnimation(anim);
//                            llOwnerSay("We started: " + anim + "  PrevFootAnim is: " + PrevFootAnim);
                            nCounter = nTotCount;   // Implicit break
                        }
                    }
                    while (nCounter < nTotCount);
                }
                do_fp = FALSE;
            }
        }
    }

    attach(key id) {
        if (id == NULL_KEY) {
            // Nothing to do on detach?
        } else {
            // Fix up our location
            adjust_pos();
        }
    }

    changed(integer change) {
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY)) {
            init();
        }
    }
}
