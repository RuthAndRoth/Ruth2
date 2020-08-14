Ruth2 - Open Source Mesh Avatar for Virtual Worlds
Prepared: 14-Aug-2020

Ruth2 is a low-poly mesh body specifically designed for OpenSimulator. It is built to use standard Second Life(TM) UV maps using a scratch-built open source mesh by Shin Ingen, Ada Radius and other contributors from the OpenSimulator Community.

============================================================
BAKES ON MESH

Ruth2 v4 is designed to work well with Bakes on Mesh. It has a simple alpha masking capability without needing many separate mesh parts. Alpha masks can be worn to give more control over hidden areas. As an alternative to Bakes on Mesh skin textures may also be applied, but you should then add a full body alpha mask to hide the underlying system avatar.

The "Ruth2 v4 Mesh Avatar" box contents are designed so that they form a complete initial avatar using Bakes on Mesh. Flat (posable), Medium and High Feet will all be attached as well as related toenails, and a number of fingernail options. You can remove the options you don't want to wear. You can switch to your own shape, skin, eyes and hair and/or use the HUD to change your appearance. Some example skins, hair, clothing  and a range of alpha masks are provided in the "Ruth2 v4 Extras" box.

============================================================
HUD

Ruth2 v4 uses a single combination HUD for alpha masking, skin and eye texture application and other features. The skins and eyes that are available are set via a notecard (!CONFIG) in the Contents of the HUD which can be edited to incorporate your own skins (10 slots are available) and/or eye textures (5 slots are available).

============================================================
BOX CONTENTS

Ruth2 v4 - Mesh Avatar - This is the normal distribution box and is designed so that once unpacked its contents can be "worn" and then adjusted to a user's needs.
* !README, !LICENSE and !CHANGES
* Ruth2 v4 (Body+Hands+Head)
* Ruth2 v4 Flat Feet (posable)
* Ruth2 v4 Medium Feet (optional)
* Ruth2 v4 High Feet (optional)
* Ruth2 v4 Eyes
* Ruth2 v4 Toenails (3 options)
* Ruth2 v4 Fingernails (5 options)
* Ruth2 v4 HUD
* Initial skin, shape, basic eyes, basic hair, and basic hair tattoo
* Dark gray underwear

Ruth2 v4 - Mesh Avatar - Business

A special version of Ruth2 v4 with smoother body shape. This is the normal Business-friendly distribution box and is designed so that once unpacked its contents can be "worn" and then adjusted to a user's needs.
* !README, !LICENSE and !CHANGES
* Ruth2 v4 Business (Body+Hands+Head)
* Ruth2 v4 Flat Feet (posable)
* Ruth2 v4 Medium Feet (optional)
* Ruth2 v4 High Feet (optional)
* Ruth2 v4 Eyes
* Ruth2 v4 Toenails (3 options: for flat, medium and high feet)
* Ruth2 v4 Fingernails (2 options: short and oval)
* Ruth2 v4 HUD
* Initial skin, shape, basic eyes, basic hair, and basic hair tattoo
* Dark gray underwear

Ruth2 v4 - Extras - This is a box of useful extra elements and options.
* !README-EXTRAS and !LICENSE
* Ruth2 v4 Business (Body+Feet+Hands+Head)
* Ruth2 v4 Business Headless (Body+Feet+Hands)
* Ruth2 v4 Body (only)
* Ruth2 v4 Hands
* Ruth2 v4 Head
* Ruth2 v4 Headless (Body+Feet+Hands)
* Ruth2 v4 Head+Vneck (section of body)
* Ruth2 v4 Elf Ears
* Dark grey underwear alternatives
* Shoe height adjustments for fixed medium and high feet
* Alternative skins
* Alternative shapes
* Sample alpha masks
* Sample hair
* Sample hair tattoos

Ruth2 v4 - Resources - This box is not normally needed. It contains textures and other resources with original UUIDs as used within the other assets.. This can be useful of moving the assets across grid, or to repair elements.
* !README-RESOURCES and !LICENSE
* All skin and eye textures used in default HUD

Ruth2 v4 - Mesh Uploads - This box is not normally needed.  It contains mesh for all Ruth2 v4 elements as originally uploaded and before attaching a root prim or any texturing.
* !README-MESH-UPLOADS and !LICENSE
* Collada (.dae) Mesh for all Ruth2 v4 elements as originally uploaded and before part renaming, attaching a root prim or any texturing.

============================================================
KNOWN ISSUES AND TROUBLESHOOTING

Not all the appearance sliders will work on the mesh body and parts.

Ruth2 v4 with attached Bento head will work with most shapes. The headless body, to use with system head or other mesh head, will work well with the sliders except body fat, and extremes to neck length and thickness, because of the neck seam. There are a few head sliders that don't work: Head Shape, Ear Angle, Jowls, Chin Cleft. 

Texture Alpha Mode - Alpha Blending or Alpha Masking? Ruth2 v4 is set initially with mode Alpha Masking with a mid cutoff of 128 (the cutoff range can be 0 to 255) as this may work well with the addition of clothing and hair that use Alpha Blending as transparent edges can appear if too many overlapping items use the same alpha mode.  But Alpha Blending can often look smoother.The Eyelashes are set to Alpha Blending mode for this reason since they act more like a hair attachment.

Foot skin problems? For best result, paint over the system toenails and remove as much detail as you can from your foot skin that is probably designed for the system avatar's duck feet.

============================================================
RUTHANDROTH COMMUNITY

Please contribute via the GitHub Repository and send your feedback by posting to the Discord Channel.

* Github Repository: https://github.com/RuthAndRoth/Roth2
* Discord Discussion Channel: https://discordapp.com/channels/619919380154810380/619919380691550240
* Discord Discussion Channel Invitation (open to all): https://discord.gg/UMyaZkc
* MeWe Community Page: https://mewe.com/group/5bbe0189a5f4e57c73569fb9
* Second Life Marketplace: https://marketplace.secondlife.com/stores/228512
* Second Life Groups: "RuthAndRoth" and "Ruth and Roth Community"
* OpenSim Group: OSGrid RuthAndRoth
* OpenSim Region: OSGrid RuthAndRoth hop://login.osgrid.org/RuthAndRoth/128/128/26

============================================================
CREDITS

* Original Ruth 2.0 RC#1 to RC#3 mesh by Shin Ingen with rigging and vertex weight maps by Ada Radius.
* Revised mesh, rigging and vertex weight maps by Ada Radius.
* GitHub repository management and testing by Fred Beckhusen, Outworldz LLC (Ferd Frederix), Ai Austin and Serie Sumei.
* UV map is CC-BY Linden Lab.
* Skin templates by Chip Midnight:  http://forums-archive.secondlife.com/109/72/40762/1.html
* Skins included in the HUD:
   - Eloh Elliot Skins
   - Linda Kellie Skins
* T-Shirt Texture by Robin (Soujourner) Wood: https://www.robinwood.com/Catalog/Technical/SL-Tuts/SLPages/RSW-TShirt.html
* Linda Kellie Designs - Tintable Bra and Panties - Creative Commons CC0 https://zadaroo.com/wp-content/uploads/2012/12/templates-bra-and-panties.zip
* HUD mesh, textures and scripts by Serie Sumei using modifications to original scripts by Shin Ingen.
* Elf Ears: AGPL by Fred K. Beckhusen (avatar: Ferd Frederix) and Ai Austin.
* Eyeball template derived from the UV map of Linden Lab's eyeball mesh.
* eyelashes02.png from https://outworldz.com CC-0
* R2 Logo by Serie Sumei based on original by Shin Ingen: https://github.com/RuthAndRoth/Extras/tree/master/Textures/Logo
* Thanks to all contributors as listed in the LICENSE text file.
