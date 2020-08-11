<img src="Textures/r2-logo-white-grey.png" width="75" height="75">

# Ruth2 Mesh Avatar Project

Ruth2 is a low-poly mesh body specifically designed for OpenSimulator.
It is built to use standard Second Life(TM) UV maps using scratch-built open
source mesh bodies by Shin Ingen with other open source contributions from the
OpenSimulator Community.

* Github Repository: https://github.com/RuthAndRoth/Ruth2
* Discord Discussion Forum: https://discordapp.com/channels/619919380154810380/619919380691550240
* Discord Discussion Forum Invitation (open to all): https://discord.gg/UMyaZkc
* MeWe Community Page: https://mewe.com/group/5bbe0189a5f4e57c73569fb9
* Second Life Groups: "RuthAndRoth" and "Ruth and Roth Community"
* OpenSim Group: OSGrid RuthAndRoth
* OpenSim Region: OSGrid RuthAndRoth hop://login.osgrid.org/RuthAndRoth/128/128/26

## Current Release

Ruth2 v3 is the current release and is best obtained from the Ruth repository (not this Ruth2 one) via the "archive-ruth-rc3" branch.
https://github.com/RuthAndRoth/Ruth/tree/archive-ruth-rc3

Ruth2 v4 is currently being prepared and contributions are scattered until the release is ready.


## Previous Release

Previous releases of Ruth2 may be found in the archive-ruth-rc2 and archice-ruth-rc3 branches of
the old Ruth repo on Github and in a number of places both in Second Life and OSGrid as listed above.

## Personal Directories

We have moved all personal directories under the new top-level directory
'Contrib'.  These continue to be used as they always have, as a place for
team members to put things that are still under development before (or until)
they are merged into the master release directories.

## Upload Artifacts

Since not everyone is prepared to perform Blender exports to get the Collada
files for uploading we maintain recent exported .dae files in the Artifacts
directory.  These correspond to the .blend files in the Mesh directory.

There is also an IAR file that can be uset to pre-load OpenSim grids.  These are
usually updated at releases.  They will maintain consistent UUIDs for the
assets to minimize duplication when uploading multiple releases for unchanged
files.

## Licenses

Ruth2 is AGPL licensed, other contents of this repository are also
AGPL licensed unless otherwise indicated.  See LICENSE.md for specific details.

# Changes from Ruth 2.0

The Ruth2 and Roth2 repositories have been extracted from the original Ruth 2.0
repo, retaining all Git history of the files that have been moved.  Some common
files will be moved later to a common repo.  Below is the list of changes for the
files present in this repo:

* Animations -> Accessories/Animations
* Clothing -> Accessories/Clothing
* Contrib/Shin Ingen/Ruth/Uploads -> Artifacts/Collada
* Licenses.txt -> LICENSE.md
* Mesh/Avatar Ruth -> Mesh
  * Mesh/OSRuth2_CurrentRelease_DevKit_RC3.blend -> Mesh/ru2_DevKit_v3.blend
  * Mesh/OSRuth2_CurrentRelease_Source_RC3.blend -> Mesh/ru2_Source_v3.blend
* Mesh/Avatar Ruth/IARs -> Artifacts/IAR
  * Artifacts/IAR/R2-Ruth-RC3.iar -> Artifacts/IAR/Ruth2-v3.iar
* Mesh/Avatar Ruth/Scripts -> Scripts
* Mesh/Avatar Ruth/Textures -> Textures
* Mesh/Avatar Ruth/Uploads -> Artifacts/Collada
* Shapes -> Accessories/Shapes
* Skins -> Accessories/Skins

## Reference Files

The original Ruth repo contained a number of reference files archived from
various places around the Internet.  Some of those have become hard to find
due to link rot and sites vanishing.

Those archived files are now in their own repo https://github.com/RuthAndRoth/Reference.
