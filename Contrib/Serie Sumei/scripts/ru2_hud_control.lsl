// ru2_hud_control.lsl - Ruth2 v3 HUD Controller
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2017 Shin Ingen
// Copyright 2019 Serie Sumei

// v2.0 12Apr2020 <seriesumei@avimail.org> - Based on ru2_hud_control.lsl v3.2
// v2.1 12Apr2020 <seriesumei@avimail.org> - New simpler alpha HUD
// v2.2 13May2020 <seriesumei@avimail.org> - Rework skin panel
// v3.2 07Jun2020 <seriesumei@avimail.org> - Backport to Ruth2 v3

// This is a heavily modified version of Shin's RC3 HUD scripts for alpha
// and skin selections.

// The app ID is used on calculating the actual channel number used for communication
// and must match in both the HUD and receivers.
integer APP_ID = 20181024;

vector alphaOnColor = <0.000, 0.000, 0.000>;
vector buttonOnColor = <0.400, 0.700, 0.400>;
vector faceOnColor = <0.800, 1.000, 0.800>;
vector offColor = <1.000, 1.000, 1.000>;

// Which API version do we implement?
integer API_VERSION = 2;

list fingernail_colors = [];

// Keep a mapping of link number to prim name
list link_map = [];

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
integer MEM_LIMIT = 65000;

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
// The index of this list is the value of <body-region> in the element maps

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

// A JSON buffer to save the alpha values of elements:
// key - element name
// value - 16-bit alpha values, 1 bit per face: 0 == visible, 1 == invisible
// Note this representation is opposite of the usage in the rest of this script where
// alpha values are integer representations of the actual face alpha float
string current_alpha = "{}";

// Alpha HUD button map
integer num_alpha_buttons = 8;
// These are also used as section names in mapping alpha sections in the mesh
list alpha_buttons = [
    // alpha0
    "head",
    "chest",
    "breasts",
    "nipples",
    // alpha1
    "belly",
    "upperback",
    "lowerback",
    // alpha2
    "hands",
    "fingernails",
    // alpha3
    "crotch",
    "pelvis",
    "",
    "hide",
    // alpha4
    "legs",
    "upperlegs",
    "knees",
    "lowerlegs",
    // alpha5
    "feet",
    "ankles",
    "bridges",
    "heels",
    // alpha6
    "soles",
    "toecleavage",
    "toes",
    "toenails",
    // alpha7
    "",
    "",
    "",
    "show"
];


// *****

// ***
// Hand pose
string gcPrevRtAnim = "";     //the previously selected animation on the right side
string gcPrevLfAnim = "";     //the previously selected animation on the left side
string gcWhichSide = "";      //Whether the currently selected animation is a right or left hand

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
integer current_skin = -1;
integer current_eye = -1;
integer alpha_mode = PRIM_ALPHA_MODE_MASK;
integer mask_cutoff = 128;

// Map skin selections to button faces
// Stride 2: <sk0+N>, <face>
list skin_button_faces = [
    // 0, 0,    unused
    // 0, 2,    BoM
    0, 4,
    0, 6,
    1, 0,
    1, 2,
    1, 4,
    // 1, 6,    unused
    // 2, 0,    unused
    2, 2,
    2, 4,
    2, 6,
    3, 0,
    3, 2,
    3, 4
    // 3, 6,    unused
];

// Map eye selections to button faces
// Stride 2: <eye0+N>, <face>
list eye_button_faces = [
    // 0, 0,    unused
    // 0, 2,    BoM
    0, 4,
    0, 6,
    1, 0,
    1, 2,
    1, 4
    // 1, 6,    unused
];

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
    log("Script " + name + " not found");
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
// name - link_name
// face - integer face, -1 returns the unmasked 16 bit value
// Internal JSON values are ones complement, ie a 1 bit means the face is not visible
integer json_get_alpha(string j, string name, integer face) {
    integer cur_val = (integer)llJsonGetValue(j, [name]);
    if (face < 0) {
        // All faces, return aggregate value masked to 16 bits
        cur_val = ~cur_val & 0xffff;
    } else {
        cur_val = (cur_val & (1 << face)) == 0;
    }
    return cur_val;
}

// j - JSON value storage
// name - link_name
// face - integer face, -1 sets all 16 bits in the value
// value - alpha boolean, 0 = invisible, 1 = visible
// Internal JSON values are ones complement, ie a 1 bit means the face is not visible
string json_set_alpha(string j, string name, integer face, integer value) {
    value = !value;  // logical NOT for internal storage
    integer cur_val = (integer)llJsonGetValue(j, [name]);
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
        if (llList2String(link_map, link) == name) {
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
set_alpha_section(string section_name, integer alpha) {
    integer i;
    integer len = llGetListLength(alpha_buttons);
    for (i = 0; i <= len; ++i) {
        if (llList2String(alpha_buttons, i) == section_name) {
            if (alpha < 0) {
                // Toggle the current value
                log("json: " + current_alpha);
                alpha = !json_get_alpha(current_alpha, section_name, 0);
                log("val: " + (string)alpha);
            }
            send_csv(["ALPHA", section_name, 0, alpha]);
            current_alpha = json_set_alpha(current_alpha, section_name, 0, (integer)alpha);
        }
    }
}

reset_alpha(float alpha) {
    // Reset body and HUD doll
    integer len = llGetListLength(alpha_buttons);
    integer section;
    for (section = 0; section < len; ++section) {
        string section_name = llList2String(alpha_buttons, section);
        send_csv(["ALPHA", section_name, 0, alpha]);
        current_alpha = json_set_alpha(current_alpha, section_name, 0, (integer)alpha);
    }

    // Reset HUD buttons
    integer link;
    integer j;
    for (link = 0; link < num_alpha_buttons; ++link) {
        for (j=0; j < 8; j+=2) {
            set_outline_link_face_state("alpha", link, j, 1.0, (alpha < 0.01));
        }
    }
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

// Look up link/face in map
integer lookup_button(list face_map, integer xlink, integer face) {
    integer i;
    for (i = 0; i < llGetListLength(face_map); i += 2) {
        if (llList2Integer(face_map, i) == xlink &&
            llList2Integer(face_map, i+1) == face) {
                return i / 2;
        }
    }
    return -1;
}

// Set state of an outline button given a link and face
set_outline_link_face_state(string prefix, integer xlink, integer face, float alpha, integer enabled) {
    integer link = llListFindList(link_map, [prefix + (string)xlink]);
    if (link >= 0) {
        if (enabled) {
            llSetLinkPrimitiveParamsFast(link, [
                PRIM_COLOR, face, faceOnColor, alpha,
                PRIM_COLOR, face+1, buttonOnColor, alpha,
                PRIM_TEXTURE, face+1, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);
        } else {
            llSetLinkPrimitiveParamsFast(link, [
                PRIM_COLOR, face, <1.0, 1.0, 1.0>, alpha,
                PRIM_COLOR, face+1, offColor, alpha,
                PRIM_TEXTURE, face+1, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
            ]);
        }
    }
}

// Sets the texture and outline of an outline button using a map of button
// numbers to link/face
set_outline_button_state(list face_map, string prefix, integer index, integer enabled) {
    integer xlink = llList2Integer(face_map, (index * 2));
    integer face = llList2Integer(face_map, (index * 2) + 1);
    set_outline_link_face_state(prefix, xlink, face, 1.0, enabled);
}

// Sets the texture and outline of an outline button using a map of button
// numbers to link/face
set_outline_button_tex(list face_map, string prefix, integer index, string texture) {
    integer xlink = llList2Integer(face_map, (index * 2));
    integer face = llList2Integer(face_map, (index * 2) + 1);
    integer link = llListFindList(link_map, [prefix + (string)xlink]);
    if (link >= 0) {
        llSetLinkPrimitiveParamsFast(link, [
            PRIM_COLOR, face, <1.0, 1.0, 1.0>, 1.0,
            PRIM_TEXTURE, face, texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
            PRIM_COLOR, face+1, offColor, 1.0,
            PRIM_TEXTURE, face+1, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0
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
        link_map += [name];
        if (name == "fp0") {
            AnkleLockLink = i;
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
                    log(
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
            integer bx = (integer)(pos.x * 2);
            if (bx == 1) {
                rotation localRot = llList2Rot(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_ROT_LOCAL]), 0);
                llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_ROT_LOCAL, llEuler2Rot(<0.0, -PI_BY_TWO, 0.0>)*localRot]);
            } else {
                rotation localRot = llList2Rot(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_ROT_LOCAL]), 0);
                llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_ROT_LOCAL, llEuler2Rot(<0.0, PI_BY_TWO, 0.0>)*localRot]);
            }
            // Save current alpha rotation
            alpha_rot = llRot2Euler(llList2Rot(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_ROT_LOCAL]), 0));
        }
        else if (name == "alphabox" || name == "optionbox" || name == "skinbox") {
            // Ignore clicks on these
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
                set_alpha_section("neck", -1);
            }
            else if (bx == 4 || bx == 5) {
                if (by == 8) {
                    // head
                    set_alpha_section("head", -1);
                }
                else if (by == 6 || by == 7) {
                    // torso (except neck)
                    set_alpha_section("torso", -1);
                }
                else if (by > 1 && by < 6) {
                    // legs
                    set_alpha_section("legs", -1);
                }
                else if (by == 1) {
                    // feet
                    set_alpha_section("feet", -1);
                }
            }
            else if ((bx == 3 || bx == 6) && (by == 6 || by == 7)) {
                // arms
                set_alpha_section("arms", -1);
            }
            else if ((bx == 3 || bx == 6) && by == 5) {
                // hands
                set_alpha_section("hands", -1);
            }
        }
        else if (llGetSubString(name, 0, 4) == "alpha") {
            integer b = ((integer)llGetSubString(name, 5, -1));
            if (b == (integer)(num_alpha_buttons / 2) - 1 && face == 6) {
                // Hide all
                reset_alpha(0.0);
            }
            else if (b == num_alpha_buttons - 1 && face == 6) {
                // Show all
                reset_alpha(1.0);
            }
            else {
                set_alpha_section(llList2String(alpha_buttons, (b * 4) + (face >> 1)), -1);

                // Set button color
                vector face_color = llList2Vector(llGetLinkPrimitiveParams(link, [PRIM_NAME, PRIM_COLOR, face]), 1);
                set_outline_link_face_state("alpha", b, face, 1.0, (face_color == offColor));
            }
        }
        else if (llGetSubString(name, 0, 4) == "amode") {
            // Alpha Mode
            if (face == 2) {
                // Alpha Masking
                alpha_mode = PRIM_ALPHA_MODE_MASK;
                set_outline_link_face_state("amode", 0, 2, 1.0, TRUE);
                set_outline_link_face_state("amode", 0, 4, 1.0, FALSE);
            }
            else if (face == 4) {
                // Alpha Blending
                alpha_mode = PRIM_ALPHA_MODE_BLEND;
                set_outline_link_face_state("amode", 0, 2, 1.0, FALSE);
                set_outline_link_face_state("amode", 0, 4, 1.0, TRUE);
            }
            string cmd = llList2CSV(["ALPHAMODE", "all", -1, alpha_mode, mask_cutoff]);
            log(cmd);
            send(cmd);
        }
        else if (llGetSubString(name, 0, 1) == "sk") {
            // Skin appliers
            integer b = (integer)llGetSubString(name, 2, -1);
            // BoM button is hard coded to xlink 0, face 2
            if (b == 0 && face == 2) {
                // Skin Bakes on Mesh
                if (current_skin >= 0) {
                    set_outline_button_state(skin_button_faces, "sk", current_skin, FALSE);
                }
                current_skin = -1;
                set_outline_link_face_state("sk", b, face, 1.0, TRUE);
                llMessageLinked(LINK_THIS, LINK_RUTH_APP, llList2CSV(["skin", "bom"]), "");
            } else {
                integer index = lookup_button(skin_button_faces, b, face);
                if (index >= 0) {
                    if (current_skin >= 0) {
                        set_outline_button_state(skin_button_faces, "sk", current_skin, FALSE);
                    } else {
                        // BoM button is hard coded to xlink 0, face 2
                        set_outline_link_face_state("sk", 0, 2, 1.0, FALSE);
                    }
                    current_skin = index;
                    set_outline_button_state(skin_button_faces, "sk", index, TRUE);
                    llMessageLinked(
                        LINK_THIS,
                        LINK_RUTH_APP,
                        llList2CSV(["skin", (string)(index+1)]),
                        ""
                    );
                }
            }
        }
        else if (llGetSubString(name, 0, 2) == "eye") {
            // Eye appliers
            integer b = (integer)llGetSubString(name, 3, -1);
            // BoM button is hard coded to xlink 0, face 2
            if (b == 0 && face == 2) {
                // Eyes Bakes on Mesh
                if (current_eye >= 0) {
                    set_outline_button_state(eye_button_faces, "eye", current_eye, FALSE);
                }
                current_eye = -1;
                set_outline_link_face_state("eye", b, face, 1.0, TRUE);
                llMessageLinked(LINK_THIS, LINK_RUTH_APP, llList2CSV(["eyes", "bom"]), "");
           } else {
                integer index = lookup_button(eye_button_faces, b, face);
                if (index >= 0) {
                    if (current_eye >= 0) {
                        set_outline_button_state(eye_button_faces, "eye", current_eye, FALSE);
                    } else {
                        // BoM button is hard coded to xlink 0, face 2
                        set_outline_link_face_state("eye", 0, 2, 1.0, FALSE);
                    }
                    current_eye = index;
                    set_outline_button_state(eye_button_faces, "eye", index, TRUE);
                    llMessageLinked(
                        LINK_THIS,
                        LINK_RUTH_APP,
                        llList2CSV(["eyes", (string)(index+1)]),
                        ""
                    );
                }
            }
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
            // There are 4 buttons per link but 2 faces per button
            // All of the left buttons (hp0-hp2) come first then all
            // of the right buttons (hp3-hp5) but the animations
            // are L,R,L,R,... order.

            // TODO: add stop button??
            // Stop
            //hp_index = 0;

            // First get the delta for the R side buttons to overlap the left
            integer delta = ((integer)(b / 3) * 3);

            // Calculate the usual 8 face stride and add one for the right side
            // and another one because the list is 1-based
            hp_index = ((b - delta) * 8) + face + ((integer)(b / 3)) + 1;

            integer i;
            for (i=0; i<8; i+=2) {
                set_outline_link_face_state("hp", 0+delta, i, 0.0, FALSE);
                set_outline_link_face_state("hp", 1+delta, i, 0.0, FALSE);
                set_outline_link_face_state("hp", 2+delta, i, 0.0, FALSE);
            }
            set_outline_link_face_state("hp", b, face, 0.4, TRUE);

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
            // Handle alphas for touching the doll (that sounds baaaaaad...)
            list paramList = llGetLinkPrimitiveParams(link, [PRIM_NAME, PRIM_COLOR, face]);
            string primName = llList2String(paramList, 0);
            vector primColor = llList2Vector(paramList, 1);
            integer alphaVal;

            if (primColor == offColor) {
                alphaVal=0;
                llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, face, alphaOnColor, 1.0]);
            } else {
                alphaVal=1;
                llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, face, offColor, 1.0]);
            }
            send_csv(["ALPHA", primName, face, alphaVal]);
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
            else if (command == "SKIN_THUMBNAILS") {
                log("Loaded notecard: " + llList2String(cmdargs, 1));
                integer len = llGetListLength(skin_button_faces);
                integer i;
                // Walk returned thumbnail list
                for (i = 0; i < len; ++i) {
                    string tex = llList2String(cmdargs, i + 2);
                    if (tex == "") {
                        tex = TEXTURE_TRANSPARENT;
                    }
                    set_outline_button_tex(skin_button_faces, "sk", i, tex);
                }
                if (current_skin == -1) {
                    // Skin Bakes on Mesh
                    set_outline_link_face_state("sk", 0, 2, 1.0, TRUE);
                } else {
                    set_outline_button_state(skin_button_faces, "sk", current_skin, TRUE);
                }
            }
            else if (command == "EYE_THUMBNAILS") {
                log("Loaded notecard: " + llList2String(cmdargs, 1));
                integer len = llGetListLength(eye_button_faces);
                integer i;
                // Walk returned thumbnail list
                for (i = 0; i < len; ++i) {
                    string tex = llList2String(cmdargs, i + 2);
                    if (tex == "") {
                        tex = TEXTURE_TRANSPARENT;
                    }
                    set_outline_button_tex(eye_button_faces, "eye", i, tex);
                }
                if (current_eye == -1) {
                    // Eyes Bakes on Mesh
                    set_outline_link_face_state("eye", 0, 2, 1.0, TRUE);
                } else {
                    set_outline_button_state(eye_button_faces, "eye", current_eye, TRUE);
                }
            }
            else if (command == "NAIL_COLORS") {
                log("Loaded notecard: " + llList2String(cmdargs, 1));
                integer len = 10;
                integer i;
                // Walk returned mail color list
                for (i = 0; i < len; ++i) {
                    vector color = llList2Vector(cmdargs, i + 2);
                    if (color == ZERO_VECTOR) {
                        color = <1,1,1>;
                    }
                    // set_outline_button_tex(eye_button_faces, "eye", i, tex);
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
//                llOwnerSay("All finished: " + (string)len + llGetSubString(" animations",0,-1 - (len == 1))+" stopped.\n");
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
                            lFlag = TRUE; //We found the animation
                        }
                    }
                }
                while (nCounter < nTotCount && !lFlag);

                if (!lFlag) {
                    //Error messages - explanations of common problems a user might have if they assemble the HUD or add their own animations
                    if (nItemNo == 0) {
                        llOwnerSay("There's a problem.  First check to make sure you've loaded all of the hand animations in the HUD inventory.  There should be 24 of them.  If that's not the problem, you may have used an incorrect name for one of the prims making up the HUD.\n");
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
