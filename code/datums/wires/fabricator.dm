#define AUTOLATHE_HACK_WIRE    1
#define AUTOLATHE_SHOCK_WIRE   2
#define AUTOLATHE_DISABLE_WIRE 4

/datum/wires/fabricator

	holder_type = /obj/machinery/fabricator
	wire_count = 6
	descriptions = list(
		new /datum/wire_description(AUTOLATHE_HACK_WIRE, "This wire appears to lead to an auxiliary data storage unit."),
		new /datum/wire_description(AUTOLATHE_SHOCK_WIRE, "This wire seems to be carrying a heavy current."),
		new /datum/wire_description(AUTOLATHE_DISABLE_WIRE, "This wire is connected to the power switch.", SKILL_EXPERIENCED)
	)

/datum/wires/fabricator/GetInteractWindow(mob/user)
	var/obj/machinery/fabricator/A = holder
	. += ..()
	. += "<BR>The red light is [(A.fab_status_flags & FAB_DISABLED) ? "off" : "on"]."
	. += "<BR>The green light is [(A.fab_status_flags & FAB_SHOCKED) ? "off" : "on"]."
	. += "<BR>The blue light is [(A.fab_status_flags & FAB_HACKED) ? "off" : "on"].<BR>"

/datum/wires/fabricator/CanUse()
	var/obj/machinery/fabricator/A = holder
	if(A.panel_open)
		return 1
	return 0

/datum/wires/fabricator/UpdateCut(index, mended)
	var/obj/machinery/fabricator/A = holder
	switch(index)
		if(AUTOLATHE_HACK_WIRE)
			if(mended)
				A.fab_status_flags &= ~FAB_HACKED
			else
				A.fab_status_flags |= FAB_HACKED

			A.update_tgui_static_data_for_all_viewers()
		if(AUTOLATHE_SHOCK_WIRE)
			if(mended)
				A.fab_status_flags &= ~FAB_SHOCKED
			else
				A.fab_status_flags |= FAB_SHOCKED
		if(AUTOLATHE_DISABLE_WIRE)
			if(mended)
				A.fab_status_flags &= ~FAB_DISABLED
			else
				A.fab_status_flags |= FAB_DISABLED
				SStgui.close_uis(A)



/datum/wires/fabricator/UpdatePulsed(index)
	if(IsIndexCut(index))
		return
	var/obj/machinery/fabricator/A = holder
	switch(index)
		if(AUTOLATHE_HACK_WIRE)
			if(A.fab_status_flags & FAB_HACKED)
				A.fab_status_flags &= ~FAB_HACKED
			else
				A.fab_status_flags |= FAB_HACKED

			A.update_tgui_static_data_for_all_viewers()

			spawn(50)
				if(A && !IsIndexCut(index))
					A.fab_status_flags &= ~FAB_HACKED
					A.update_tgui_static_data_for_all_viewers()
					Interact(usr)
		if(AUTOLATHE_SHOCK_WIRE)
			if(A.fab_status_flags & FAB_SHOCKED)
				A.fab_status_flags &= ~FAB_SHOCKED
			else
				A.fab_status_flags |= FAB_SHOCKED
			spawn(50)
				if(A && !IsIndexCut(index))
					A.fab_status_flags &= ~FAB_SHOCKED
					Interact(usr)
		if(AUTOLATHE_DISABLE_WIRE)
			if(A.fab_status_flags & FAB_DISABLED)
				A.fab_status_flags &= ~FAB_DISABLED
			else
				A.fab_status_flags |= FAB_DISABLED
				SStgui.close_uis(A)

			spawn(50)
				if(A && !IsIndexCut(index))
					A.fab_status_flags &= ~FAB_DISABLED
					Interact(usr)

#undef AUTOLATHE_HACK_WIRE
#undef AUTOLATHE_SHOCK_WIRE
#undef AUTOLATHE_DISABLE_WIRE
