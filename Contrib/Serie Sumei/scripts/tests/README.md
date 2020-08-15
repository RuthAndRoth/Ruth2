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

Fundamentally this is about handling differences between the server platforms.
There are also configuration items in OpenSimulator that can be determined
for functional reasons.  The current platforms detected are:

* Halcyon
* OpenSimulator
* Second Life

## Halcyon

While the Halcyon platform is derived from OpenSimulator there are
significant differences making it necessary to identify it specifically.
This includes the unavailability of os*() functions.

    Platform Detection Tests
    is_SL(): llParseString2List("12999"): 1,2,9,9,9
      Appears to be OpenSimulator
    RegionName: [MySin]
    simulator_hostname: [*.*.*.*]
    estate_id: [3]
    estate_name: [MySin]
    region_product_name: [Estate / Full Region]
    sim_version: [0.9.41.7023]
    sim_channel: [Halcyon Server]
    region_start_time: [1582785875]
    platform: [Halcyon]
    script_engine: [Phlox]
    halcyon: [1]
    grid_name: [Amaryllis Grid]

## OpenSimulator

### OpenSimulator on .NET (OSGrid)

Notable only in the sim_version value as 'Win/.NET', otherwise appears to
have no difference from Mono/Linux.

    Platform Detection Tests
    get_platform(): [opensim]
    get_grid_name(): [OSgrid]
    haz_SL_bug(): llParseString2List("12999") returns 1,2,9,9,9
      Second Life not detected

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

### OpenSimulator on Mono (OSGrid)

Reported in sim_version as 'Unix/Mono'.

    Platform Detection Tests
    get_platform(): [opensim]
    get_grid_name(): [OSgrid]
    haz_SL_bug(): llParseString2List("12999") returns 1,2,9,9,9
      Second Life not detected

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

### OpenSimulator (3rd Rock Grid)

    Platform Detection Tests
    get_platform(): [opensim]
    get_grid_name(): [3rdrockgrid]
    haz_SL_bug(): llParseString2List("12999") returns 1,2,9,9,9
      Second Life not detected

    RegionName: [170Test]
    simulator_hostname: [r067.3rdrockgrid.com]
    estate_id: [230]
    estate_name: [Butch]
    region_product_name: [Mainland]
    sim_version: [OpenSim 0.8.2.1-DWG16c-3RGPost_Fixes       (Win/.NET)]
    sim_channel: [OpenSim]
    region_start_time: [1590555362]
    platform: []
    script_engine: []
    halcyon: []
    grid_name: []

### OpenSimulator on Mono (Utopia Skye)

    Platform Detection Tests
    get_platform(): [opensim]
    get_grid_name(): [Skye Dreams]
    haz_SL_bug(): llParseString2List("12999") returns 1,2,9,9,9
      Second Life not detected

    RegionName: [Skye Dreams]
    simulator_hostname: [rsrv11.utopiaskyegrid.com]
    estate_id: [102]
    estate_name: [Skye Dreams]
    region_product_name: [Private Region]
    sim_version: [OpenSim 0.9.2.0 Yeti Release       (Unix/Mono)]
    sim_channel: [OpenSim]
    region_start_time: [1585421854]
    platform: []
    script_engine: []
    halcyon: []
    grid_name: []

### OpenSimulator (standalone)

A plain OpenSimulator install on Mono with minimal configuration.

    Platform Detection Tests
    get_platform(): [opensim]
    get_grid_name(): [Dogwood]
    haz_SL_bug(): llParseString2List("12999") returns 1,2,9,9,9
      Second Life not detected

    RegionName: [Dogwood]
    simulator_hostname: [*.*.*.*]
    estate_id: [101]
    estate_name: [Elms]
    region_product_name: []
    sim_version: [OpenSim 0.9.1.1 Snail Release       (Unix/Mono)]
    sim_channel: [OpenSim]
    region_start_time: [1584569097]
    platform: []
    script_engine: []
    halcyon: []
    grid_name: []

## Second Life

Second Life has two primary installations, the main grid (Agni) and the beta grid (aditi).

### Agni

    Platform Detection Tests
    get_platform(): [secondlife]
    get_grid_name(): [agni]
    SL bug detected
    haz_SL_bug(): llParseString2List("12999") returns 1,2,999
      Second Life detected

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

### Aditi

    Platform Detection Tests
    get_platform(): [secondlife]
    get_grid_name(): [aditi]
    SL bug detected
    haz_SL_bug(): llParseString2List("12999") returns 1,2,999
      Second Life detected

    RegionName: [Morris]
    simulator_hostname: [sim***.aditi.lindenlab.com]
    estate_id: [1]
    estate_name: [mainland]
    region_product_name: [Mainland / Full Region]
    sim_version: [2020-03-20T20:30:23.538927]
    sim_channel: [Second Life Server]
    region_start_time: [1584997845]
    platform: []
    script_engine: []
    halcyon: []
    grid_name: []
