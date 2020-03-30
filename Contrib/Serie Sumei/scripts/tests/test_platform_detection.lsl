// test_platform_detection.lsl - Test functions to determine the grid/platform
// v1 - Create tests

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

integer is_SL_verbose() {
    string sa = "12999";
    list OS = [1,2,9,9,9];
    list SL = [1,2,999];
    list la = llParseString2List(sa, [], ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]);
    log("is_SL(): llParseString2List(\"12999\"): " + llDumpList2String(la, ","));
    if (la == OS)
      log("  Appears to be OpenSimulator");
    if (la == SL)
      log("  Appears to be Second Life");
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

say_env(string varname) {
    llOwnerSay(varname + ": [" + llGetEnv(varname) + "]");
}

default {
    state_entry() {
        log("\nPlatform Detection Tests");
        log("The tests for platform detection require manual inspection due to the chicken-and-egg problem of detecting the platform in order to test the detection. :)");
        is_SL_verbose();

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
