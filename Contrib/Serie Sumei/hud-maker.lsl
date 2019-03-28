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

// Build a single HUD for Ruth/Roth for alpha and skin appliers:
// * Upload or obtain via whatever means the Alpha HUD mesh and the 'doll' mesh.  This
//   script will throw an error if you start with a pre-linked Alpha HUD but it should
//   work anyway.  Remove any scripts in these meshes.
// * Create a new prim and take a copy of it into inventory
// * Copy the folloing objects into the new prim on the ground:
//   * the new prim from inventory created above and name it 'Object'
//   * the alpha HUD mesh into the root prim and name it 'alpha-hud'
//   * the skin HUD mesh into the root prim and name it 'skin-hud'
//   * the doll mesh into the root prim and name it 'doll' if it is not already linked
//     to the ahpha HUD mesh
//   * this script
// * Light fuse (touch the new prim) and get away, the new HUD will be assembled
//   around the new prim which is now the root prim of the HUD.
// * The alpha HUD and the doll will not be linked as they may need size and/or
//   position adjustments depending on how your mesh is linked and what their original
//   root prim was.
// * Rename the former root prim of the alpha HUD mesh, if it was the rotation bar
//   at the bottom name it 'rotatebar'.  Remove any script if it is still present.
// * Rename the former root prim of the doll according to the usual doll link names.
// * Make any position and size adjustments as necessary to the alpha HUD mesh and
//   doll, then link them both to the new HUD root prim.  Make sure that the center
//   square HUD prim is last so it remains the root of the linkset.
// * Remove this script from the HUD root prim and copy in the ss-c version of the
//   ru2HUD_ac_trigger HUD script.
// * The other objects are also not needed any longer in the root prim and can be removed.

vector build_pos;
integer link_me = FALSE;
integer FINI = FALSE;
integer counter = 0;

key bar_texture = "332b97c3-d7c0-f2e5-732a-16ead0d8ba02";
vector bar_size = <0.5, 0.5, 0.04>;

key hud_texture = "0f85ff3b-de15-4dbe-b899-63324de774e4";
vector hud_size = <0.5, 0.5, 0.5>;

key options_texture = "00846504-9c2c-46bb-91d7-e392b0ee6a35";
key fingernails_shape_texture = "fe777245-4fa2-4834-b794-0c29fa3e1fcf";

vector color_button_size = <0.01, 0.145, 0.025>;
vector shape_button_size = <0.01, 0.295, 0.051>;

// Spew debug info
integer VERBOSE = TRUE;

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

configre_bar(string name, float offset_y) {
    log("Configuring " + name);
    llSetLinkPrimitiveParamsFast(2, [
        PRIM_NAME, name,
        PRIM_TEXTURE, ALL_SIDES, bar_texture, <1.0, 0.1, 0.0>, <0.0, offset_y, 0.0>, 0.0,
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
            rez_object("Object", <0.0, 0.0, -0.5>, <0.0, 0.0, 0.0>);
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
            configre_bar("minbar", 0.440);

            // log("Rezzing east");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.5, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 2) {
            configre_bar("optionbar", 0.065);

            // log("Rezzing north");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.5>, <PI, 0.0, 0.0>);
        }
        else if (counter == 3) {
            configre_bar("skinbar", 0.190);

            // log("Rezzing west");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.5, 0.0>, <PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 4) {
            configre_bar("alphabar", 0.314);

            log("Rezzing option HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, -0.76953, 0.0>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 5) {
            log("Configuring option HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "optionbox",
                PRIM_TEXTURE, ALL_SIDES, options_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, hud_size
            ]);

            log("Rezzing skin HUD");
            link_me = TRUE;
            rez_object("Object", <0.0, 0.0, 0.76953>, <PI, 0.0, 0.0>);
        }
        else if (counter == 6) {
            log("Configuring skin HUD");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "skinbox",
                PRIM_TEXTURE, ALL_SIDES, hud_texture, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_SIZE, hud_size
            ]);

            log("Rezzing alpha HUD");
            link_me = FALSE;
            rez_object("alpha-hud", <0.0, 0.811, 0.0>, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
        }
        else if (counter == 7) {
            log("Rezzing alpha doll");
            link_me = FALSE;
            rez_object("doll", <0.0, 0.9, 0.0>, <PI_BY_TWO, 0.0, -PI_BY_TWO>);
        }
        else if (counter == 8) {
            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.6, -0.03027>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 9) {
            configure_color_buttons("fnc0");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.6, 0.11965>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 10) {
            configure_color_buttons("fnc1");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.64849, 0.04468>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 11) {
            log("Configuring buttons");
            llSetLinkPrimitiveParamsFast(2, [
                PRIM_NAME, "fns0",
                PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 5, fingernails_shape_texture, <0.25, 1.0, 0.0>, <-0.375, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 6, fingernails_shape_texture, <0.25, 1.0, 0.0>, <-0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 1, fingernails_shape_texture, <0.25, 1.0, 0.0>, <0.125, 0.0, 0.0>, 0.0,
                PRIM_TEXTURE, 2, fingernails_shape_texture, <0.25, 1.0, 0.0>, <0.375, 0.0, 0.0>, 0.0,
                PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.00,
                PRIM_COLOR, 3, <0.3, 0.3, 0.3>, 1.00,
                PRIM_COLOR, 4, <0.6, 0.6, 0.6>, 1.00,
                PRIM_COLOR, 0, <0.0, 0.0, 0.0>, 1.00,
                PRIM_SIZE, shape_button_size
            ]);

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.73976, -0.03027>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 12) {
            configure_color_buttons("tnc0");

            log("Rezzing buttons");
            link_me = TRUE;
            rez_object("5x button", <-0.2488, -0.73976, 0.11965>, <-PI_BY_TWO, 0.0, 0.0>);
        }
        else if (counter == 13) {
            configure_color_buttons("tnc1");

        }
    }
}
