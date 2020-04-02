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

// v3.0 02Apr2020 <seriesumei@avimail.org> - Based on ss-r from Control/Serie Sumei

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
//     it and name it 'ruthdollv3'
//   * the button meshes named '5x1-s_button', '6x1_button' and '4x2_button'
//   * this script
// * Light fuse (touch the box prim) and get away, the new HUD will be
//   assembled around the box prim which will become the root prim of the HUD.
// * The alpha HUD and the doll may not be linked as they may need size
//   and/or position adjustments depending on how your mesh is linked.  Since
//   they are both linksets you do not want to link them to the main HUD until
//   you are very satisfied with their position.  Then link them and rejoice.
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

key hud_texture;
key header_texture;
key skin_texture;
key options_texture;
key fingernails_shape_texture;

vector bar_size = <0.4, 0.4, 0.03>;
vector hud_size = <0.4, 0.4, 0.34985>;
vector color_button_size = <0.01, 0.145, 0.025>;
vector shape_button_size = <0.01, 0.295, 0.051>;

vector alpha_hud_pos;
vector alpha_doll_pos;

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

// Wrapper for osGetGridName to simplify transition between environments
string GetGridName() {
    string grid_name;
    // Comment out this line to run in SecondLife, un-comment it to run in OpenSim
    grid_name = osGetGridName();
    if (is_SL()) {
        grid_name = llGetEnv("sim_channel");
    }
    llOwnerSay("grid: " + grid_name);
    return grid_name;
}

// The textures used in the HUD referenced below are included in the repo:
// hud_texture: ruth2 v3 hud gradient.png
// header_texture: ruth2 v3 hud header.png
// skin_texture: ruth2 v3 hud.skin.png
// options_texture: ruth2 v3 hud options.png
// fingernails_shape_texture: ruth 2.0 hud fingernails shape.png

get_textures() {
    if (is_SL()) {
        // Textures in SL
        // The textures listed are full-perm uploaded by seriesumei Resident
        hud_texture = "76dbff9c-c2fd-ffe9-a37f-cb9e42f722fe";
        header_texture = "c74e2f3e-d493-47e7-0042-58c240802c8a";
        skin_texture = "1cf48b3f-768d-652e-b789-4d0fa5e7085c";
        options_texture = "3857c5e8-95aa-1731-d27c-8ca3baa98d0b";
        fingernails_shape_texture = "fb6ee827-3c3e-99a8-0e33-47015c0845a9";
        alpha_hud_pos = <0.0, 1.03528, 0.24976>;
        alpha_doll_pos = <0.0, 0.57, 0.18457>;
    } else {
        if (GetGridName() == "OSGrid") {
            // Textures in OSGrid
            // TODO: Bad assumption that OpenSim == OSGrid, how do we detect
            //       which grid?  osGetGridName() is an option but does not
            //       compile in SL so editing the script would stll be required.
            //       Maybe we don't care too much about that?
            // The textures listed are full-perm uploaded by serie sumei to OSGrid
            hud_texture = "f38beb3f-6f3c-4072-b37e-1ee57f6e9ee4";
            header_texture = "2d80dac8-670a-4f46-8201-e7796a77afdd";
            skin_texture = "2f45a3e9-d4a9-4ea0-bbc8-bc3ead7a0a0f";
            options_texture = "a97c448b-10a7-4a2c-a705-f9b73368c852";
            fingernails_shape_texture = "fe777245-4fa2-4834-b794-0c29fa3e1fcf";
            alpha_hud_pos = <0.0, 0.811, 0.0>;
            alpha_doll_pos = <0.0, 0.78, 0.0>;
        } else {
            log("OpenSim detected but grid " + GetGridName() + " unknown, using blank textures");
            hud_texture = TEXTURE_BLANK;
            header_texture = TEXTURE_BLANK;
            skin_texture = TEXTURE_BLANK;
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
    log("Rezzing " + name);
    llRezObject(
        name,
        build_pos + delta,
        <0.0, 0.0, 0.0>,
        llEuler2Rot(rot),
        0
    );
}

configure_header(string name, float offset_y) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_TEXTURE, ALL_SIDES, header_texture, <1.0, 0.08, 0.0>, <0.0, offset_y, 0.0>, 0.0,
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
        build_pos = llGetPos();
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
            configure_header("minbar", 0.440);
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_TEXTURE, 2, header_texture, <0.2, 0.08, 0.0>, <-0.4, 0.437, 0.0>, 0.0,
                PRIM_TEXTURE, 4, header_texture, <0.2, 0.08, 0.0>, <-0.4, 0.437, 0.0>, 0.0,
                PRIM_SIZE, <0.40, 0.08, 0.03>
            ]);

        // ***** Alpha HUD *****

            log("Rezzing alphabar (west)");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.5, 0.0>, <PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 2) {
            configure_header("alphabar", 0.312);

            log("Rezzing alpha HUD");
            link_me = TRUE;
            rez_object("alpha-hud", alpha_hud_pos, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
        }
        else if (counter == 3) {
            log("Configuring alpha HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "rotatebar"
            ]);

            log("Rezzing alpha doll");
            link_me = TRUE;
            rez_object("ruthdollv3", alpha_doll_pos, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
        }
        else if (counter == 4) {
            log("Configuring alpha doll");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "chest"
            ]);

        // ***** Skin HUD *****

            // Set counter for skin panel
            counter = 10;

            log("Rezzing skinbar (north)");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.5>, <PI, 0.0, 0.0>);
        }
        else if (counter == 11) {
            configure_header("skinbar", 0.187);

            log("Rezzing skin HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.6894>, <PI, 0.0, 0.0>);
        }
        else if (counter == 12) {
            log("Configuring skin HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skinbox",
                PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, skin_texture, <1.0, 0.7, 0.0>, <0.0, 0.15, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, hud_size
            ]);

            log("Rezzing skin buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, 0.0000, 0.57145>, <PI, 0.0, 0.0>);
        }
        else if (counter == 13) {
            log("Configuring skin tone button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "sk0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.3, 0.05135>
            ]);

            log("Rezzing BoM button");
            link_me = TRUE;
            rez_object("Object", <-0.2025, 0.0000, 0.65473>, <PI, 0.0, 0.0>);
        }
        else if (counter == 14) {
            log("Configuring BoM button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "bom0",
                PRIM_TEXTURE, ALL_SIDES, skin_texture, <0.275, 0.1, 0.0>, <0.35, -0.44, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.10653, 0.04670>
            ]);

            log("Rezzing BoM preview");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, 0.0000, 0.71111>, <PI, 0.0, 0.0>);
        }
        else if (counter == 15) {
            log("Configuring BoM preview");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "bom1",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.3, 0.05135>
            ]);

        // ***** Option HUD *****

            // Set counter for option panel
            counter = 20;

            log("Rezzing optionbar (east)");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.5, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 21) {
            configure_header("optionbar", 0.062);

            log("Rezzing option HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.6894, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 22) {
            log("Configuring option HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "optionbox",
                PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 0.7, 0.0>, <0.0, 0.15, 0.0>, 0.0,
                PRIM_TEXTURE, 4, options_texture, <1.0, 0.7, 0.0>, <0.0, 0.15, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, hud_size
            ]);

            log("Rezzing hand pose button");
            link_me = TRUE;
            rez_object("Object", <-0.2025, -0.6958, 0.1555>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 23) {
            log("Configuring hand pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.05, 0.02>
            ]);

            log("Rezzing hand pose buttons");
            link_me = TRUE;
            rez_object("4x2_button", <-0.2025, -0.7327, -0.0708>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 24) {
            log("Configuring hand pose buttons");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp1",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.1, 0.05>
            ]);

            log("Rezzing hand pose buttons");
            link_me = TRUE;
            rez_object("4x2_button", <-0.2025, -0.7327, 0.0305>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 25) {
            log("Configuring hand pose buttons");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp2",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.1, 0.05>
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("4x2_button", <-0.2025, -0.7327, 0.1316>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 26) {
            log("Configuring hand pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "hp3",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.1, 0.05>
            ]);

        // Ruth only from here down
            log("Rezzing ankle lock button");
            link_me = TRUE;
            rez_object("Object", <-0.2025, -0.8130, -0.15891>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 27) {
            log("Configuring ankle lock button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fp0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 4, options_texture, <0.12, 0.12, 0.0>, <0.44, -0.44, 0.0>, 0.0,
                PRIM_SIZE, <0.01, 0.05, 0.05>
            ]);

            log("Rezzing foot pose buttons");
            link_me = TRUE;
            rez_object("6x1_button", <-0.2025, -0.813, 0.0315>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 28) {
            log("Configuring foot pose button");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fp1",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_SIZE, <1.0, 0.3, 0.05>
            ]);

            log("Rezzing fingernail shape buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.5693, 0.03198>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 29) {
            log("Configuring fingernail shape buttons");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fns0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 0, fingernails_shape_texture, <0.2, 0.9, 0.0>, <-0.375, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 1, fingernails_shape_texture, <0.2, 0.9, 0.0>, <-0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 2, fingernails_shape_texture, <0.2, 0.9, 0.0>, <0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 3, fingernails_shape_texture, <0.2, 0.9, 0.0>, <0.375, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
//                PRIM_COLOR, 3, <0.3, 0.3, 0.3>, 1.00,
//                PRIM_COLOR, 4, <0.6, 0.6, 0.6>, 1.00,
                PRIM_COLOR, 4, <0.0, 0.0, 0.0>, 1.00,
                PRIM_SIZE, <0.01, 0.295, 0.035>
            ]);

            log("Rezzing fingernail color buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6037, -0.04297>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 30) {
            configure_color_buttons("fnc0");

            log("Rezzing fingernail color buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6037, 0.10695>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 31) {
            configure_color_buttons("fnc1");

            log("Rezzing toenail color buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6589, -0.04297>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 32) {
            configure_color_buttons("tnc0");

            log("Rezzing toenail color buttons");
            link_me = TRUE;
            rez_object("5x1-s_button", <-0.2025, -0.6589, 0.10695>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 33) {
            configure_color_buttons("tnc1");
        }
    }
}
