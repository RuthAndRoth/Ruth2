// ru2HUD_control.lsl - Ruth2 v3 HUD Controller
// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright 2017 Shin Ingen
// Copyright 2019 Serie Sumei

// v3.0 02Apr2020 <seriesumei@avimail.org> - Based on ss-r from Controb/Serie Sumei
// v3.1 02Apr2020 <seriesumei@avimail.org> - New alpha HUD button order, fix prim mapping

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
    "head", -1, "head", 0,
    "chest", -1, "chest", 1,
    "breastright", -1, "breasts", 1,
    "breastleft", -1, "breasts", 1,
    "breastright", 0, "nipples", 1,
    "breastleft", 0, "nipples", 1,
    "belly", -1, "belly", 1,

    "backupper", -1, "backupper", 1,
    "backlower", -1, "backlower", 1,

    "armright", 0, "armsupper", 1,
    "armright", 1, "armsupper", 1,
    "armright", 2, "armsupper", 1,
    "armright", 3, "armsupper", 1,
    "armleft", 0, "armsupper", 1,
    "armleft", 1, "armsupper", 1,
    "armleft", 2, "armsupper", 1,
    "armleft", 3, "armsupper", 1,
    "armright", 4, "armslower", 1,
    "armright", 5, "armslower", 1,
    "armright", 6, "armslower", 1,
    "armright", 7, "armslower", 1,
    "armleft", 4, "armslower", 1,
    "armleft", 5, "armslower", 1,
    "armleft", 6, "armslower", 1,
    "armleft", 7, "armslower", 1,

    "armright", -1, "arms", 1,
    "armleft", -1, "arms", 1,
    "hands", -1, "hands", 1,
    "fingernails", -1, "hands", 11,

    "pelvisback", 7, "crotch", 2,
    "pelvisfront", 5, "crotch", 2,
    "pelvisfront", 6, "crotch", 2,
    "pelvisfront", 7, "crotch", 2,
    "pelvisback", -1, "pelvis", 2,
    "pelvisfront", -1, "pelvis", 2,

    "legright1", -1, "legsupper", 2,
    "legright2", -1, "legsupper", 2,
    "legright3", -1, "legsupper", 2,
    "legleft1", -1, "legsupper", 2,
    "legleft2", -1, "legsupper", 2,
    "legleft3", -1, "legsupper", 2,

    "legright4", -1, "knees", 2,
    "legright5", -1, "knees", 2,
    "legleft4", -1, "knees", 2,
    "legleft5", -1, "knees", 2,

    "legright6", -1, "legslower", 2,
    "legright7", -1, "legslower", 2,
    "legright8", -1, "legslower", 2,
    "legleft6", -1, "legslower", 2,
    "legleft7", -1, "legslower", 2,
    "legleft8", -1, "legslower", 2,

    "legright1", -1, "legsfull", 2,
    "legright2", -1, "legsfull", 2,
    "legright3", -1, "legsfull", 2,
    "legright4", -1, "legsfull", 2,
    "legright5", -1, "legsfull", 2,
    "legright6", -1, "legsfull", 2,
    "legright7", -1, "legsfull", 2,
    "legright8", -1, "legsfull", 2,
    "legleft1", -1, "legsfull", 2,
    "legleft2", -1, "legsfull", 2,
    "legleft3", -1, "legsfull", 2,
    "legleft4", -1, "legsfull", 2,
    "legleft5", -1, "legsfull", 2,
    "legleft6", -1, "legsfull", 2,
    "legleft7", -1, "legsfull", 2,
    "legleft8", -1, "legsfull", 2,

    "feet", -1, "feet", 2,
    "feet", 0, "ankles", 2,
    "feet", 1, "heels", 2,
    "feet", 2, "bridges", 2,
    "feet", 3, "toecleavages", 2,
    "feet", 4, "soles", 2,
    "feet", 5, "toes", 2,
    "toenails", -1, "feet", 12
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

// Set the alpha val of all links matching name
set_alpha(string name, integer face, float alpha) {
    integer link;
    for (; link < num_links; ++link) {
        // Set color for all matching link names
        if (llList2String(prim_map, link) == name) {
            // Reset links that appear in the list of body parts
            send_csv(["ALPHA", name, face, alpha]);
            if (alpha == 0) {
                llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, face, alphaOnColor, 1.0]);
            } else {
                llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, face, offColor, 1.0]);
            }
        }
    }
}

set_alpha_group(list buttons, integer button_link, integer button_face) {
    string button_name = llList2String(buttons, button_face);
    list paramList = llGetLinkPrimitiveParams(button_link, [PRIM_NAME, PRIM_COLOR, button_face]);
    vector face_color = llList2Vector(paramList, 1);

    // Toggle the group button state
    integer alphaVal;
    log("set_alpha_group(): button: " + button_name + " link=" + (string)button_link + " face=" + (string)button_face);
    if (face_color == offColor) {
        alphaVal = 0;
        llSetLinkPrimitiveParamsFast(button_link, [PRIM_COLOR, button_face, buttonOnColor, 1.0]);
    } else {
        alphaVal = 1;
        llSetLinkPrimitiveParamsFast(button_link, [PRIM_COLOR, button_face, offColor, 1.0]);
    }

    // Set doll face state
    integer i;
    list groups = llList2ListStrided(llDeleteSubList(element_map, 0, 1), 0, -1, element_stride);
    integer len = llGetListLength(groups);
    for (i = 0; i <= len; ++i) {
        if (llList2String(groups, i) == button_name) {
            // process matching group entry
            string prim_name = llList2String(element_map, i * element_stride);
            integer doll_face = llList2Integer(element_map, (i * element_stride) + 1);
            set_alpha(prim_name, doll_face, alphaVal);
        }
    }
}

reset_alpha(float alpha) {
    // Reset body and HUD doll
    list seen = [];
    list groups = llList2ListStrided(llDeleteSubList(element_map, 0, 1), 0, -1, element_stride);
    integer len = llGetListLength(groups);
    integer i;
    for (i = 0; i <= len; ++i) {
        string prim_name = llList2String(element_map, i * element_stride);
        if (llListFindList(seen, [prim_name]) < 0) {
            seen += [prim_name];
            set_alpha(prim_name, -1, alpha);
        }
    }

    // Reset HUD buttons
    for(i = 0; i <= 7; ++i) {
        set_alpha("buttonbar" + (string)i, -1, alpha);
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
        else if (name == "buttonbar1" || name == "buttonbar5") {
            list buttonList = [
                    "head",
                    "chest",
                    "breasts",
                    "nipples",
                    "belly",
                    "backupper",
                    "backlower",
                    "arms"
                    ];
            set_alpha_group(buttonList, link, face);
        }
        else if (name == "buttonbar2" || name == "buttonbar6") {
            list buttonList = [
                    "armsupper",
                    "armslower",
                    "hands",
                    "fingernails",
                    "crotch",
                    "pelvis",
                    "",
                    "hideall"
                    ];
            if(face == 7) {
                reset_alpha(0.0);
            } else {
                set_alpha_group(buttonList, link, face);
            }
        }
        else if (name == "buttonbar3" || name == "buttonbar7") {
            list buttonList = [
                    "legs",
                    "legsupper",
                    "knees",
                    "legslower",
                    "feet",
                    "ankles",
                    "bridges",
                    "heels"
                    ];
            set_alpha_group(buttonList, link, face);
        }
        else if (name == "buttonbar4" || name == "buttonbar8") {
            list buttonList = [
                    "soles",
                    "toecleavage",
                    "toes",
                    "toenails",
                    "--",
                    "--",
                    "--",
                    "showall"
                    ];
            if(face == 7) {
                reset_alpha(1.0);
            } else {
                set_alpha_group(buttonList, link, face);
            }
        }
        else if (name == "backboard") {
            // ignore click on backboard
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
        else if (name == "optionbox") {
            // Do nothing here
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
