# scripts/tests

These scripts test specific aspects of the scripting environment of
Second Life and OpenSimulator.  They also test specific functions used
in the HUD scripts.

* test_json_alpha.lsl - Tests the json_get_alpha() and json_set_alpha()
  functions used to store the alpha state in the body receiver and HUD
  control scripts.

* test_platform_detection.lsl - Tests and provides a debugging framework
  for platfrm detection in LSL and OSSL.


# Scripting Platforms

There are multiple scripting engines that these scripts are expected to
run under and there are differences both in operation and available
functions that we sometimes need to account for.  Below are the outputs of
test_platform_detection.lsl on specific script engines for reference.

## Second Life

    Platform Detection Tests
    The tests for platform detection require manual inspection due to the chicken-and-egg problem of detecting the platform in order to test the detection. :)
    is_SL(): llParseString2List("12999"): 1,2,999
      Appears to be Second Life
    RegionName: [Fireheart]
    simulator_hostname: [sim10193.agni.lindenlab.com]
    estate_id: [1]
    estate_name: [mainland]
    region_product_name: [Mainland / Full Region]
    sim_version: [2020-03-17T20:08:11.538605]
    sim_channel: [Second Life Server]
    region_start_time: [1585058313]
    platform: []
    script_engine: []
    halcyon: []
    grid_name: []


## OpenSimulator

    Platform Detection Tests
    The tests for platform detection require manual inspection due to the chicken-and-egg problem of detecting the platform in order to test the detection. :)
    is_SL(): llParseString2List("12999"): 1,2,9,9,9
      Appears to be OpenSimulator
    RegionName: [RuthAndRoth]
    simulator_hostname: []
    estate_id: [1]
    estate_name: [RuthAndRoth]
    region_product_name: [Mainland]
    sim_version: [OpenSim 0.9.2.0 Yeti Dev   OSgrid 0.9.2.0 Yeti Dev   cfef190424: 2020-03-15 22:13:31 +0000 (Win/.NET)]
    sim_channel: [OpenSim]
    region_start_time: [1585226930]
    platform: []
    script_engine: []
    halcyon: []
    grid_name: []

    Platform Detection Tests
    The tests for platform detection require manual inspection due to the chicken-and-egg problem of detecting the platform in order to test the detection. :)
    is_SL(): llParseString2List("12999"): 1,2,9,9,9
      Appears to be OpenSimulator
    RegionName: [Soap Bubble]
    simulator_hostname: []
    estate_id: [101]
    estate_name: [Serie-ous Style]
    region_product_name: []
    sim_version: [OpenSim 0.9.1.1 Yeti Dev   OSgrid 0.9.1.1 Yeti Dev   066a6fbaa1: 2019-12-18 23:26:13 +0000 (Unix/Mono)]
    sim_channel: [OpenSim]
    region_start_time: [1584569015]
    platform: []
    script_engine: []
    halcyon: []
    grid_name: []
