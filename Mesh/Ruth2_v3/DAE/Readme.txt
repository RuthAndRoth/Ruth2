## Ruth2 v3 Collada DAE

The Collada DAE for Ruth 2.0 RC#3 as used by Shin Ingen for the definitive release was not uploaded to GitHub at the time that the final Ruth 2.0 RC#3 Blender files were put in place. In the GitHub Readme file he stated "No test DAE included pending final in-world testing".

DAE produced by other contributors such as Sundance haiku, Taarna Welles, Curious Creator and Ada Radius are not fully in step with the final Blender file that Shin used. A source of exported DAE from the original Blender mesh and dev kit is from Sean Heavy, which he used without altering the Blender Source and DevKit meshes as the basis for his exports at https://github.com/ocsean/RuthToo

That source has been used as the basis for the DAE provided here for convenience.

---------------------------------------

## Ruth2 v3 Mesh

* **ru2_Source_v3.blend**: This blender file is a compilation of all the
  improvements done since RC#2 and is the file used for the OpenSim release
  of RC#3. All collaborators should use this file to create your own release
  and/or for future improvements.

  * mesh head 	- Avastar
  * upper body 	- Edit#15
  * lower body 	- Edit#15
  * bento hands	- Edit#15

  * NOW RUTH STANDARD
    * flat feet 	- Taarna Wells
    * medium feet	- Taarna Wells
    * high feet 	- Taarna Wells

  * Extras
    * Curious high feet 		- Edit#14
    * Sundance high feet 		- Edit#15
    * Ada flat feet (poseable) 		- Edit#15

  Toenails for all feet types are Sundance Haiku's toenails modified by
  Taarna Wells. It now uses only one UV map and will be easier to manage.
  They are compatible with Sundance Haiku's Nail System HUD v3.

* **ru2_DevKit_v3.blend**: This blender file is intended for content creators.
  It is an exact duplicate of the source file but textured with the alpha cut
  faces used for the official RC#3 release. I usually join the parts as a
  personal preference but I am leaving that up to each content creator's preference.

---------------------------------------

## Ruth2 v3 Mesh Final Tweaks

Shin Ingen noted these changes to the Blender mesh for the final version...

Tweaks to the original Sundance Edit #15 (please note that the source of these mesh parts is the original Sundance Edit #15 and not the renamed Edit #16. I reverted Sundance commit hash fb1cd5ef334c7612db7eeca5d05f18f0a7bc23e2 and delete Edit #16 for it is not needed)

As part of the pre-release preparation the following steps were taken. The order in which they were done is important.

1. Re-established the lower body center seam line (UV Map only).

2. Removed dead node reference to mRightHip.

3. Removed node reference to L_UPPER_LEG & R_UPPER_LEG within the 3 node rings of the lower body. Some have weights that might pull the waist connection during animation.

4. Removed cross vertex group reference define by the center seam. (lower body only)

5. Smoothing of vertex weights of the lower body mesh around the inner thighs to remove some rough spots when animating.

6. Joined upper and lower body and removed double nodes along the waist connection. This will ensure that the upper and lower body connection node rings will have exactly the same vertex weight after separation.

7. Removed all unused vertex group for each part.

8. Remove asymmetries of the upper body, lower body and flat feet meshes. The remaining mesh parts are symmetical.

9. Re-snapped all connecting parts using the following method to ensure that the lower and upper body symmetries are maintained. 
	- all feet type to lower body.
	- lower body to upper body.
	- upper body to mesh bento head.
	- bento hands to upper body.

10. No test DAE included pending final in-world testing.

---------------------------------------------

## Ruth2 v3 Collada Mesh Uploads Available as at 6-Jan-2019

DAE exports created by Sundance Haiku using .blend file for Ruth RC#3
Available at https://github.com/RuthAndRoth/   Ruth2/Contrib/Sundance%20Haiku/RC3_Edits/RC3_Final

DAE exports created by Sean Heavy for his "Ruth Too" based on the .blend file for Ruth RC#3
Available via https://github.com/ocsean/RuthToo

Previous RC#2 Collada (.dae) files in Ruth\Mesh\Avatar Ruth\Previous Release\Ruth RC2\Uploads
Available from https://github.com/RuthAndRoth/Ruth/tree/archive-ruth-rc2/Mesh/Avatar%20Ruth/Previous%20Release/Uploads

