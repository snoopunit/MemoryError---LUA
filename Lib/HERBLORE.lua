local API = require("api")
local UTILS = require("UTILS")
local MISC = require("lib/MISC")
local BANK = require("lib/BANKING")

local Herblore = {}

OBJECTS = {
    Portable_Well = { Name = "Portable Well", ID = 89770 }
}

POTIONS = {
    -- Unfinished potions
    Guam_Potion_Unfinished = { Name = "Guam potion (unfinished)", ID = 91 },
    Marrentill_Potion_Unfinished = { Name = "Marrentill potion (unfinished)", ID = 93 },
    Tarromin_Potion_Unfinished = { Name = "Tarromin potion (unfinished)", ID = 95 },
    Harralander_Potion_Unfinished = { Name = "Harralander potion (unfinished)", ID = 97 },
    Ranarr_Potion_Unfinished = { Name = "Ranarr potion (unfinished)", ID = 99 },
    Irit_Potion_Unfinished = { Name = "Irit potion (unfinished)", ID = 101 },
    Avantoe_Potion_Unfinished = { Name = "Avantoe potion (unfinished)", ID = 103 },
    Kwuarm_Potion_Unfinished = { Name = "Kwuarm potion (unfinished)", ID = 105 },
    Cadantine_Potion_Unfinished = { Name = "Cadantine potion (unfinished)", ID = 107 },
    Dwarf_Weed_Potion_Unfinished = { Name = "Dwarf weed potion (unfinished)", ID = 109 },
    Torstol_Potion_Unfinished = { Name = "Torstol potion (unfinished)", ID = 111 },
    Snapdragon_Potion_Unfinished = { Name = "Snapdragon potion (unfinished)", ID = 3004 },
    Toadflax_Potion_Unfinished = { Name = "Toadflax potion (unfinished)", ID = 3002 },
    Spirit_Weed_Potion_Unfinished = { Name = "Spirit weed potion (unfinished)", ID = 12181 },
    Lantadyme_Potion_Unfinished = { Name = "Lantadyme potion (unfinished)", ID = 2483 },
    Wergali_Potion_Unfinished = { Name = "Wergali potion (unfinished)", ID = 14856 },
    Rogue_Purse_Potion_Unfinished = { Name = "Rogue purse potion (unfinished)", ID = 4840 },
    Fellstalk_Potion_Unfinished = { Name = "Fellstalk potion (unfinished)", ID = 21628 },
    Argway_Potion_Unfinished = { Name = "Argway potion (unfinished)", ID = 20000 },
    Shengo_Potion_Unfinished = { Name = "Shengo potion (unfinished)", ID = 20001 },
    Samaden_Potion_Unfinished = { Name = "Samaden potion (unfinished)", ID = 20002 },
    Ugune_Potion_Unfinished = { Name = "Ugune potion (unfinished)", ID = 19999 },
    Erzille_Potion_Unfinished = { Name = "Erzille potion (unfinished)", ID = 19998 },
    Sagewort_Potion_Unfinished = { Name = "Sagewort potion (unfinished)", ID = 17538 },
    Valerian_Potion_Unfinished = { Name = "Valerian potion (unfinished)", ID = 17540 },
    Aloe_Potion_Unfinished = { Name = "Aloe potion (unfinished)", ID = 17542 },
    Wormwood_Potion_Unfinished = { Name = "Wormwood potion (unfinished)", ID = 17544 },
    Magebane_Potion_Unfinished = { Name = "Magebane potion (unfinished)", ID = 17546 },
    Featherfoil_Potion_Unfinished = { Name = "Featherfoil potion (unfinished)", ID = 17548 },
    Winters_Grip_Potion_Unfinished = { Name = "Winter's grip potion (unfinished)", ID = 17550 },
    Lycopus_Potion_Unfinished = { Name = "Lycopus potion (unfinished)", ID = 17552 },
    Buckthorn_Potion_Unfinished = { Name = "Buckthorn potion (unfinished)", ID = 17554 },
    Arbuck_Potion_Unfinished = { Name = "Arbuck potion (unfinished)", ID = 48241 },
    Bloodweed_Potion_Unfinished = { Name = "Bloodweed potion (unfinished)", ID = 37973 },

    -- Finished potions (3-dose, main)
    Strength_Potion_3 = { Name = "Strength potion (3)", ID = 115 },
    Attack_Potion_3 = { Name = "Attack potion (3)", ID = 121 },
    Restore_Potion_3 = { Name = "Restore potion (3)", ID = 127 },
    Defence_Potion_3 = { Name = "Defence potion (3)", ID = 133 },
    Prayer_Potion_3 = { Name = "Prayer potion (3)", ID = 139 },
    Super_Attack_3 = { Name = "Super attack (3)", ID = 145 },
    Fishing_Potion_3 = { Name = "Fishing potion (3)", ID = 151 },
    Super_Strength_3 = { Name = "Super strength (3)", ID = 157 },
    Super_Defence_3 = { Name = "Super defence (3)", ID = 163 },
    Super_Ranging_Potion_3 = { Name = "Super ranging potion (3)", ID = 169 },
    Antipoison_3 = { Name = "Antipoison (3)", ID = 175 },
    Super_Antipoison_3 = { Name = "Super antipoison (3)", ID = 181 },
    Zamorak_Brew_3 = { Name = "Zamorak brew (3)", ID = 189 },
    Bravery_Potion = { Name = "Bravery potion", ID = 739 },
    Blamish_Oil = { Name = "Blamish oil", ID = 1582 },
    Antifire_3 = { Name = "Antifire potion (3)", ID = 2454 },
    Energy_Potion_3 = { Name = "Energy potion (3)", ID = 3010 },
    Super_Energy_3 = { Name = "Super energy (3)", ID = 3018 },
    Super_Restore_3 = { Name = "Super restore (3)", ID = 3026 },
    Agility_Potion_3 = { Name = "Agility potion (3)", ID = 3034 },
    Super_Magic_Potion_3 = { Name = "Super magic potion (3)", ID = 3042 },
    Serum_207_3 = { Name = "Serum 207 (3)", ID = 3410 },
    Guthix_Rest_3 = { Name = "Guthix rest (3)", ID = 4419 },
    Relicyms_Balm_3 = { Name = "Relicym's balm (3)", ID = 4844 },
    Weapon_Poison_Plus_Unfinished = { Name = "Weapon poison+ (unfinished)", ID = 5936 },
    Weapon_Poison_PlusPlus_Unfinished = { Name = "Weapon poison++ (unfinished)", ID = 5939 },
    Antipoison_Plus_Unfinished = { Name = "Antipoison+ (unfinished)", ID = 5942 },
    Antipoison_Plus_4 = { Name = "Antipoison+ (4)", ID = 5943 },
    Antipoison_PlusPlus_Unfinished = { Name = "Antipoison++ (unfinished)", ID = 5951 },
    Antipoison_PlusPlus_4 = { Name = "Antipoison++ (4)", ID = 5952 },
    Saradomin_Brew_3 = { Name = "Saradomin brew (3)", ID = 6687 },
    Magic_Essence_3 = { Name = "Magic essence (3)", ID = 9022 },
    Combat_Potion_3 = { Name = "Combat potion (3)", ID = 9741 },
    Hunter_Potion_3 = { Name = "Hunter potion (3)", ID = 10000 },
    Summoning_Potion_3 = { Name = "Summoning potion (3)", ID = 12142 },
    Super_Fishing_Explosive = { Name = "Super fishing explosive", ID = 12633 },
    Crafting_Potion_3 = { Name = "Crafting potion (3)", ID = 14840 },
    Fletching_Potion_3 = { Name = "Fletching potion (3)", ID = 14848 },
    Adrenaline_Potion_3 = { Name = "Adrenaline potion (3)", ID = 15301 },
    Super_Antifire_3 = { Name = "Super antifire (3)", ID = 15305 },
    Extreme_Attack_3 = { Name = "Extreme attack (3)", ID = 15309 },
    Extreme_Strength_3 = { Name = "Extreme strength (3)", ID = 15313 },
    Extreme_Defence_3 = { Name = "Extreme defence (3)", ID = 15317 },
    Extreme_Magic_3 = { Name = "Extreme magic (3)", ID = 15321 },
    Extreme_Ranging_3 = { Name = "Extreme ranging (3)", ID = 15325 },
    Super_Prayer_3 = { Name = "Super prayer (3)", ID = 15329 },
    Overload_3 = { Name = "Overload (3)", ID = 15333 },
    Weak_Magic_Potion = { Name = "Weak magic potion", ID = 17556 },
    Weak_Ranged_Potion = { Name = "Weak ranged potion", ID = 17558 },
    Weak_Melee_Potion = { Name = "Weak melee potion", ID = 17560 },
    Weak_Defence_Potion = { Name = "Weak defence potion", ID = 17562 },
    Weak_Stat_Restore_Potion = { Name = "Weak stat restore potion", ID = 17564 },
    Weak_Cure_Potion = { Name = "Weak cure potion", ID = 17568 },
    Weak_Rejuvenation_Potion = { Name = "Weak rejuvenation potion", ID = 17570 },
    Weak_Weapon_Poison = { Name = "Weak weapon poison", ID = 17572 },
    Weak_Gatherers_Potion = { Name = "Weak gatherer's potion", ID = 17574 },
    Weak_Artisans_Potion = { Name = "Weak artisan's potion", ID = 17576 },
    Weak_Naturalists_Potion = { Name = "Weak naturalist's potion", ID = 17578 },
    Weak_Survivalists_Potion = { Name = "Weak survivalist's potion", ID = 17580 },
    Magic_Potion = { Name = "Magic potion", ID = 17582 },
    Ranged_Potion = { Name = "Ranged potion", ID = 17584 },
    Melee_Potion = { Name = "Melee potion", ID = 17586 },
    Defence_Potion = { Name = "Defence potion", ID = 17588 },
    Stat_Restore_Potion = { Name = "Stat restore potion", ID = 17590 },
    Cure_Potion = { Name = "Cure potion", ID = 17592 },
    Rejuvenation_Potion = { Name = "Rejuvenation potion", ID = 17594 },
    Weapon_Poison = { Name = "Weapon poison", ID = 17596 },
    Gatherers_Potion = { Name = "Gatherer's potion", ID = 17598 },
    Artisans_Potion = { Name = "Artisan's potion", ID = 17600 },
    Naturalists_Potion = { Name = "Naturalist's potion", ID = 17602 },
    Survivalists_Potion = { Name = "Survivalist's potion", ID = 17604 },
    Strong_Magic_Potion = { Name = "Strong magic potion", ID = 17606 },
    Strong_Ranged_Potion = { Name = "Strong ranged potion", ID = 17608 },
    Strong_Melee_Potion = { Name = "Strong melee potion", ID = 17610 },
    Strong_Defence_Potion = { Name = "Strong defence potion", ID = 17612 },
    Strong_Stat_Restore_Potion = { Name = "Strong stat restore potion", ID = 17614 },
    Strong_Cure_Potion = { Name = "Strong cure potion", ID = 17616 },
    Strong_Rejuvenation_Potion = { Name = "Strong rejuvenation potion", ID = 17618 },
    Strong_Weapon_Poison = { Name = "Strong weapon poison", ID = 17620 },
    Strong_Gatherers_Potion = { Name = "Strong gatherer's potion", ID = 17622 },
    Strong_Artisans_Potion = { Name = "Strong artisan's potion", ID = 17624 },
    Strong_Naturalists_Potion = { Name = "Strong naturalist's potion", ID = 17626 },
    Strong_Survivalists_Potion = { Name = "Strong survivalist's potion", ID = 17628 },
    Juju_Mining_Potion_3 = { Name = "Juju mining potion (3)", ID = 20004 },
    Juju_Cooking_Potion_3 = { Name = "Juju cooking potion (3)", ID = 20008 },
    Juju_Farming_Potion_3 = { Name = "Juju farming potion (3)", ID = 20012 },
    Juju_Woodcutting_Potion_3 = { Name = "Juju woodcutting potion (3)", ID = 20016 },
    Juju_Fishing_Potion_3 = { Name = "Juju fishing potion (3)", ID = 20020 },
    Juju_Hunter_Potion_3 = { Name = "Juju hunter potion (3)", ID = 20024 },
    Scentless_Potion_3 = { Name = "Scentless potion (3)", ID = 20028 },
    Saradomins_Blessing_3 = { Name = "Saradomin's blessing (3)", ID = 20032 },
    Guthixs_Gift_3 = { Name = "Guthix's gift (3)", ID = 20036 },
    Zamoraks_Favour_3 = { Name = "Zamorak's favour (3)", ID = 20040 },
    Prayer_Renewal_3 = { Name = "Prayer renewal (3)", ID = 21632 },
    Weapon_Poison_3 = { Name = "Weapon poison (3)", ID = 25487 },
    Weapon_PoisonPlus_3 = { Name = "Weapon poison+ (3)", ID = 25495 },
    Weapon_PoisonPlusPlus_3 = { Name = "Weapon poison++ (3)", ID = 25503 },
    Strength_Potion_4 = { Name = "Strength potion (4)", ID = 25569 },
    Ranging_Mix_2 = { Name = "Ranging mix (2)", ID = 27496 },
    Magic_Mix_2 = { Name = "Magic mix (2)", ID = 27500 },
    Ranging_Potion_3 = { Name = "Ranging potion (3)", ID = 27506 },
    Magic_Potion_3 = { Name = "Magic potion (3)", ID = 27514 },
    Super_Saradomin_Brew_3 = { Name = "Super saradomin brew (3)", ID = 28193 },
    Super_Zamorak_Brew_3 = { Name = "Super zamorak brew (3)", ID = 28201 },
    Super_Guthix_Rest_3 = { Name = "Super guthix rest (3)", ID = 28209 },
    Perfect_Juju_Woodcutting_Potion_3 = { Name = "Perfect juju woodcutting potion (3)", ID = 32757 },
    Perfect_Juju_Farming_Potion_3 = { Name = "Perfect juju farming potion (3)", ID = 32765 },
    Perfect_Juju_Mining_Potion_3 = { Name = "Perfect juju mining potion (3)", ID = 32773 },
    Perfect_Juju_Smithing_Potion_3 = { Name = "Perfect juju smithing potion (3)", ID = 32781 },
    Perfect_Juju_Agility_Potion_3 = { Name = "Perfect juju agility potion (3)", ID = 32789 },
    Perfect_Juju_Prayer_Potion_3 = { Name = "Perfect juju prayer potion (3)", ID = 32797 },
    Perfect_Juju_Herblore_Potion_3 = { Name = "Perfect juju herblore potion (3)", ID = 32805 },
    Perfect_Juju_Dungeoneering_Potion_3 = { Name = "Perfect juju dungeoneering potion (3)", ID = 32813 },
    Grand_Strength_Potion_6 = { Name = "Grand strength potion (6)", ID = 32958 },
    Grand_Ranging_Potion_6 = { Name = "Grand ranging potion (6)", ID = 32970 },
    Grand_Magic_Potion_6 = { Name = "Grand magic potion (6)", ID = 32982 },
    Grand_Attack_Potion_6 = { Name = "Grand attack potion (6)", ID = 32994 },
    Grand_Defence_Potion_6 = { Name = "Grand defence potion (6)", ID = 33006 },
    Super_Melee_Potion_6 = { Name = "Super melee potion (6)", ID = 33018 },
    Super_Warmasters_Potion_6 = { Name = "Super warmaster's potion (6)", ID = 33030 },
    Replenishment_Potion_6 = { Name = "Replenishment potion (6)", ID = 33042 },
    Wyrmfire_Potion_6 = { Name = "Wyrmfire potion (6)", ID = 33054 },
    Extreme_Brawlers_Potion_6 = { Name = "Extreme brawler's potion (6)", ID = 33066 },
    Extreme_Battlemages_Potion_6 = { Name = "Extreme battlemage's potion (6)", ID = 33078 },
    Extreme_Sharpshooters_Potion_6 = { Name = "Extreme sharpshooter's potion (6)", ID = 33090 },
    Extreme_Warmasters_Potion_6 = { Name = "Extreme warmaster's potion (6)", ID = 33102 },
    Supreme_Strength_Potion_6 = { Name = "Supreme strength potion (6)", ID = 33114 },
    Supreme_Attack_Potion_6 = { Name = "Supreme attack potion (6)", ID = 33126 },
    Supreme_Defence_Potion_6 = { Name = "Supreme defence potion (6)", ID = 33138 },
    Supreme_Magic_Potion_6 = { Name = "Supreme magic potion (6)", ID = 33150 },
    Supreme_Ranging_Potion_6 = { Name = "Supreme ranging potion (6)", ID = 33162 },
    Brightfire_Potion_6 = { Name = "Brightfire potion (6)", ID = 33174 },
    Super_Prayer_Renewal_Potion_6 = { Name = "Super prayer renewal potion (6)", ID = 33186 },
    Overload_Salve_6 = { Name = "Overload salve (6)", ID = 33198 },
    Supreme_Overload_Potion_6 = { Name = "Supreme overload potion (6)", ID = 33210 },
    Supreme_Overload_Salve_6 = { Name = "Supreme overload salve (6)", ID = 33222 },
    Perfect_Plus_Potion_6 = { Name = "Perfect plus potion (6)", ID = 33234 },
    Holy_Overload_Potion_6 = { Name = "Holy overload potion (6)", ID = 33246 },
    Searing_Overload_Potion_6 = { Name = "Searing overload potion (6)", ID = 33258 },
    Perfect_Juju_Fishing_Potion_3 = { Name = "Perfect juju fishing potion (3)", ID = 35739 },
    Extreme_Guthix_Balance = { Name = "Extreme guthix balance", ID = 37273 },
    Camouflage_Potion_3 = { Name = "Camouflage potion (3)", ID = 37957 },
    Luck_Potion = { Name = "Luck potion", ID = 37963 },
    Aggression_Potion_3 = { Name = "Aggression potion (3)", ID = 37969 },
    Super_Adrenaline_Potion_3 = { Name = "Super adrenaline potion (3)", ID = 39214 },
    Enhanced_Replenishment_Potion_6 = { Name = "Enhanced replenishment potion (6)", ID = 39230 },
    Enhanced_Luck_Potion = { Name = "Enhanced luck potion", ID = 39820 },
    Divination_Potion_3 = { Name = "Divination potion (3)", ID = 44047 },
    Runecrafting_Potion_3 = { Name = "Runecrafting potion (3)", ID = 44055 },
    Invention_Potion_3 = { Name = "Invention potion (3)", ID = 44063 },
    Super_Divination_3 = { Name = "Super divination (3)", ID = 44071 },
    Super_Runecrafting_3 = { Name = "Super runecrafting (3)", ID = 44079 },
    Super_Invention_3 = { Name = "Super invention (3)", ID = 44087 },
    Super_Hunter_3 = { Name = "Super hunter (3)", ID = 44095 },
    Extreme_Divination_3 = { Name = "Extreme divination (3)", ID = 44103 },
    Extreme_Runecrafting_3 = { Name = "Extreme runecrafting (3)", ID = 44111 },
    Extreme_Invention_3 = { Name = "Extreme invention (3)", ID = 44119 },
    Extreme_Hunter_3 = { Name = "Extreme hunter (3)", ID = 44127 },
    Extended_Super_Antifire_3 = { Name = "Extended super antifire (3)", ID = 48215 },
    Stamina_Potion_3 = { Name = "Stamina potion (3)", ID = 48223 },
    Aggroverload_6 = { Name = "Aggroverload (6)", ID = 48239 },
    Vulnerability_Bomb = { Name = "Vulnerability bomb", ID = 48951 },
    Poison_Bomb = { Name = "Poison bomb", ID = 48954 },
    Sticky_Bomb = { Name = "Sticky bomb", ID = 48957 },
    Harvest_Potion_3 = { Name = "Harvest potion (3)", ID = 48970 },
    Charming_Potion_3 = { Name = "Charming potion (3)", ID = 48986 },
    Cooking_Potion_3 = { Name = "Cooking potion (3)", ID = 48994 },
    Super_Cooking_Potion_3 = { Name = "Super cooking potion (3)", ID = 49002 },
    Extreme_Cooking_Potion_3 = { Name = "Extreme cooking potion (3)", ID = 49010 },
    Spiritual_Prayer_Potion_6 = { Name = "Spiritual prayer potion (6)", ID = 49027 },
    Elder_Overload_Potion_6 = { Name = "Elder overload potion (6)", ID = 49039 },
    Elder_Overload_Salve_6 = { Name = "Elder overload salve (6)", ID = 49052 },
    Powerburst_of_Acceleration_4 = { Name = "Powerburst of acceleration (4)", ID = 49055 },
    Powerburst_of_Sorcery_4 = { Name = "Powerburst of sorcery (4)", ID = 49063 },
    Powerburst_of_Feats_4 = { Name = "Powerburst of feats (4)", ID = 49071 },
    Adrenaline_Renewal_Potion_4 = { Name = "Adrenaline renewal potion (4)", ID = 49079 },
    Powerburst_of_Masterstroke_4 = { Name = "Powerburst of masterstroke (4)", ID = 49087 },
    Powerburst_of_Vitality_4 = { Name = "Powerburst of vitality (4)", ID = 49095 },
    Weapon_Poison_Triple_3 = { Name = "Weapon poison+++ (3)", ID = 49117 },
    Summoning_Renewal_3 = { Name = "Summoning renewal (3)", ID = 50845 },
    Archaeology_Potion_3 = { Name = "Archaeology potion (3)", ID = 50853 },
    Spirit_Attraction_Potion_3 = { Name = "Spirit attraction potion (3)", ID = 50861 },
    Holy_Aggroverload_6 = { Name = "Holy aggroverload (6)", ID = 50877 },
    Powerburst_of_Opportunity_4 = { Name = "Powerburst of opportunity (4)", ID = 50880 },
    Woodcutting_Potion_3 = { Name = "Woodcutting potion (3)", ID = 52428 },
    Mining_Potion_3 = { Name = "Mining potion (3)", ID = 52436 },
    Super_Woodcutting_Potion_3 = { Name = "Super woodcutting potion (3)", ID = 52444 },
    Super_Mining_Potion_3 = { Name = "Super mining potion (3)", ID = 52452 },
    Necromancy_Potion_3 = { Name = "Necromancy potion (3)", ID = 55310 },
    Super_Necromancy_3 = { Name = "Super necromancy (3)", ID = 55318 },
    Extreme_Necromancy_3 = { Name = "Extreme necromancy (3)", ID = 55326 },
    Overload_3_RS3 = { Name = "Overload (3)", ID = 55959 },
    Overload_Salve_6_RS3 = { Name = "Overload salve (6)", ID = 55961 },
    Supreme_Overload_Potion_6_RS3 = { Name = "Supreme overload potion (6)", ID = 55962 },
    Supreme_Overload_Salve_6_RS3 = { Name = "Supreme overload salve (6)", ID = 55964 },
    Elder_Overload_Potion_6_RS3 = { Name = "Elder overload potion (6)", ID = 55965 },
    Elder_Overload_Salve_6_RS3 = { Name = "Elder overload salve (6)", ID = 55967 },

    Water_Vial = { Name = "Vial of water", ID = 227 }
}

INGREDIENTS = {
    Eye_of_Newt = { Name = "Eye of newt", ID = 221 },
    Limpwurt_Root = { Name = "Limpwurt root", ID = 225 },
    Red_Spiders_Eggs = { Name = "Red spiders' eggs", ID = 223 },
    Bear_Fur = { Name = "Bear fur", ID = 948 },
    Snape_Grass = { Name = "Snape grass", ID = 231 },
    White_Berries = { Name = "White berries", ID = 239 },
    Wine_of_Zamorak = { Name = "Wine of Zamorak", ID = 245 },
    Unicorn_Horn_Dust = { Name = "Unicorn horn dust", ID = 235 },
    Jangerberries = { Name = "Jangerberries", ID = 247 },
    Ardrigal_Mixture = { Name = "Ardrigal mixture", ID = 738 },
    Clean_Snake_Weed = { Name = "Clean snake weed", ID = 1526 },
    Blamish_Snail_Slime = { Name = "Blamish snail slime", ID = 1581 },
    Dragon_Scale_Dust = { Name = "Dragon scale dust", ID = 241 },
    Chocolate_Dust = { Name = "Chocolate dust", ID = 1975 },
    Mort_Myre_Fungus = { Name = "Mort myre fungus", ID = 2970 },
    Toads_Legs = { Name = "Toad's legs", ID = 2152 },
    Potato_Cactus = { Name = "Potato cactus", ID = 3138 },
    Ashes = { Name = "Ashes", ID = 592 },
    Caviar = { Name = "Caviar", ID = 11326 },
    Goat_Horn_Dust = { Name = "Goat horn dust", ID = 9736 },
    Kebbit_Teeth_Dust = { Name = "Kebbit teeth dust", ID = 10111 },
    Garlic = { Name = "Garlic", ID = 1550 },
    Silver_Dust = { Name = "Silver dust", ID = 7650 },
    Gorak_Claw_Powder = { Name = "Gorak claw powder", ID = 9018 },
    Pharmakos_Berries = { Name = "Pharmakos berries", ID = 11807 },
    Rubium = { Name = "Rubium", ID = 12630 },
    Frog_Spawn = { Name = "Frog spawn", ID = 5004 },
    Wimpy_Feather = { Name = "Wimpy feather", ID = 11525 },
    Papaya_Fruit = { Name = "Papaya fruit", ID = 5972 },
    Phoenix_Feather = { Name = "Phoenix feather", ID = 4621 },
    Ground_Mud_Runes = { Name = "Ground mud runes", ID = 9594 },
    Grenwall_Spikes = { Name = "Grenwall spikes", ID = 12539 },
    Harmony_Moss = { Name = "Harmony moss", ID = 32947 },
    Wine_of_Saradomin = { Name = "Wine of Saradomin", ID = 28256 },
    Wine_of_Guthix = { Name = "Wine of Guthix", ID = 28253 },
    Chinchompa_Residue = { Name = "Chinchompa residue", ID = 43973 },
    Zygomite_Fruit = { Name = "Zygomite fruit", ID = 43983 },
    Yak_Milk = { Name = "Yak milk", ID = 43989 },
    Spider_Fangs = { Name = "Spider fangs", ID = 43987 },
    Rabbit_Teeth = { Name = "Rabbit teeth", ID = 43985 },
    Yak_Tuft = { Name = "Yak tuft", ID = 43991 },
    Spider_Venom = { Name = "Spider venom", ID = 43997 },
    Mycelial_Webbing = { Name = "Mycelial webbing", ID = 43995 },
    Bull_Horns = { Name = "Bull horns", ID = 43993 },
    Aggression_Potion_4 = { Name = "Aggression potion (4)", ID = 37971 },
    Onyx_Bolt_Tips = { Name = "Onyx bolt tips", ID = 9194 },
    Rabbit_Foot = { Name = "Rabbit foot", ID = 10134 },
    Redberries = { Name = "Redberries", ID = 1951 },
    Harmony_Dust = { Name = "Harmony dust", ID = 35727 },
    Enriched_Fungal_Algae = { Name = "Enriched fungal algae", ID = 52323 },
    Timber_Fungus = { Name = "Timber fungus", ID = 52313 },
    Calcified_Fungus = { Name = "Calcified fungus", ID = 52317 },
    Enriched_Timber_Fungus = { Name = "Enriched timber fungus", ID = 52315 },
    Enriched_Calcified_Fungus = { Name = "Enriched calcified fungus", ID = 52319 },
    Cadava_Berries = { Name = "Cadava berries", ID = 753 },
    Congealed_Blood = { Name = "Congealed blood", ID = 37227 },
    Ground_Miasma_Rune = { Name = "Ground miasma rune", ID = 55697 },
    Primal_Extract = { Name = "Primal extract", ID = 48962 },
    Bomb_Vial = { Name = "Bomb vial", ID = 48961 },
    Bottled_Dinosaur_Roar = { Name = "Bottled dinosaur roar", ID = 48926 },
    Poison_Slime = { Name = "Poison slime", ID = 48921 },
    Beak_Snot = { Name = "Beak snot", ID = 48925 },
    Dinosaur_Claws = { Name = "Dinosaur claws", ID = 48922 },
    Watermelon = { Name = "Watermelon", ID = 5982 },
    Gold_Charm = { Name = "Gold charm", ID = 12158 },
    Green_Charm = { Name = "Green charm", ID = 12159 },
    Crimson_Charm = { Name = "Crimson charm", ID = 12160 },
    Blue_Charm = { Name = "Blue charm", ID = 12163 },
    Spark_Chitin = { Name = "Spark chitin", ID = 48923 },
    Swordfish = { Name = "Swordfish", ID = 373 },
    Adrenaline_Crystal = { Name = "Adrenaline crystal", ID = 39067 },
    Runite_Stone_Spirit = { Name = "Runite stone spirit", ID = 44808 },
    Necrite_Stone_Spirit = { Name = "Necrite stone spirit", ID = 44811 },
    Searing_Ashes = { Name = "Searing ashes", ID = 34159 },
    Crushed_Dragonstone = { Name = "Crushed dragonstone", ID = 37914 },
    Black_Salamander = { Name = "Black salamander", ID = 10148 },
    Poison_Ivy_Berries = { Name = "Poison ivy berries", ID = 6018 },
    Red_Moss = { Name = "Red moss", ID = 17534 },
    Firebreath_Whiskey = { Name = "Firebreath whiskey", ID = 17536 },
    Misshapen_Claw = { Name = "Misshapen claw", ID = 17532 },
    Timeworn_Tincture = { Name = "Timeworn tincture", ID = 50803 },
    Phasmatite = { Name = "Phasmatite", ID = 44828 },
    Third_Age_Iron = { Name = "Third age iron", ID = 49460 },
    Crystal_Flask = { Name = "Crystal flask", ID = 32843 },
    Crystal_Tree_Blossom = { Name = "Crystal tree blossom", ID = 32270 }
}

GRIMY_HERBS = {
    Grimy_Guarm = { Name = "Grimy guam", ID = 199 },
    Grimy_Marrentill = { Name = "Grimy marrentill", ID = 201 },
    Grimy_Tarromin = { Name = "Grimy tarromin", ID = 203 },
    Grimy_Harralander = { Name = "Grimy harralander", ID = 205 },
    Grimy_Ranarr = { Name = "Grimy ranarr", ID = 207 },
    Grimy_Irit = { Name = "Grimy irit", ID = 209 },
    Grimy_Avantoe = { Name = "Grimy avantoe", ID = 211 },
    Grimy_Kwuarm = { Name = "Grimy kwuarm", ID = 213 },
    Grimy_Cadantine = { Name = "Grimy cadantine", ID = 215 },
    Grimy_Dwarf_Weed = { Name = "Grimy dwarf weed", ID = 217 },
    Grimy_Torstol = { Name = "Grimy torstol", ID = 219 },
    Grimy_Snapdragon = { Name = "Grimy snapdragon", ID = 3051 },
    Grimy_Toadflax = { Name = "Grimy toadflax", ID = 3049 },
    Grimy_Spirit_Weed = { Name = "Grimy spirit weed", ID = 12174 },
    Grimy_Lantadyme = { Name = "Grimy lantadyme", ID = 2485 },
    Grimy_Wergali = { Name = "Grimy wergali", ID = 14854 },
    Grimy_Rogue_Purse = { Name = "Grimy rogue purse", ID = 4742 },
    Grimy_Fellstalk = { Name = "Grimy fellstalk", ID = 21626 },
    Grimy_Arbuck = { Name = "Grimy arbuck", ID = 48213 },
    Grimy_Bloodweed = { Name = "Grimy bloodweed", ID = 37975 },
    Grimy_Aloe = { Name = "Grimy aloe", ID = 17544 },
    Grimy_Buckthorn = { Name = "Grimy buckthorn", ID = 17556 },
    Grimy_Magebane = { Name = "Grimy magebane", ID = 17548 },
    Grimy_Featherfoil = { Name = "Grimy featherfoil", ID = 17550 },
    Grimy_Lycopus = { Name = "Grimy lycopus", ID = 17554 },
    Grimy_Winters_Grip = { Name = "Grimy winter's grip", ID = 17552 },
    Grimy_Sagewort = { Name = "Grimy sagewort", ID = 17536 },
    Grimy_Valerian = { Name = "Grimy valerian", ID = 17538 },
    Grimy_Wormwood = { Name = "Grimy wormwood", ID = 17540 },
    Grimy_Samaden = { Name = "Grimy samaden", ID = 20004 },
    Grimy_Shengo = { Name = "Grimy shengo", ID = 20003 },
    Grimy_Ugune = { Name = "Grimy ugune", ID = 20005 },
    Grimy_Erzille = { Name = "Grimy erzille", ID = 20006 },
    Grimy_Argway = { Name = "Grimy argway", ID = 20007 }
}

CLEAN_HERBS = {
    Clean_Guarm = { Name = "Clean guam", ID = 249 },
    Clean_Marrentill = { Name = "Clean marrentill", ID = 251 },
    Clean_Tarromin = { Name = "Clean tarromin", ID = 253 },
    Clean_Harralander = { Name = "Clean harralander", ID = 255 },
    Clean_Ranarr = { Name = "Clean ranarr", ID = 257 },
    Clean_Irit = { Name = "Clean irit", ID = 259 },
    Clean_Avantoe = { Name = "Clean avantoe", ID = 261 },
    Clean_Kwuarm = { Name = "Clean kwuarm", ID = 263 },
    Clean_Cadantine = { Name = "Clean cadantine", ID = 265 },
    Clean_Dwarf_Weed = { Name = "Clean dwarf weed", ID = 267 },
    Clean_Torstol = { Name = "Clean torstol", ID = 269 },
    Clean_Snapdragon = { Name = "Clean snapdragon", ID = 3000 },
    Clean_Toadflax = { Name = "Clean toadflax", ID = 2998 },
    Clean_Spirit_Weed = { Name = "Clean spirit weed", ID = 12172 },
    Clean_Lantadyme = { Name = "Clean lantadyme", ID = 2481 },
    Clean_Wergali = { Name = "Clean wergali", ID = 14836 },
    Clean_Rogue_Purse = { Name = "Clean rogue purse", ID = 4740 },
    Clean_Fellstalk = { Name = "Clean fellstalk", ID = 21624 },
    Clean_Arbuck = { Name = "Clean arbuck", ID = 48211 },
    Clean_Bloodweed = { Name = "Clean bloodweed", ID = 37973 },
    Clean_Aloe = { Name = "Clean aloe", ID = 17542 },
    Clean_Buckthorn = { Name = "Clean buckthorn", ID = 17554 },
    Clean_Magebane = { Name = "Clean magebane", ID = 17546 },
    Clean_Featherfoil = { Name = "Clean featherfoil", ID = 17548 },
    Clean_Lycopus = { Name = "Clean lycopus", ID = 17552 },
    Clean_Winters_Grip = { Name = "Clean winter's grip", ID = 17550 },
    Clean_Sagewort = { Name = "Clean sagewort", ID = 17538 },
    Clean_Valerian = { Name = "Clean valerian", ID = 17540 },
    Clean_Wormwood = { Name = "Clean wormwood", ID = 17544 },
    Clean_Samaden = { Name = "Clean samaden", ID = 20002 },
    Clean_Shengo = { Name = "Clean shengo", ID = 20001 },
    Clean_Ugune = { Name = "Clean ugune", ID = 19999 },
    Clean_Erzille = { Name = "Clean erzille", ID = 19998 },
    Clean_Argway = { Name = "Clean argway", ID = 20000 }
}

GLOBALS = {
    makeUnf = false,
    useSkillcape = false,
    useWell = false,
    potionType = POTIONS.Prayer_Renewal_3,
    potionsMade = 0,
    currentState = "Idle"
}

----METRICS----
function Herblore.metrics()
    local METRICS = {
        {"Current State: ", GLOBALS.currentState},
        {"Potion Type: ", GLOBALS.potionType.Name},
        {"GE Value: ", MISC.fmt(API.GetExchangePrice(GLOBALS.potionType.ID))},
        {"# of potions: ", MISC.fmt(GLOBALS.potionsMade)},
        {"# of potions/hr: ", MISC.fmt(MISC.itemsPerHour(GLOBALS.potionsMade))},
        {"Est. profit: ", MISC.fmt(MISC.EstimatedProfit(GLOBALS.potionType.ID, GLOBALS.potionsMade))},
        {"Est. profit/hr: ", MISC.fmt(MISC.EstimatedProfitPerHour(GLOBALS.potionType.ID, GLOBALS.potionsMade))}
    }
    API.DrawTable(METRICS)
end

function Herblore.updatePotionNum(potionsMade)

    GLOBALS.potionsMade = (GLOBALS.potionsMade + potionsMade)

    Herblore.metrics()

end

function Herblore.updateCurrentState(state)

    GLOBALS.currentState = state

    API.logDebug("Current State: "..GLOBALS.currentState)

    Herblore.metrics()

end
----METRICS----

function Herblore.drawGUI()



    imguiBackground = API.CreateIG_answer()

    imguiBackground.box_name = "imguiBackground"

    imguiBackground.box_start = FFPOINT.new(50, 30, 0)

    imguiBackground.box_size = FFPOINT.new(400, 225, 0)

    imguiBackground.colour = ImColor.new(99, 99, 99, 225)

    imguiBackground.string_value = ""



    potionTypes = { "Prayer renewal (3)", "Saradomin brew (3)", "Super restore (3)", "Overload (3)" }



    local gui_center_x = imguiBackground.box_start.x + (imguiBackground.box_size.x / 2)

    local dropdown_width = 300

    local dropdown_height = 20

    local dropdown_x = gui_center_x - (dropdown_width / 2) - 20

    local dropdown_y = 40 



    potionTypeCombo = API.CreateIG_answer()

    potionTypeCombo.box_name = "Potion Type"

    potionTypeCombo.box_start = FFPOINT.new(dropdown_x, dropdown_y, 0)

    potionTypeCombo.stringsArr = potionTypes

    potionTypeCombo.string_value = potionTypes[1]

    potionTypeCombo.colour = ImColor.new(0, 255, 255)

    potionTypeCombo.tooltip_text = "Choose the potion type you wish to craft."



    --set default potionType 

    local selectedPotionType = potionTypeCombo.string_value

    for key, value in pairs(POTIONS) do

        if value.Name == selectedPotionType then

            GLOBALS.potionType = value

            break

        end

    end



    local checkbox_width = 140

    local checkbox_height = 20

    local checkbox_spacing = 10

    local checkbox_start_x = dropdown_x

    local checkbox_start_y = dropdown_y + dropdown_height + 20  



    useSkillcapeBox = API.CreateIG_answer()

    useSkillcapeBox.box_name = "Use Skillcape"

    useSkillcapeBox.box_start = FFPOINT.new(checkbox_start_x, checkbox_start_y, 0)

    useSkillcapeBox.box_size = FFPOINT.new(checkbox_width, checkbox_height, 0)

    useSkillcapeBox.tooltip_text = "Use Herblore Skillcape effect"

    useSkillcapeBox.box_ticked = GLOBALS.useSkillcape

    useSkillcapeBox.colour = ImColor.new(0, 0, 255)



    useWellBox = API.CreateIG_answer()

    useWellBox.box_name = "Use Well"

    useWellBox.box_start = FFPOINT.new(checkbox_start_x, checkbox_start_y + checkbox_height + checkbox_spacing, 0)

    useWellBox.box_size = FFPOINT.new(checkbox_width, checkbox_height, 0)

    useWellBox.tooltip_text = "Use Portable Well"

    useWellBox.box_ticked = GLOBALS.useWell

    useWellBox.colour = ImColor.new(0, 0, 255)



    makeUnfBox = API.CreateIG_answer()

    makeUnfBox.box_name = "Make UNF"

    makeUnfBox.box_start = FFPOINT.new(checkbox_start_x, checkbox_start_y + (checkbox_height + checkbox_spacing) * 2, 0)

    makeUnfBox.box_size = FFPOINT.new(checkbox_width, checkbox_height, 0)

    makeUnfBox.tooltip_text = "Make unfinished potions"

    makeUnfBox.box_ticked = GLOBALS.makeUnf

    makeUnfBox.colour = ImColor.new(0, 0, 255)



    -- Center START and QUIT buttons

    local button_y = checkbox_start_y + (checkbox_height + checkbox_spacing) * 3 + 10

    local button_width = 80

    local button_height = 30

    local button_spacing = 20

    local total_button_width = button_width * 2 + button_spacing

    local buttons_start_x = gui_center_x - (total_button_width / 2)



    startButton = API.CreateIG_answer()

    startButton.box_name = "START"

    startButton.box_start = FFPOINT.new(buttons_start_x - 40, button_y, 0)

    startButton.box_size = FFPOINT.new(button_width, button_height, 0)

    startButton.colour = ImColor.new(0, 0, 255, 255)

    startButton.tooltip_text = "Start the script."



    quitButton = API.CreateIG_answer()

    quitButton.box_name = "QUIT"

    quitButton.box_start = FFPOINT.new(buttons_start_x + button_width + button_spacing - 20, button_y, 0)

    quitButton.box_size = FFPOINT.new(button_width, button_height, 0)

    quitButton.colour = ImColor.new(0, 0, 255, 255)

    quitButton.tooltip_text = "Close the script."



    API.DrawSquareFilled(imguiBackground)

    API.DrawComboBox(potionTypeCombo)

    API.DrawCheckbox(useSkillcapeBox)

    API.DrawCheckbox(useWellBox)

    API.DrawCheckbox(makeUnfBox)

    API.DrawBox(startButton)

    API.DrawBox(quitButton)



end

function Herblore.clearGUI()

    imguiBackground.remove = true

    potionTypeCombo.remove = true

    useSkillcapeBox.remove = true

    useWellBox.remove = true

    makeUnfBox.remove = true

    startButton.remove = true

    quitButton.remove = true

end

function Herblore.makeVials()

    API.logDebug("Clicking Water Vials...")

    if Inventory:Contains(POTIONS.Water_Vial.ID) then

        if not Inventory:DoAction(POTIONS.Water_Vial.Name,1,API.OFF_ACT_GeneralInterface_route) then

            API.logWarn("Failed to Inventory:DoAction on Water Vials!")

            return false

        else

            return true

        end    

    else

        API.logWarn("No water vials found in inventory!")

        return false

    end

end

function Herblore.mixPotionsAtPortableWell()
    API.logDebug("API.DoAction 'Mix Potions' on 'Portable Well'")
    return API.DoAction_Object1(0x29,API.OFF_ACT_GeneralObject_route0,{ OBJECTS.Portable_Well },50)
end

function Herblore.mixPotionsInventory()
    API.logDebug("Inventory:DoAction 'Mix'")
    return Inventory:DoAction("unfinished", 1, API.OFF_ACT_GeneralInterface_route)
end

function Herblore.cleanHerbs(herbID)
    API.logDebug("Inventory:DoAction 'clean' on ", tostring(herbID))
    return Inventory:DoAction(herbID,1,API.OFF_ACT_GeneralInterface_route)
end

function Herblore.skillCape()

    local cape = Equipment:GetCape()
    if cape and cape.id ~= 0 then
        return Equipment:DoAction(cape.id, 2)
    else
        print("No cape equipped.")
        return false
    end
    
end

end

function Herblore.findGrimyHerbs()

    for x, herb in pairs(GRIMY_HERBS) do
        if Inventory:Contains(herb.Name) then
            API.logDebug("Found Grimy Herb: "..herb.Name)
            return herb
        end
    end

end

function Herblore.makePotions() 

    Herblore.updateCurrentState("Banking...")

    if GLOBALS.makeUnf then

        if BANK.doPreset(1) then

            if not Inventory:IsFull() then
                API.logWarn("Didn't grab a full inventory!")
                API.Write_LoopyLoop(false)
                return
            end

            local herbToClean = Herblore.findGrimyHerbs()

            if herbToClean then

                if GLOBALS.useSkillcape then

                    Herblore.updateCurrentState("Using herblore skillcape...")

                    if not Herblore.skillCape() then
                        API.logWarn("Failed to use herblore skillcape!")
                        API.Write_LoopyLoop(false)
                        return false
                    end

                else

                    Herblore.updateCurrentState("Cleaning herbs...")

                    if Herblore.cleanHerbs(herbToClean.ID) then
                        MISC.doCrafting()
                    else 
                        API.logWarn("Failed to clean herbs!")
                        API.Write_LoopyLoop(false)
                        return false
                    end

                end

            end

            if Herblore.makeVials() then
                Herblore.updateCurrentState("Making unfinished potions...")
                MISC.doCrafting()
            else
                API.logWarn("Shutting down!") 
                API.Write_LoopyLoop(false)
                return     
            end

        else
            API.logWarn("Failed to load preset 1!")
            API.Write_LoopyLoop(false)
            return
        end 

    end

    Herblore.updateCurrentState("Banking...")

    if BANK.doPreset(2) then

        if not Inventory:IsFull() then
            API.logWarn("Didn't grab a full inventory!")
            API.Write_LoopyLoop(false)
            return
        end

        if GLOBALS.useWell then
            Herblore.updateCurrentState("Using Portable Well...")
            if Herblore.mixPotionsAtPortableWell() then
                MISC.doCrafting()
            else
                API.logWarn("Unable to mix at portable well!") 
                API.Write_LoopyLoop(false)
                return
            end
        else
            Herblore.updateCurrentState("Crafting Potions...")
            if Herblore.mixPotionsInventory() then
                MISC.doCrafting()
            else
                API.logWarn("Failed to mix potions in inventory!")
                API.Write_LoopyLoop(false)
                return
            end
        end
    else    
        API.logWarn("Failed to load secondary preset!")
        API.Write_LoopyLoop(false)
        return
    end

    Herblore.updateCurrentState("Updating METRICS")
    Herblore.updatePotionNum(Inventory:GetItemAmount(GLOBALS.potionType.Name))
    Herblore.metrics()

end 

function startHerbloreRoutine()

    while GLOBALS.currentState == "Idle" do

        if potionTypeCombo.return_click then
            potionTypeCombo.return_click = false
            local selectedPotionType = potionTypeCombo.string_value
            for key, value in pairs(POTIONS) do
                if value.Name == selectedPotionType then
                    GLOBALS.potionType = value
                    break
                end
            end
            API.logDebug("Selected Potion Type: "..GLOBALS.potionType.Name)
        end

        if useSkillcapeBox.return_click then
            useSkillcapeBox.return_click = false
            GLOBALS.useSkillcape = useSkillcapeBox.box_ticked
            API.logDebug("Use Skillcape: "..tostring(useSkillcapeBox.box_ticked))
        end

        if useWellBox.return_click then
            useWellBox.return_click = false
            GLOBALS.useWell = useWellBox.box_ticked
            API.logDebug("Use Well: "..tostring(useWellBox.box_ticked))
        end

        if makeUnfBox.return_click then
            makeUnfBox.return_click = false
            GLOBALS.makeUnf = makeUnfBox.box_ticked
            API.logDebug("Make UNF: "..tostring(makeUnfBox.box_ticked))
        end

        if startButton.return_click then
            startButton.return_click = false
            if GLOBALS.potionType == "None" then
                API.logWarn("Potion Type not selected!")
            else
                Herblore.clearGUI()
                Herblore.updateCurrentState("Starting...")
            end

        end

        if quitButton.return_click then
            API.Write_LoopyLoop(false)
            return
        end

        API.RandomSleep2(250,0,250)

    end

    if GLOBALS.currentState ~= "Idle" then
        Herblore.makePotions()
    end

end

return Herblore