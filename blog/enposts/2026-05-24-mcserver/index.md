Setting Up a Minecraft Server
========

Recently I set up a Minecraft server. This server incorporates many mods, and rather than adopting an existing modpack such as ATM10, I selected the mods myself. Since LLM agents will help you doing all the chores, I will not elaborate on the details here and will mention only the high-level choices.

## Version Selection

The main drive for building this server was that I had watched several videos on Bilibili about the *Create: Aeronautics*, so I want to try it. This mod currently supports version 1.21.1 primarily, which is also a version with good mod compatibility at present, so 1.21.1 was the natural choice.

## Client Launcher Selection

The most popular launcher at present is [Prism Launcher](https://prismlauncher.org/). However, this launcher supports only legitimate copies of the game. If you also want friends who have not purchased the game to join with a pirate copy, you need another launcher, such as [PolyMC](https://polymc.org/). The two launchers share a common origin, both being forks of [MultiMC](https://multimc.org/); but their modpacks are not interchangeable and must be packed separately.

As for preparing a modpack, Prism Launcher is more convenient, because it resolves mod dependencies automatically. Therefore, even if you decide to use PolyMC, I recommend installing the mods with Prism Launcher and then copying all the mod jar files into the PolyMC instance.

## Server Selection

After adding many mods, the demands on memory and CPU rise sharply. Memory prices are high at present, and servers with large memory have become especially expensive. If a VPS were used, the expense would be roughly 120 USD per month, which is somewhat difficult to afford. I therefore selected an old second-hand laptop with 16 GB of memory to serve as the server, and rented a VPS costing only 15 yuan per month to act as the public gateway. In this way, the server is quite cheap — no more than the cost of a meal each month.

## Creating a Server-Side Modpack

Adding mods on the client side is very simple. But on the server side it's a little tricky, the mod API chosen is NeoForge, so first download the installer from the [NeoForge website](https://neoforged.net/), run it, and choose to install the server. Then open the client instance directory, locate the `mods/` directory inside it, and copy all the jar files into the mods directory of NeoForge.

It is recommended to test the functions in single-player mode before starting the server, because once the server is running and a problem such as incompatibility is discovered, updating becomes very troublesome: all users must upgrade together.

## Supporting Both Legitimate and Pirate Players

To allow players without legitimate copies to join, the server is set to offline mode. By default, however, the skins and capes of players on an offline-mode server cannot be displayed, so the mod [TrueUUID](https://modrinth.com/mod/trueuuid) must be added. In addition, to prevent identity impersonation, a login feature is necessary; here I recommend [NedoLogin](https://modrinth.com/mod/nedologin). For the sake of server security, it is also recommended to enable the whitelist.

Because of some intricate UUID issues, a new user must follow this procedure when joining the server:

1. Disable the server whitelist in the console;
2. After the player joins, add the player to the whitelist in the console;
3. Re-enable the server whitelist in the console.

## Selecting Mods

### Essential Utility Mods

The following are mods that, in my view, must be installed in any modpack.

- [Xaero's Minimap](https://modrinth.com/mod/xaeros-minimap) and [Xaero's World Map](https://modrinth.com/mod/xaeros-world-map/versions): provide map features;
- [Iris Shaders](https://modrinth.com/mod/iris): provides shaders;
- [JEI](https://modrinth.com/mod/jei): provides convenient crafting recipe lookup, which is an important guide when many mods are installed;
- [Jade](https://modrinth.com/mod/jade): provides information about a block when the mouse hovers over it.

### Small Mods That Improve the Experience

Here are some mods that improve the experience. They are not strictly necessary, but they are definitely recommended.

- [Waystones](https://modrinth.com/mod/waystones): teleportation stones;
- [Nature's Compass](https://modrinth.com/mod/natures-compass): locates biomes; it is very convenient when searching for resources;
- [TrashSlot](https://modrinth.com/mod/trashslot): a trash slot;
- [Jump Over Fences](https://modrinth.com/mod/jump-over-fences): the player can jump over fences, whereas monsters and animals cannot;
- [Traveler's Titles](https://modrinth.com/mod/travelers-titles): displays a caption when entering a new biome or dimension, much like the large "LIMGRAVE" text in Elden Ring;
- [Sophisticated Backpacks](https://modrinth.com/mod/sophisticated-backpacks): sophisticated backpacks;
- [Distant Horizons](https://modrinth.com/mod/distanthorizons): provides a very large view distance; combined with shaders, it produces a visual quality reminiscent of The Legend of Zelda: Breath of the Wild;
- [ClientSort](https://modrinth.com/mod/clientsort): organizes inventories and chests;
- [YSM](https://modrinth.com/mod/yes-steve-model): provides more refined player models and animations; however, it supports only Windows and Linux, so players on macOS can neither see nor use it.

### Large Mods

These are the mods that I mainly intended to play; they are listed here for reference.

- [Create](https://modrinth.com/mod/create)
- [Create: Aeronautics](https://modrinth.com/mod/create-aeronautics)
- [Ars Nouveau](https://modrinth.com/mod/ars-nouveau)
- [Bosses of Mass Destruction](https://modrinth.com/mod/bosses-of-mass-destruction)
- [L_Ender's Cataclysm](https://modrinth.com/mod/l_enders-cataclysm)
- [When Dungeons Arise](https://modrinth.com/mod/when-dungeons-arise)
- [Farmer's Delight](https://modrinth.com/mod/farmers-delight)
- [Touhou Little Maid](https://modrinth.com/mod/touhou-little-maid)
- [MineColonies](https://www.curseforge.com/minecraft/mc-mods/minecolonies)
- [The Twilight Forest](https://www.curseforge.com/minecraft/mc-mods/the-twilight-forest)

## Installing YSM Models on the Server

YSM models can be found on Bilibili; many people provide modpacks or direct downloads there. After obtaining the models, place them in the `config/yes_steve_model/custom` directory on the server, and they will be available to all players on the server.

## Advertisement

Finally, a brief advertisement: if you would like to join the server and play together, you are welcome to contact me.
