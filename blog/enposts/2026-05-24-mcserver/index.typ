#import "/template.typ": *

#doc-template(
title: "Setting Up a Minecraft Server",
date: "May 24, 2026",
parindent: 1.2em,
body: [

Recently I set up a Minecraft server. This server incorporates many mods, and rather than adopting an existing modpack such as ATM10, I selected the mods myself; hence this record. Since large AI models have become widespread, I will not elaborate on the details here and will mention only the high-level choices.

= Version Selection

The main impetus for building this server was that I had watched several videos on Bilibili about the Create: Aeronautics mod, so I was eager to try it. This mod currently supports version 1.21.1 primarily, which is also a version with good overall mod compatibility at present, so the choice was natural.

= Client Launcher Selection

The most popular launcher at present is #link("https://prismlauncher.org/", "Prism Launcher"). However, this launcher supports only legitimate copies of the game. If you also want friends who have not purchased the game to join, you need another launcher, such as #link("https://polymc.org/", "PolyMC"). The two launchers share a common origin, both being forks of #link("https://multimc.org/", "MultiMC"); nevertheless, their modpacks are not interchangeable and must be produced separately.

As for preparing a modpack, Prism Launcher is more convenient, because it resolves mod dependencies automatically. Therefore, even if you decide to use PolyMC, I recommend installing the mods with Prism Launcher and then copying all the mod jar files into the PolyMC instance.

Note that both launchers download the game from Mojang's website, which may be slow or even fail in the network environment of mainland China. If the players are not technically adept at circumventing network restrictions, some launchers developed domestically may be more suitable, such as #link("https://hmcl.huangyuhui.net/", "HMCL").

= Server Selection

After adding many mods, the demands on memory and CPU rise sharply. Memory prices are high at present, and servers with large memory have become especially expensive. If a VPS were used, the expense would be roughly 500 to 1,000 yuan per month, which is somewhat difficult to afford. I therefore selected an old second-hand laptop with 16 GB of memory to serve as the server, and rented a VPS costing only 15 yuan per month to act as the public gateway. In this way, the server is quite inexpensive — no more than the cost of a meal or two each month.

= Creating a Server-Side Modpack

Adding mods on the client side is very simple: you only need to operate within the launcher. The server side, however, is slightly more involved. The mod API chosen this time is NeoForge, so first download the installer from the #link("https://neoforged.net/", "NeoForge website"), run it, and choose to install the server. Then open the client instance directory, locate the `mods/` directory inside it, and copy all the jar files into the mods directory of NeoForge.

It is advisable to test the functions in single-player mode before starting the server, because once the server is running and a problem such as incompatibility is discovered, updating becomes very troublesome: all users must upgrade together.

= Supporting Both Legitimate and Unlicensed Players

To allow players without legitimate copies to join, the server is set to offline mode. By default, however, the skins and capes of players on an offline-mode server cannot be displayed, so the mod #link("https://modrinth.com/mod/trueuuid", "TrueUUID") must be added. In addition, to prevent identity impersonation, a login feature is necessary; here I recommend #link("https://modrinth.com/mod/nedologin", "NedoLogin"). For the sake of server security, it is also best to enable the whitelist.

Owing to some intricate UUID issues, a new user must follow this procedure when joining the server:

1. Disable the server whitelist in the console;
2. After the player joins, add the player to the whitelist in the console;
3. Re-enable the server whitelist in the console.

= Mod Selection

== Essential Utility Mods

The following are mods that, in my view, must be installed in any modpack.

- #link("https://modrinth.com/mod/xaeros-minimap", "Xaero's Minimap") and #link("https://modrinth.com/mod/xaeros-world-map/versions", "Xaero's World Map"): provide map features;
- #link("https://modrinth.com/mod/iris", "Iris Shaders"): provides shaders;
- #link("https://modrinth.com/mod/jei", "JEI"): provides convenient crafting recipe lookup, which is an important guide when many mods are installed;
- #link("https://modrinth.com/mod/jade", "Jade"): provides information about a block when the mouse hovers over it.

== Small Mods That Improve the Experience

Here are some mods that improve the experience. They are not strictly necessary, but they are definitely recommended.

- #link("https://modrinth.com/mod/waystones", "Waystones"): teleportation stones;
- #link("https://modrinth.com/mod/natures-compass", "Nature's Compass"): locates biomes; it is very convenient when searching for resources;
- #link("https://modrinth.com/mod/trashslot", "TrashSlot"): a trash slot;
- #link("https://modrinth.com/mod/jump-over-fences", "Jump Over Fences"): the player can jump over fences, whereas monsters and animals cannot;
- #link("https://modrinth.com/mod/travelers-titles", "Traveler's Titles"): displays a caption when entering a new biome or dimension, much like the large "LIMGRAVE" text in Elden Ring;
- #link("https://modrinth.com/mod/sophisticated-backpacks", "Sophisticated Backpacks"): sophisticated backpacks;
- #link("https://modrinth.com/mod/distanthorizons", "Distant Horizons"): provides a very large view distance; combined with shaders, it produces a visual quality reminiscent of The Legend of Zelda: Breath of the Wild;
- #link("https://modrinth.com/mod/clientsort", "ClientSort"): organizes inventories and chests;
- #link("https://modrinth.com/mod/yes-steve-model", "YSM"): provides more refined player models and animations; however, it supports only Windows and Linux, so players on macOS can neither see nor use it.

== Large Mods

These are the mods that I mainly intended to play by building this server; they are listed here for reference.

- #link("https://modrinth.com/mod/create", "Create")
- #link("https://modrinth.com/mod/create-aeronautics", "Create: Aeronautics")
- #link("https://modrinth.com/mod/ars-nouveau", "Ars Nouveau")
- #link("https://modrinth.com/mod/bosses-of-mass-destruction", "Bosses of Mass Destruction")
- #link("https://modrinth.com/mod/l_enders-cataclysm", "L_Ender's Cataclysm")
- #link("https://modrinth.com/mod/when-dungeons-arise", "When Dungeons Arise")
- #link("https://modrinth.com/mod/farmers-delight", "Farmer's Delight")
- #link("https://modrinth.com/mod/touhou-little-maid", "Touhou Little Maid")
- #link("https://www.curseforge.com/minecraft/mc-mods/minecolonies", "MineColonies")
- #link("https://www.curseforge.com/minecraft/mc-mods/the-twilight-forest", "The Twilight Forest")

= Installing YSM Models on the Server

YSM models can be found on Bilibili; many people provide modpacks or direct downloads there. After obtaining the models, place them in the `config/yes_steve_model/custom` directory on the server, and they will be available to all players on the server.

= Advertisement

Finally, a brief advertisement: if you would like to join the server and play together, you are welcome to contact me.

])
