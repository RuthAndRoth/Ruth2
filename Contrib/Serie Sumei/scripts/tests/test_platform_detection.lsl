// test_platform_detection.lsl - Test functions to determine the grid/platform
// v1 - Create tests
// v2 - Add Aditi, Halcyon
// v3 - Add 3rd Rock Grid

integer VERBOSE = TRUE;

log(string msg) {
    if (VERBOSE == 1) {
        llOwnerSay(msg);
    }
}

// *****
// Test bits

integer failures;
integer total;

integer test_integer(integer actual, integer expected, string desc) {
    total++;
    string str = "OK";
    if (actual != expected) {
        str = "not OK: " + (string)actual + " == " + (string)expected;
        failures++;
    }
    log(desc + ": " + str);
    return (actual == expected);
}

integer test_string(string actual, string expected, string desc) {
    total++;
    string str = "OK";
    if (actual != expected) {
        str = "not OK: " + actual + " == " + expected;
        failures++;
    }
    log(desc + ": " + str);
    return (actual == expected);
}
// *****


// Hack to detect Second Life vs other platforms that try to behave like SL
// Relies on a bug in llParseString2List() in SL
// http://grimore.org/fuss/lsl/bugs#splitting_strings_to_lists
integer haz_SL_bug() {
    // Expected result is [1,2,9,9,9];
    return (llParseString2List("12999", [], ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]) == [1,2,999]);
}

integer haz_SL_bug_verbose() {
    list expected = [1,2,9,9,9];
    list SL = [1,2,999];
    list la = llParseString2List("12999", [], ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
    log("haz_SL_bug(): llParseString2List(\"12999\") returns " + llDumpList2String(la, ","));
    if (la == expected)
      log("  Second Life not detected");
    if (la == SL)
      log("  Second Life detected");
    return (la == SL);
}

// Derive an identifier for specific grids
// grid_name - only supported by some platforms/configurations, use it if present
// sim_version - scanned for 'OSgrid'
// simulator_hostname - scanned for 'aditi' and 'agni'
string get_grid_name() {
    string grid_name = llGetEnv("grid_name");
    if (grid_name == "") {
        string sim = llGetEnv("sim_channel");
        if (sim == "Halcyon Server") {
            // Should have set grid_name above
        }
        else if (sim == "OpenSim") {
            string sim_version = llGetEnv("sim_version");
            if (llSubStringIndex(sim_version, "OSgrid") >= 0) {
                grid_name = "OSgrid";
            }
            else if (llSubStringIndex(llGetEnv("simulator_hostname"), "3rdrockgrid.com") >= 0) {
                grid_name = "3rdrockgrid";
            }
            if (grid_name == "") {
                // Fall back to region name
                grid_name = llGetRegionName();
            }
        }
        else if (sim == "Second Life Server") {
            if (llSubStringIndex(llGetEnv("simulator_hostname"), "aditi.lindenlab") >= 0) {
                // Try to detect the SL beta grid
                grid_name = "aditi";
            } else {
                // Return the name of the SL main grid
                grid_name = "agni";
            }
        }
        else {
            // Fall back to region name
            grid_name = llGetRegionName();
        }
    }
    return grid_name;
}

// Returns an identifier of the base sim platform
// halcyon, opensim, secondlife
string get_platform() {
    string sim = llGetEnv("sim_channel");
    string ret;
    if (sim == "Halcyon Server") {
        ret = "halcyon";
    }
    else if (sim == "OpenSim") {
        ret = "opensim";
    }
    else if (sim == "Second Life Server") {
        ret = "secondlife";
    }
    return ret;
}

say_env(string varname) {
    llOwnerSay(varname + ": [" + llGetEnv(varname) + "]");
}

default {
    state_entry() {
        log("\nPlatform Detection Tests");
        log("get_platform(): [" + get_platform() + "]");
        log("get_grid_name(): [" + get_grid_name() + "]");

        if (haz_SL_bug()) log("SL bug detected");
        haz_SL_bug_verbose();

        log(" ");
        log("RegionName: [" + llGetRegionName() + "]");
        say_env("simulator_hostname");
        say_env("estate_id");
        say_env("estate_name");
        say_env("region_product_name");
        say_env("sim_version");
        say_env("sim_channel");
        say_env("region_start_time");
        say_env("platform");
        say_env("script_engine");
        say_env("halcyon");
        say_env("grid_name");
    }
}
