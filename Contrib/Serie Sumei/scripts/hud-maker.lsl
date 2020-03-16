//*********************************************************************************
//**   This program is free software: you can redistribute it and/or modify
//**   it under the terms of the GNU Affero General Public License as
//**   published by the Free Software Foundation, either version 3 of the
//**   License, or (at your option) any later version.
//**
//**   This program is distributed in the hope that it will be useful,
//**   but WITHOUT ANY WARRANTY; without even the implied warranty of
//**   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//**   GNU Affero General Public License for more details.
//**
//**   You should have received a copy of the GNU Affero General Public License
//**   along with this program.  If not, see <https://www.gnu.org/licenses/>
//*********************************************************************************

// ss-c 31Dec2018 <seriesumei@avimail.org> - Combined HUD
// ss-d 03Jan2019 <seriesumei@avimail.org> - Add skin panel
// ss-e 10Feb2019 <seriesumei@avimail.org> - Add option panel
// ss-f 31Mar2019 <seriesumei@avimail.org> - Fix textures for SL vs OpenSim
// ss-g 02Apr2019 <seriesumei@avimail.org> - Add skin buttons and tweak textures
// ss-o 15Mar2020 <seriesumei@avimail.org> - Catch up to current state

// This builds a multi-paned HUD for Ruth/Roth that includes the existing
// alpha HUD mesh and adds panes for a different skin applier than Shin's
// and an Options pane that has fingernail shape/color and toenail
// color buttons as well as hand and foot pose buttons.
//
// To build the HUD from scratch you will need to:
// * Upload or obtain via whatever means the Alpha HUD mesh and the 'doll'
//   mesh.  This script will throw an error if you start with a pre-linked
//   alpha HUD but it should work anyway.  To prepare the alpha hud and doll
//   meshes:
//   * Remove all scripts
//   * Make sure that the 'rotatebar' link is the root of the HUD linkset and
//     the 'chest' link is the root of the doll linkset.  Thse are used for
//     positioning, even so SL gets the positioning wrong compares to OpenSim.
// * Create a new empty box prim named 'Object' and take a copy of it into
//   inventory
// * Copy the folloing objects into the new box's inventory on the ground:
//   * the new box from inventory created above and name it 'Object'
//   * the alpha HUD mesh and name it 'alpha-hud'
//   * if the doll mes is not already linked into the alpha HUD linkset copy
//     it and name it 'doll'
//   * the button meshes named '5x1-s_button', '6x1_button' and '4x2_button'
//   * this script
// * Light fuse (touch the box prim) and get away, the new HUD will be
//   assembled around the box prim which will become the root prim of the HUD.
// * The alpha HUD and the doll will not be linked as they may need size
//   and/or position adjustments depending on how your mesh is linked.  Since
//   they are both linksets you do not want to link them to the main HUD until
//   you are very satisfied with their position.  Then link them and rejoice.
// * Rename the former root prim of the alpha HUD mesh, if it was the rotation
//   bar at the bottom name it 'rotatebar'.  Remove any script if it is still
//   present.
// * Rename the former root prim of the doll according to the usual doll link
//   names.
// * Make any position and size adjustments as necessary to the alpha HUD mesh
//   and doll, then link them both to the new HUD root prim.  Make sure that
//   the center square HUD prim is last so it remains the root of the linkset.
// * Remove this script from the HUD root prim and copy in the HUD script(s).
// * The other objects are also not needed any longer in the root prim and
//   can be removed.

vector build_pos;
integer link_me = FALSE;
integer FINI = FALSE;
integer counter = 0;

key bar_texture;
key hud_texture;
key options_texture;
key fingernails_shape_texture;

vector bar_size = <0.4, 0.4, 0.03>;
vector color_button_size = <0.01, 0.145, 0.025>;
vector shape_button_size = <0.01, 0.295, 0.051>;

// Spew debug info
integer VERBOSE = FALSE;

// Hack to detect Second Life vs OpenSim
// Relies on a bug in llParseString2List() in SL
// http://grimore.org/fuss/lsl/bugs#splitting_strings_to_lists
integer is_SL() {
    string sa = "12999";
//    list OS = [1,2,9,9,9];
    list SL = [1,2,999];
    list la = llParseString2List(sa, [], ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
    return (la == SL);
}

// The four textures used in the HUD referenced below are included in the repo:
// bar_texture: ruth2 v3 hud header.png
// hud_texture: ruth2 v3 hud gradient.png
// options_texture: ruth2 v3 hud options.png
// fingernails_shape_texture: ruth 2.0 hud fingernails shape.png

get_textures() {
    if (is_SL()) {
        // Textures in SL
        // The textures listed are full-perm uploaded by seriesumei Resident
        bar_texture = "c74e2f3e-d493-47e7-0042-58c240802c8a";
        hud_texture = "76dbff9c-c2fd-ffe9-a37f-cb9e42f722fe";
        options_texture = "9dfaebd8-5676-fb92-6018-5f52dd903d01";
        fingernails_shape_texture = "fb6ee827-3c3e-99a8-0e33-47015c0845a9";
    } else {
        if (osGetGridName() == "OSGrid") {
            // Textures in OSGrid
            // TODO: Bad assumption that OpenSim == OSGrid, how do we detect
            //       which grid?  osGetGridName() is an option but does not
            //       compile in SL so editing the script would stll be required.
            //       Maybe we don't care too much about that?
            // The textures listed are full-perm uploaded by serie sumei to OSGrid
            bar_texture = "165ecebe-b9f2-4633-b547-2f55af868f82";
            hud_texture = "f38beb3f-6f3c-4072-b37e-1ee57f6e9ee4";
            options_texture = "9234be05-9ff4-4cb3-bcdb-4115f7e32ff6";
            fingernails_shape_texture = "fe777245-4fa2-4834-b794-0c29fa3e1fcf";
        } else {
            log("OpenSim detected but grid " + osGetGridName() + " unknown, using blank textures");
            bar_texture = TEXTURE_BLANK;
            hud_texture = TEXTURE_BLANK;
            options_texture = TEXTURE_BLANK;
            fingernails_shape_texture = TEXTURE_BLANK;
        }
    }
}

log(string txt) {
    if (VERBOSE) {
        llOwnerSay(txt);
    }
}

rez_object(string name, vector delta, vector rot) {
    vector build_pos = llGetPos();
    build_pos += delta;;

    log("Rezzing " + name);
    llRezObject(
        name,
        build_pos,
        <0.0, 0.0, 0.0>,
        llEuler2Rot(rot),
        0
    );
}

configure_bar(string name, float offset_y) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_TEXTURE, ALL_SIDES, bar_texture, <1.0, 0.08, 0.0>, <0.0, offset_y, 0.0>, 0.0,
        PRIM_TEXTURE, 0, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
        PRIM_TEXTURE, 5, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
        PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
        PRIM_SIZE, bar_size
    ]);
}

configure_color_buttons(string name) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
        PRIM_COLOR, 3, <0.3, 0.3, 0.3>, 1.00,
        PRIM_COLOR, 4, <0.6, 0.6, 0.6>, 1.00,
        PRIM_SIZE, color_button_size
    ]);
}

default {
    touch_start(integer total_number) {
        get_textures();
        counter = 0;
        // set up root prim
        log("Configuring root");
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
            PRIM_NAME, "HUD base",
            PRIM_SIZE, <0.1, 0.1, 0.1>,
            PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <0,0,0>, <0.0, 0.455, 0.0>, 0.0,
            PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00
        ]);

        // See if we'll be able to link to trigger build
        llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
    }

    run_time_permissions(integer perm) {
        // Only bother rezzing the object if will be able to link it.
        if (perm & PERMISSION_CHANGE_LINKS) {
            // log("Rezzing south");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.16, -0.5>, <0.0, 0.0, 0.0>);
        } else {
            llOwnerSay("unable to link objects, aborting build");
        }
    }

    object_rez(key id) {
        counter++;
        integer i = llGetNumberOfPrims();
        log("counter="+(string)counter);

        if (link_me) {
            llCreateLink(id, TRUE);
            link_me = FALSE;
        }

        if (counter == 1) {
            configure_bar("minbar", 0.440);
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_TEXTURE, 2, bar_texture, <0.2, 0.08, 0.0>, <-0.4, 0.437, 0.0>, 0.0,
                PRIM_TEXTURE, 4, bar_texture, <0.2, 0.08, 0.0>, <-0.4, 0.437, 0.0>, 0.0,
                PRIM_SIZE, <0.40, 0.08, 0.03>
            ]);

            // log("Rezzing east");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.5, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 2) {
            configure_bar("optionbar", 0.062);

            // log("Rezzing north");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.5>, <PI, 0.0, 0.0>);
        }
        else if (counter == 3) {
            configure_bar("skinbar", 0.187);

            // log("Rezzing west");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.5, 0.0>, <PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 4) {
            configure_bar("alphabar", 0.312);

            log("Rezzing option HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.6894, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 5) {
            log("Configuring option HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "optionbox",
                PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 0.7, 0.0>, <0.0, 0.15, 0.0>, 0.0,
                PRIM_TEXTURE, 4, options_texture, <1.0, 0.7, 0.0>, <0.0, 0.15, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, <0.4, 0.4, 0.34985>
            ]);

            log("Rezzing skin HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.7147>, <PI, 0.0, 0.0>);
        }
        else if (counter == 6) {
            log("Configuring skin HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skinbox",
                PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, <0.4, 0.4, 0.4>
            ]);

            log("Rezzing alpha HUD");
            link_me = TRUE;
            rez_object("alpha-hud", <0.0, 0.811, 0.0>, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
        }
        else if (counter == 7) {
            log("Configuring rotatebar");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "rotatebar"
            ]);

            log("Rezzing alpha doll");
            link_me = FALSE;
            rez_object("doll", <0.0, 0.78, 0.0>, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
        }
        else if (counter == 8) {
            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6037, -0.03027>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 9) {
            configure_color_buttons("fnc0");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6037, 0.11965>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 10) {
            configure_color_buttons("fnc1");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.5693, 0.04468>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 11) {
            log("Configuring buttons");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fns0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 0, fingernails_shape_texture, <0.2, 0.9, 0.0>, <-0.375, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 1, fingernails_shape_texture, <0.2, 0.9, 0.0>, <-0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 2, fingernails_shape_texture, <0.2, 0.9, 0.0>, <0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 3, fingernails_shape_texture, <0.2, 0.9, 0.0>, <0.375, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_COLOR, 3, <0.3, 0.3, 0.3>, 1.00,
                PRIM_COLOR, 4, <0.6, 0.6, 0.6>, 1.00,
                PRIM_COLOR, 0, <0.0, 0.0, 0.0>, 1.00,
                PRIM_SIZE, <0.01, 0.295, 0.035>
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6589, -0.03027>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 12) {
            configure_color_buttons("tnc0");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6589, 0.11965>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 13) {
            configure_color_buttons("tnc1");

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("4x2_button", <-0.2025, -0.7327, -0.0708>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 14) {
            log("Configuring hand pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp1",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.1, 0.05>
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("4x2_button", <-0.2025, -0.7327, 0.0305>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 15) {
            log("Configuring hand pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp2",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.1, 0.05>
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("4x2_button", <-0.2025, -0.7327, 0.1316>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 16) {
            log("Configuring hand pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp3",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.1, 0.05>
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("Object", <-0.2025, -0.6958, 0.1555>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 17) {
            log("Configuring hand pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.05, 0.02>
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            // z=0.76953
            rez_object("6x1_button", <-0.2025, -0.813, 0.0315>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 18) {
            log("Configuring foot pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fp0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 5, options_texture, <0.12, 0.12, 0.0>, <0.44, -0.44, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.3, 0.05>
            ]);

        }
    }
}
