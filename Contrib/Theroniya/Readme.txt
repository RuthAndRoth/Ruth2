Theroniya’s Garage Sale has provided a Ruth2 v4 mesh body variant and
modifiable clothing at https://marketplace.secondlife.com/stores/248121

Blender sources for the modified mesh body and clothing are at
https://github.com/Theroniya/garage-sale/

Note from user comments on the Second Life Marketplace...

One minor problem as at July 2023, the lower back prim has an empty
description, this prevents the HUD from working when you try to alpha
that section of the body. Luckily, this is full perm! All you have to
do is put the following into the back prim's description (the main
one that is named "1 - Body With Hands"):

aBacklower0:0,aBacklower1:1,aBacklower2:2,aBacklower3:3,aBacklower4:4

This sets all 5 faces of that prim (0..4). If it already says that
in the Description, be aware it was probably already fixed.