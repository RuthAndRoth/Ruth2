## Ruth2 v4 Mesh

* **Ruth2v4Dev.blend**: This blender file is a compilation of all the parts
  used for Ruth2 v4. All collaborators should use this file as a basis for
  future improvements, which under the AGPL license should be made freely
  and publicly available.

* The .blend file, Colada (DAE) exports of parts and the UV maps
  are copied from Ruth2/Contrib/Ada Radius as at 2-Sep-2020.

* The .blend file is equivalent to Ada Radius Draft 11.

* Most parts are unchanged since Draft 9. Elements with head part changed at Draft 10. Eyelashes changed at Draft 10. All nails changed at Draft 11.

* Ruth2v4Dev.blend has a complete set of the objects and no armature. Sevrak forums reported issues in using Blender 2.83. Upgrading to Blender 2.9, appending whatever is needed from Ruth2v4Dev.blend into a clean file and adding in a clean armature (either Avastar or one of the armatures Ada Radius built from avatar_skeleton.xml) works okay. Ada decided to avoid including an armature in the Dev file - a simpler set of objects in a blend file is more useful to designers, long term, as Blender upgrades and Avastar either does or does not catch up.
