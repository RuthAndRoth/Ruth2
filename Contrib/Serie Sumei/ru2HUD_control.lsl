// Ruth 2.0 HUD Controller
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

// The command button list is:
// <button-name> :: <prim-name> :: <link-number> :: <face-number>
// Note that <link-number> is no longer used, replaced with the index in
// prim_map that is built at script startup, thus relieving us
// of the perils of not liking the HUD in the right order

list commandButtonList = [
    "reset",

    "backupper::backupper::30::-1",
    "backlower::backlower::31::-1",

    "chest::chest::32::-1",
    "breasts::breastright::33::-1",
    "breasts::breastleft::34::-1",
    "nipples::breastright::33::0",
    "nipples::breastleft::34::0",
    "belly::belly::35::-1",

    "armsupper::armright::36::0",
    "armsupper::armright::36::1",
    "armsupper::armright::36::2",
    "armsupper::armright::36::3",
    "armsupper::armleft::37::0",
    "armsupper::armleft::37::1",
    "armsupper::armleft::37::2",
    "armsupper::armleft::37::3",

    "armslower::armright::36::4",
    "armslower::armright::36::5",
    "armslower::armright::36::6",
    "armslower::armright::36::7",
    "armslower::armleft::37::4",
    "armslower::armleft::37::5",
    "armslower::armleft::37::6",
    "armslower::armleft::37::7",

    "armsfull::armright::36::-1",
    "armsfull::armleft::37::-1",

    "hands::hands::38::-1",

    "buttcrotch::pelvisback::11::7",
    "buttcrotch::pelvisfront::12::5",
    "buttcrotch::pelvisfront::12::6",
    "buttcrotch::pelvisfront::12::7",
    "pelvis::pelvisback::11::-1",
    "pelvis::pelvisfront::12::-1",

    "legsupper::legright1::13::-1",
    "legsupper::legright2::14::-1",
    "legsupper::legright3::15::-1",
    "legsupper::legleft1::21::-1",
    "legsupper::legleft2::22::-1",
    "legsupper::legleft3::23::-1",

    "knees::legright4::16::-1",
    "knees::legright5::17::-1",
    "knees::legleft4::24::-1",
    "knees::legleft5::25::-1",

    "legslower::legright6::18::-1",
    "legslower::legright7::19::-1",
    "legslower::legright8::20::-1",
    "legslower::legleft6::26::-1",
    "legslower::legleft7::27::-1",
    "legslower::legleft8::28::-1",

    "legsfull::legright1::13::-1",
    "legsfull::legright2::14::-1",
    "legsfull::legright3::15::-1",
    "legsfull::legright4::16::-1",
    "legsfull::legright5::17::-1",
    "legsfull::legright6::18::-1",
    "legsfull::legright7::19::-1",
    "legsfull::legright8::20::-1",
    "legsfull::legleft1::21::-1",
    "legsfull::legleft2::22::-1",
    "legsfull::legleft3::23::-1",
    "legsfull::legleft4::24::-1",
    "legsfull::legleft5::25::-1",
    "legsfull::legleft6::26::-1",
    "legsfull::legleft7::27::-1",
    "legsfull::legleft8::28::-1",

    "feet::feet::29::-1",
    "ankles::feet::29::0",
    "bridges::feet::29::1",
    "bridges::feet::29::2",
    "toecleavages::feet::29::3",
    "toes::feet::29::4",
    "soles::feet::29::5",
    "heels::feet::29::6"
];

list fingernails = [
    "fingernailsshort::fingernails",
    "fingernailsmedium::fingernails",
    "fingernailslong::fingernails",
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
integer MEM_LIMIT = 32000;

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

resetallalpha() {
    integer i;

    // Reset body and HUD doll
    list seen = [];
    integer x = llGetListLength(commandButtonList) + 1;
    for (; i < x; ++i) {
        string dataString = llList2String(commandButtonList, i);
        list stringList = llParseString2List(dataString, ["::"], []);
        string name = llList2String(stringList, 1);
        if (llListFindList(seen, [name]) < 0) {
            seen += [name];
            set_alpha(name, -1, 1.0);
        }
    }

    // Reset HUD buttons
    for(i=1; i <= 8; ++i) {
        string name = "buttonbar" + (string)i;
        set_alpha(name, -1, 1.0);
    }
}

colorDoll(string commandFilter, integer alphaVal) {
    integer i;
    integer x = llGetListLength(commandButtonList)+1;
    for (; i < x; ++i) {
        string dataString = llList2String(commandButtonList,i);
        list stringList = llParseString2List(dataString, ["::"], []);
        string command = llList2String(stringList,0);

        if (command == commandFilter) {
            string name = llList2String(stringList, 1);
            // Set color for all matching link names
            integer face = llList2Integer(stringList, 3);
            set_alpha(name, face, alphaVal);
        }
    }
}

// Put thumbnails from the applier onto the HUD buttons
// Assumes the 2x1 mesh button and the square face 4
set_skin_thumbnails(list names) {
    integer i;
    for (; i < llGetListLength(names); ++i) {
        string texture = llList2String(names, i);
        string prim_name = "skin" + (string)i;
        integer link = llListFindList(prim_map, [prim_name]);
        log("h: link=" + (string)link);
        if (link >= 0) {
            // face == 4 is specific to these buttons
            llSetLinkTexture(link, texture, 4);
        }
    }
}

doButtonPress(list buttons, integer link, integer face) {
    string commandButton = llList2String(buttons, face);
    list paramList = llGetLinkPrimitiveParams(link, [PRIM_NAME, PRIM_COLOR, face]);
    string primName = llList2String(paramList, 0);
    vector primColor = llList2Vector(paramList, 1);
    string name = llGetLinkName(link);

    integer alphaVal;
    integer i;
    log("doButtonPress(): " + primName + " " + (string)link + " " + (string)face);
    for (; i < num_links; ++i) {
        // Set color for all matching link names
        if (llList2String(prim_map, i) == name) {
            if (primColor == offColor) {
                alphaVal = 0;
                llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, face, buttonOnColor, 1.0]);
            } else {
                alphaVal = 1;
                llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, face, offColor, 1.0]);
            }
        }
    }
    colorDoll(commandButton, alphaVal);
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

// Convert face + position to a button name for 3 choices
string map_button_3(integer face, integer x) {
    string ret;
    if (face == 0 && x == 0) {
        ret = "1";
    }
    else if (face == 0 && x == 1) {
        ret = "2";
    }
    else if (face == 2) {
        ret = "3";
    }
    else if (face == 4) {
        ret = "1";
    }
    return ret;
}

// Convert face + position to a button name for 4 choices
string map_button_4(integer face, integer x) {
    string ret;
    if (face == 0 && x == 0) {
        ret = "1";
    }
    else if (face == 0 && x == 1) {
        ret = "2";
    }
    else if (face == 2 && x == 0) {
        ret = "3";
    }
    else if (face == 2 && x == 1) {
        ret = "4";
    }
    else if (face == 4) {
        ret = "1";
    }
    return ret;
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
        prim_map += [llList2String(p, 0)];
    }

    alpha_rot = ALPHA_HUD;
    last_rot = MIN_BAR;

    // Read skin notecard
    log("Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);

    haz_xtea = can_haz_script(XTEA_NAME);
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

            if (bx == 2 || bx == 3) {
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
            else if (bx == 8) {
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
            else if (bx == 9) {
                log("DETACH!");
                llRequestPermissions(llDetectedKey(0), PERMISSION_ATTACH);
            }
        }
        else if (name == "buttonbar1" || name == "buttonbar5") {
            list buttonList = [
                    "reset",
                    "chest",
                    "breasts",
                    "nipples",
                    "belly",
                    "backupper",
                    "backlower",
                    "armsupper"
                    ];
            if(face == 0) {
                resetallalpha();
            } else {
                doButtonPress(buttonList, link, face);
            }
        }
        else if (name == "buttonbar2" || name == "buttonbar6") {
            list buttonList = [
                    "armslower",
                    "armsfull",
                    "hands",
                    "buttcrotch",
                    "pelvis",
                    "legsupper",
                    "knees",
                    "legslower"
                    ];
            doButtonPress(buttonList, link, face);
        }
        else if (name == "buttonbar3" || name == "buttonbar7") {
            list buttonList = [
                    "legsfull",
                    "feet",
                    "ankles",
                    "heels",
                    "bridges",
                    "toecleavages",
                    "toes",
                    "soles"
                    ];
            doButtonPress(buttonList, link, face);
        }
        else if (name == "buttonbar4" || name == "buttonbar8") {
            list buttonList = [
                    "--",
                    "--",
                    "--",
                    "--",
                    "--",
                    "--",
                    "savealpha",
                    "loadalpha"
                    ];
            string commandButton = llList2String(buttonList,face);
            llOwnerSay("Saving and loading alpha is not yet implemented!");
        }
        else if (name == "backboard") {
            // ignore click on backboard
        }
        else if (name == "bom") {
            // Bakes on Mesh
            apply_texture("sb_81");
        }
        else if (llGetSubString(name, 0, 3) == "skin") {
            // Skin appliers
            integer b = (integer)llGetSubString(name, 4, -1);
            string sname = "sb_" + (string)b + map_button_3(face, 0);
            apply_texture(sname);
        }
        else if (llGetSubString(name, 0, 2) == "fnc") {
            // Fingernail color
            integer b = (integer)llGetSubString(name, 3, -1);
            if (b >= 0 && b <= 9) {
                texture_v2(
                    "fingernails",
                    "",
                    ALL_SIDES,
                    llList2Vector(fingernail_colors, b)
                );
            }
        }
        else if (llGetSubString(name, 0, 1) == "fn") {
            // Fingernail shape
            list nail_types = [
                "fingernailsshort",
                "fingernailsmedium",
                "fingernailslong",
                "fingernailspointed",
                "fingernailsnone"
            ];
            integer b = (integer)llGetSubString(name, 2, -1);
            if (b >= 0 && b <= 4) {
                integer num = llGetListLength(nail_types);
                integer i;
                visible_fingernails = b;
                for (; i < num; ++i) {
                    if (i == b) {
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
            if (b >= 0 && b <= 9) {
                texture_v2(
                    "toenails",
                    "",
                    ALL_SIDES,
                    llList2Vector(fingernail_colors, b)
                );
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
        log("h: num: " + (string)number + "msg: " + message);
        if (number == LINK_RUTH_HUD) {
            // <command>,<arg1>,...
            list cmdargs = llCSV2List(message);
            string command = llToUpper(llList2String(cmdargs, 0));
            if (command == "STATUS") {
                log("Loaded notecard: " + llList2String(cmdargs, 1));
            }
            else if (command == "THUMBNAILS") {
                log("Loaded notecard: " + llList2String(cmdargs, 1));
                set_skin_thumbnails(llList2List(cmdargs, 1, -1));
            }
        }
    }

    run_time_permissions(integer perm) {
        if (perm & PERMISSION_ATTACH) {
            llDetachFromAvatar();
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
