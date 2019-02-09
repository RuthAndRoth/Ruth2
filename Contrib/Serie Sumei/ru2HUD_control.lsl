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

// The list stride is 3
integer num_tex = 3;

// These skin textures were uploaded to SL by seriesumei and are full-perm
// from Linda Kellie's set
// Set these to the full-perm texture UUIDs
list tex_1 = [
    // Female 1 shaved
    "aebcf034-b7b5-c682-5877-9e6037db9799",
    "64b3d1a1-1efb-99c8-e287-cff42f48c6a5",
    "0be30f69-6c17-358e-3419-38aeb92540ae",

    // Female 1 bushy
    "aebcf034-b7b5-c682-5877-9e6037db9799",
    "64b3d1a1-1efb-99c8-e287-cff42f48c6a5",
    "24b7eae1-403f-7346-b899-d34dde0f3d01",

    // Female 1 landing strip
    "aebcf034-b7b5-c682-5877-9e6037db9799",
    "64b3d1a1-1efb-99c8-e287-cff42f48c6a5",
    "acadebf3-c9d7-5f3a-320f-ed210d901699",

    // Female 1 extra bushy
    "aebcf034-b7b5-c682-5877-9e6037db9799",
    "64b3d1a1-1efb-99c8-e287-cff42f48c6a5",
    "3022144c-087a-1f0a-b6a3-36142cdf4b14"
];

list tex_2 = [
    // Female 2 shaved
    "c923f154-c1bf-ae41-d3f8-c1de78f44ca0",
    "83172ffd-2431-e629-7b19-f67e689288b5",
    "63d9c443-e815-070b-18e7-5db998af28e5",

    // Female 2 bushy
    "c923f154-c1bf-ae41-d3f8-c1de78f44ca0",
    "83172ffd-2431-e629-7b19-f67e689288b5",
    "ae90997b-5fd9-b047-acca-ac4e7adb3fa1",

    // Female 2 landing strip
    "c923f154-c1bf-ae41-d3f8-c1de78f44ca0",
    "83172ffd-2431-e629-7b19-f67e689288b5",
    "b0d6e00c-f14e-46aa-5ad8-7989e7b8ac53",

    // Female 2 extra bushy
    "c923f154-c1bf-ae41-d3f8-c1de78f44ca0",
    "83172ffd-2431-e629-7b19-f67e689288b5",
    "a5c97deb-dafd-385e-2883-e698e2ebac3c"
];

list tex_3 = [
    // Female 3 shaved
    "44d47200-8f4e-1220-2b74-2be1ee8e9ac5",
    "a276d547-8de0-8326-c603-49cbcc509cb8",
    "7ea4efe7-c0f9-3c56-3326-c87e5a2f19c3",

    // Female 3 bushy
    "44d47200-8f4e-1220-2b74-2be1ee8e9ac5",
    "a276d547-8de0-8326-c603-49cbcc509cb8",
    "b9690079-5734-c01b-5bc2-95c2e41c375f",

    // Female 3 landing strip
    "44d47200-8f4e-1220-2b74-2be1ee8e9ac5",
    "a276d547-8de0-8326-c603-49cbcc509cb8",
    "8421cf09-bb4a-9ba5-8087-911746b00ced"
];

list tex_4 = [
    // Female 4 shaved
    "096ee6f2-717b-fec3-4ed8-39f636fec964",
    "a3243796-87eb-78a7-cbe1-15a29c78ca5a",
    "7ea4efe7-c0f9-3c56-3326-c87e5a2f19c3",

    // Female 4 bushy
    "096ee6f2-717b-fec3-4ed8-39f636fec964",
    "a3243796-87eb-78a7-cbe1-15a29c78ca5a",
    "a656222d-73e2-2663-5472-8ccd85d3adf5",

    // Female 4 landing strip
    "096ee6f2-717b-fec3-4ed8-39f636fec964",
    "a3243796-87eb-78a7-cbe1-15a29c78ca5a",
    "225c1668-b82d-aea1-40fb-1e421f37ab11"
];

list tex_5 = [
    // Female 5 shaved
    "5dd60e66-f8a3-6dcb-50c6-23e52939e86b",
    "e9af3504-70e5-80c7-d332-7fc3272ab23a",
    "68f829d1-d736-269b-1577-e8b768795638",

    // Female 5 bushy
    "5dd60e66-f8a3-6dcb-50c6-23e52939e86b",
    "e9af3504-70e5-80c7-d332-7fc3272ab23a",
    "b2b1a848-377b-031c-d5c4-fd30b49c4fb3",

    // Female 5 landing strip
    "5dd60e66-f8a3-6dcb-50c6-23e52939e86b",
    "e9af3504-70e5-80c7-d332-7fc3272ab23a",
    "d2062972-ee1b-4826-d35e-e00eb5b55320"
];

list tex_6 = [
    // Female 6 shaved
    "374ec125-5968-33a9-eca3-c9b9ee3cb262",
    "cc92325a-aa11-d6c1-6c46-db2ea4a56885",
    "9ef029ff-65fc-76f4-432d-f013c4a593c5",

    // Female 6 bushy
    "374ec125-5968-33a9-eca3-c9b9ee3cb262",
    "cc92325a-aa11-d6c1-6c46-db2ea4a56885",
    "8e83a25f-bef9-2724-943f-1aecbc79d3b4",

    // Female 6 landing strip
    "374ec125-5968-33a9-eca3-c9b9ee3cb262",
    "cc92325a-aa11-d6c1-6c46-db2ea4a56885",
    "365df245-4b69-8e18-a315-bc6420db5798"
];

list tex_7 = [
    // Female 7 shaved
    "31b85c7e-5294-76ec-b83b-854581240e74",
    "c40b8624-8cd0-d877-4fab-ce96e31ae446",
    "79f1c337-8549-5d4e-cba8-842512add3b8",

    // Female 7 bushy
    "31b85c7e-5294-76ec-b83b-854581240e74",
    "c40b8624-8cd0-d877-4fab-ce96e31ae446",
    "1a15673d-8d0a-1fa3-a17a-6b284023dcce",

    // Female 7 shaved
    "31b85c7e-5294-76ec-b83b-854581240e74",
    "c40b8624-8cd0-d877-4fab-ce96e31ae446",
    "d2094f99-48f0-0aab-8b50-eebd09da5fca"
];

list tex_8 = [
    // CMFF Template
    "0585d463-b6e4-2c6c-46a3-19aa9c512a3c",
    "fb9bbbc9-dadf-026f-bf87-7937ec470f5d",
    "4f0aa9d0-1591-fd43-bae3-7e11a6c9c45d"
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

vector MIN_BAR = <-PI_BY_TWO, 0.0, 0.0>;
vector ALPHA_HUD = <PI, 0.0, 0.0>;
vector OPTION_HUD = <TWO_PI, 0.0, 0.0>;
vector SKIN_HUD = <PI_BY_TWO, 0.0, 0.0>;
vector alpha_rot;
vector last_rot;

integer VERBOSE = FALSE;

// Memory limit
integer MEM_LIMIT = 32000;

integer r2channel;
integer visible_fingernails = 0;

log(string msg) {
    if (VERBOSE == 1) {
        llOwnerSay(msg);
    }
}

send(string msg) {
    llSay(r2channel, msg);
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

apply_texture(list tex) {
    send("TEXTURE,head," + llList2String(tex, 0));
    send("TEXTURE,upper," + llList2String(tex, 1));
    send("TEXTURE,lower," + llList2String(tex, 2));
}

// Literal API for TEXTURE v2 command
texture_v2(string name, string tex, integer face, vector color) {
    string cmd = llList2CSV(["TEXTURE", name, tex, face, color]);
    log(cmd);
    send(cmd);
}

default {
    state_entry() {
        // Initialize attach state
        last_attach = llGetAttached();
        log("state_entry() attached=" + (string)last_attach);

        r2channel = keyapp2chan(APP_ID);
        llListen(r2channel+1, "", "", "");
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

        log("Free memory " + (string)llGetFreeMemory() + "  Limit: " + (string)MEM_LIMIT);
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
                llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_ROT_LOCAL, llEuler2Rot(<0.0,0.0,-PI/2>)*localRot]);
            } else {
                rotation localRot = llList2Rot(llGetLinkPrimitiveParams(LINK_ROOT, [PRIM_ROT_LOCAL]), 0);
                llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_ROT_LOCAL, llEuler2Rot(<0.0,0.0,PI/2>)*localRot]);
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
        else if (llGetSubString(name, 0, 3) == "skin") {
            // Skin appliers
            integer b = (integer)llGetSubString(name, 4, -1);
            if (b == 1 && face == 0) {
                integer i = ((1 - 1) * num_tex);
                apply_texture(llList2List(tex_1, i, i+num_tex-1));
            }
            else if (b == 1 && face == 2) {
                integer i = ((2 - 1) * num_tex);
                apply_texture(llList2List(tex_1, i, i+num_tex-1));
            }
            else if (b == 1 && face == 4) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_1, i, i+num_tex-1));
            }
            else if (b == 2 && face == 0) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_2, i, i+num_tex-1));
            }
            else if (b == 2 && face == 2) {
                integer i = ((2 - 1) * num_tex);
                apply_texture(llList2List(tex_2, i, i+num_tex-1));
            }
            else if (b == 2 && face == 4) {
                integer i = ((1 - 1) * num_tex);
                apply_texture(llList2List(tex_2, i, i+num_tex-1));
            }
            else if (b == 3 && face == 0) {
                integer i = ((1 - 1) * num_tex);
                apply_texture(llList2List(tex_3, i, i+num_tex-1));
            }
            else if (b == 3 && face == 2) {
                integer i = ((2 - 1) * num_tex);
                apply_texture(llList2List(tex_3, i, i+num_tex-1));
            }
            else if (b == 3 && face == 4) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_3, i, i+num_tex-1));
            }
            else if (b == 4 && face == 0) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_4, i, i+num_tex-1));
            }
            else if (b == 4 && face == 2) {
                integer i = ((2 - 1) * num_tex);
                apply_texture(llList2List(tex_4, i, i+num_tex-1));
            }
            else if (b == 4 && face == 4) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_4, i, i+num_tex-1));
            }
            else if (b == 5 && face == 0) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_5, i, i+num_tex-1));
            }
            else if (b == 5 && face == 2) {
                integer i = ((2 - 1) * num_tex);
                apply_texture(llList2List(tex_5, i, i+num_tex-1));
            }
            else if (b == 5 && face == 4) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_5, i, i+num_tex-1));
            }
            else if (b == 6 && face == 0) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_6, i, i+num_tex-1));
            }
            else if (b == 6 && face == 2) {
                integer i = ((2 - 1) * num_tex);
                apply_texture(llList2List(tex_6, i, i+num_tex-1));
            }
            else if (b == 6 && face == 4) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_6, i, i+num_tex-1));
            }
            else if (b == 7 && face == 0) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_7, i, i+num_tex-1));
            }
            else if (b == 7 && face == 2) {
                integer i = ((2 - 1) * num_tex);
                apply_texture(llList2List(tex_7, i, i+num_tex-1));
            }
            else if (b == 7 && face == 4) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_7, i, i+num_tex-1));
            }
            else if (b == 3 && face == 0) {
                integer i = ((3 - 1) * num_tex);
                apply_texture(llList2List(tex_3, i, i+num_tex-1));
            }
            else if (b == 8) {
                integer i = ((1 - 1) * num_tex);
                apply_texture(llList2List(tex_8, i, i+num_tex-1));
            }
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
        if (change & CHANGED_OWNER) {
            llResetScript();
        }
    }
}
