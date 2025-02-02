// Stuff worn on the ears. Items here go in the "ears" category but they must not use
// the slot_r_ear or slot_l_ear as the slot, or else players will spawn with no headset.
/datum/gear/ears
	category = GEAR_CATEGORY_EARWEAR
	abstract_type = /datum/gear/ears

/datum/gear/ears/earmuffs
	display_name = "earmuffs"
	path = /obj/item/clothing/ears/earmuffs

/datum/gear/ears/headphones
	display_name = "headphones"
	path = /obj/item/clothing/ears/headphones

/datum/gear/ears/earrings
	display_name = "earrings"
	path = /obj/item/clothing/ears/earring

/datum/gear/ears/earrings/New()
	..()
	var/earrings = list()
	earrings["stud, pearl"] = /obj/item/clothing/ears/earring/stud
	earrings["stud, glass"] = /obj/item/clothing/ears/earring/stud/glass
	earrings["stud, wood"] = /obj/item/clothing/ears/earring/stud/wood
	earrings["stud, iron"] = /obj/item/clothing/ears/earring/stud/iron
	earrings["stud, steel"] = /obj/item/clothing/ears/earring/stud/steel
	earrings["stud, silver"] = /obj/item/clothing/ears/earring/stud/silver
	earrings["stud, gold"] = /obj/item/clothing/ears/earring/stud/gold
	earrings["stud, platinum"] = /obj/item/clothing/ears/earring/stud/platinum
	earrings["stud, diamond"] = /obj/item/clothing/ears/earring/stud/diamond
	earrings["dangle, glass"] = /obj/item/clothing/ears/earring/dangle/glass
	earrings["dangle, wood"] = /obj/item/clothing/ears/earring/dangle/wood
	earrings["dangle, iron"] = /obj/item/clothing/ears/earring/dangle/iron
	earrings["dangle, steel"] = /obj/item/clothing/ears/earring/dangle/steel
	earrings["dangle, silver"] = /obj/item/clothing/ears/earring/dangle/silver
	earrings["dangle, gold"] = /obj/item/clothing/ears/earring/dangle/gold
	earrings["dangle, platinum"] = /obj/item/clothing/ears/earring/dangle/platinum
	earrings["dangle, diamond"] = /obj/item/clothing/ears/earring/dangle/diamond
	gear_tweaks += new/datum/gear_tweak/path(earrings)

/datum/gear/ears/skrell
	abstract_type = /datum/gear/ears/skrell
	whitelisted = list(SPECIES_SKRELL)

/datum/gear/ears/skrell/bands
	display_name = "headtail band (Skrell)"
	path = /obj/item/clothing/ears/skrell/band
	flags = GEAR_HAS_SUBTYPE_SELECTION

/datum/gear/ears/skrell/chains
	display_name = "headtail chain (Skrell)"
	path = /obj/item/clothing/ears/skrell/chain
	flags = GEAR_HAS_SUBTYPE_SELECTION

/datum/gear/ears/skrell/colored
	abstract_type = /datum/gear/ears/skrell/colored
	flags = GEAR_HAS_COLOR_SELECTION

/datum/gear/ears/skrell/colored/chain
	display_name = "headtail chain, colored (Skrell)"
	path = /obj/item/clothing/ears/skrell/colored/chain

/datum/gear/ears/skrell/colored/band
	display_name = "headtail band, colored (Skrell)"
	path = /obj/item/clothing/ears/skrell/colored/band

/datum/gear/ears/skrell/cloth
	abstract_type = /datum/gear/ears/skrell/cloth
	flags = GEAR_HAS_COLOR_SELECTION

/datum/gear/ears/skrell/cloth/male
	display_name = "headtail cloth, male (Skrell)"
	path = /obj/item/clothing/ears/skrell/cloth_male

/datum/gear/ears/skrell/cloth/female
	display_name = "headtail cloth, female (Skrell)"
	path = /obj/item/clothing/ears/skrell/cloth_female
