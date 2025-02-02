#define EMITTER_DAMAGE_POWER_TRANSFER 450 //used to transfer power to containment field generators

/obj/machinery/power/emitter
	name = "emitter"
	desc = "A massive, heavy-duty industrial laser. This design is a fixed installation, capable of shooting in only one direction."
	icon = 'icons/obj/machines/power/emitter.dmi'
	icon_state = "emitter"
	anchored = FALSE
	density = TRUE
	active_power_usage = 100 KILOWATTS
	obj_flags = OBJ_FLAG_ROTATABLE | OBJ_FLAG_ANCHORABLE

	/// Access required to lock or unlock the emitter. Separate variable to prevent `req_access` from blocking use of the emitter while unlocked.
	var/list/req_lock_access = list(access_engine_equip)
	var/efficiency = 0.3	// Energy efficiency. 30% at this time, so 100kW load means 30kW laser pulses.
	var/active = FALSE
	var/powered = FALSE
	var/fire_delay = 10 SECONDS
	var/max_burst_delay = 10 SECONDS
	var/min_burst_delay = 2 SECONDS
	var/burst_shots = 3
	var/last_shot = 0
	var/shot_number = 0
	var/state = EMITTER_LOOSE
	var/locked = FALSE
	core_skill = SKILL_ENGINES

	uncreated_component_parts = list(
		/obj/item/stock_parts/radio/receiver,
		/obj/item/stock_parts/power/apc
	)
	public_variables = list(
		/singleton/public_access/public_variable/emitter_active,
		/singleton/public_access/public_variable/emitter_locked
	)
	public_methods = list(
		/singleton/public_access/public_method/toggle_emitter
	)
	stock_part_presets = list(/singleton/stock_part_preset/radio/receiver/emitter = 1)

/obj/machinery/power/emitter/anchored
	anchored = TRUE
	state = EMITTER_WELDED

/obj/machinery/power/emitter/anchored/on
	active = TRUE
	powered = TRUE

/obj/machinery/power/emitter/Initialize()
	. = ..()
	if (state == EMITTER_WELDED && anchored)
		connect_to_network()

/obj/machinery/power/emitter/Destroy()
	log_and_message_admins("deleted [src]")
	investigate_log("[SPAN_COLOR("red", "deleted")] at ([x],[y],[z])","singulo")
	return ..()

/obj/machinery/power/emitter/examine(mob/user)
	. = ..()
	var/is_observer = isobserver(user)
	if (user.Adjacent(src) || is_observer)
		var/state_message = "It is unsecured."
		switch (state)
			if (EMITTER_WRENCHED)
				state_message = "It is bolted to the floor, but lacks securing welds."
			if (EMITTER_WELDED)
				state_message = "It is firmly secured in place."
		. += SPAN_NOTICE(state_message)
		if (emagged && (user.skill_check(core_skill, SKILL_TRAINED) || is_observer))
			. += SPAN_WARNING("Its control locks have been fried.")

/obj/machinery/power/emitter/on_update_icon()
	ClearOverlays()
	if(active && powernet && avail(active_power_usage))
		AddOverlays(emissive_appearance(icon, "[icon_state]_lights"))
		AddOverlays("[icon_state]_lights")

/obj/machinery/power/emitter/interface_interact(mob/user)
	if (!CanInteract(user, DefaultTopicState()))
		return FALSE
	activate(user)
	return TRUE

/obj/machinery/power/emitter/proc/activate(mob/user as mob)
	if (!istype(user))
		user = null // safety, as the proc is publicly available.

	if (state == EMITTER_WELDED)
		if (!powernet)
			to_chat(user, SPAN_WARNING("You try to turn on [src], but it doesn't seem to be receiving power."))
			return TRUE
		if (!locked)
			var/area/A = get_area(src)
			if (active)
				active = FALSE
				if (user?.Adjacent(src))
					user.visible_message(
						SPAN_NOTICE("[user] turns off [src]."),
						SPAN_NOTICE("You power down [src]."),
						SPAN_ITALIC("You hear a switch being flicked.")
					)
				else
					visible_message(SPAN_NOTICE("[src] turns off."))
				playsound(src, "switch", 50)
				log_and_message_admins("turned off [src] in [A.name]", user, src)
				investigate_log("turned [SPAN_COLOR("red", "off")] by [key_name_admin(user || usr)] in [A.name]","singulo")
			else
				active = TRUE
				if (user)
					operator_skill = user.get_skill_value(core_skill)
				if (user?.Adjacent(src))
					user.visible_message(
						SPAN_NOTICE("[user] turns on [src]."),
						SPAN_NOTICE("You configure [src] and turn it on."), // Mention configuration to allude to operator skill playing into efficiency
						SPAN_ITALIC("You hear a switch being flicked.")
					)
				else
					visible_message(SPAN_NOTICE("[src] turns on."))
				playsound(src, "switch", 50)
				update_efficiency()
				shot_number = 0
				fire_delay = get_initial_fire_delay()
				log_and_message_admins("turned on [src] in [A.name]", user, src)
				investigate_log("turned [SPAN_COLOR("green", "on")] by [key_name_admin(user || usr)] in [A.name]","singulo")
			update_icon()
		else
			to_chat(user, SPAN_WARNING("The controls are locked!"))
	else
		to_chat(user, SPAN_WARNING("[src] needs to be firmly secured to the floor first."))
		return TRUE

/obj/machinery/power/emitter/proc/update_efficiency()
	efficiency = initial(efficiency)
	if (!operator_skill)
		return
	var/skill_modifier = 0.8 * (SKILL_MAX - operator_skill)/(SKILL_MAX - SKILL_MIN) //How much randomness is added
	efficiency *= 1 + (rand() - 1) * skill_modifier //subtract off between 0.8 and 0, depending on skill and luck.

/obj/machinery/power/emitter/emp_act(severity)
	SHOULD_CALL_PARENT(FALSE)
	return

/obj/machinery/power/emitter/Process()
	if (MACHINE_IS_BROKEN(src))
		return
	if (state != EMITTER_WELDED || (!powernet && active_power_usage))
		active = FALSE
		update_icon()
		return
	if (((last_shot + fire_delay) <= world.time) && active)

		var/actual_load = draw_power(active_power_usage)
		if (actual_load >= active_power_usage) // does the laser have enough power to shoot?
			if (!powered)
				powered = TRUE
				update_icon()
				visible_message(SPAN_WARNING("[src] powers up!"))
				investigate_log("regained power and turned [SPAN_COLOR("green", "on")]","singulo")
		else
			if (powered)
				powered = FALSE
				update_icon()
				visible_message(SPAN_WARNING("[src] powers down!"))
				investigate_log("lost power and turned [SPAN_COLOR("red", "off")]","singulo")
			return

		last_shot = world.time
		if (shot_number < burst_shots)
			fire_delay = get_burst_delay()
			shot_number++
		else
			fire_delay = get_rand_burst_delay()
			shot_number = 0

		//need to calculate the power per shot as the emitter doesn't fire continuously.
		var/burst_time = (min_burst_delay + max_burst_delay) / 2 + 2 * (burst_shots - 1)
		var/power_per_shot = (active_power_usage * efficiency) * (burst_time / 10) / burst_shots

		if (prob(35))
			var/datum/effect/spark_spread/s = new /datum/effect/spark_spread
			s.set_up(5, 1, src)
			s.start()

		var/obj/item/projectile/beam/emitter/A = get_emitter_beam()
		playsound(loc, A.fire_sound, 25, TRUE)
		A.damage = round (power_per_shot / EMITTER_DAMAGE_POWER_TRANSFER)
		A.launch( get_step(loc, dir) )

/obj/machinery/power/emitter/post_anchor_change()
	if (anchored)
		state = EMITTER_WRENCHED
	else
		state = EMITTER_LOOSE
	..()

/obj/machinery/power/emitter/wrench_act(mob/living/user, obj/item/tool)
	if(active)
		to_chat(user, SPAN_WARNING("Turn [src] off first."))
		return ITEM_INTERACT_SUCCESS
	if(state == EMITTER_WELDED)
		to_chat(user, SPAN_WARNING("[src] needs to be unwelded from the floor before you raise its bolts."))
		return ITEM_INTERACT_SUCCESS

/obj/machinery/power/emitter/welder_act(mob/living/user, obj/item/tool)
	. = ITEM_INTERACT_SUCCESS
	if(active)
		balloon_alert(user, "нужно отключить!")
		return TRUE
	switch(state)
		if(EMITTER_LOOSE)
			USE_FEEDBACK_NEED_ANCHOR(user)
		if(EMITTER_WRENCHED)
			if(!tool.tool_start_check(user, 1))
				return
			balloon_alert(user, "приваривание к полу")
			if(!tool.use_as_tool(src, user, 2 SECONDS, 1, 50, SKILL_CONSTRUCTION, do_flags = DO_REPAIR_CONSTRUCT))
				return
			state = EMITTER_WELDED
			balloon_alert_to_viewers("приварено к полу!")
			connect_to_network()
		if(EMITTER_WELDED)
			if(!tool.tool_start_check(user, 1))
				return
			USE_FEEDBACK_UNWELD_FROM_FLOOR(user)
			if(!tool.use_as_tool(src, user, 2 SECONDS, 1, 50, SKILL_CONSTRUCTION, do_flags = DO_REPAIR_CONSTRUCT))
				return
			state = EMITTER_WRENCHED
			balloon_alert_to_viewers("отварено от пола!")
			disconnect_from_network()

/obj/machinery/power/emitter/use_tool(obj/item/W, mob/living/user, list/click_params)
	if (istype(W, /obj/item/card/id) || istype(W, /obj/item/modular_computer))
		if (emagged)
			to_chat(user, SPAN_WARNING("The control lock seems to be broken."))
			return TRUE
		if (has_access(req_lock_access, W.GetAccess()))
			locked = !locked
			user.visible_message(
				SPAN_NOTICE("[user] [locked ? "locks" : "unlocks"] [src]'s controls."),
				SPAN_NOTICE("You [locked ? "lock" : "unlock"] the controls.")
			)
		else
			to_chat(user, SPAN_WARNING("[src]'s controls flash an 'Access denied' warning."))
		return TRUE

	return ..()

/obj/machinery/power/emitter/emag_act(remaining_charges, mob/user)
	if (!emagged)
		locked = FALSE
		emagged = TRUE
		req_access.Cut()
		req_lock_access.Cut()
		user.visible_message(SPAN_WARNING("[user] messes with [src]'s controls."), SPAN_WARNING("You short out the control lock."))
		user.playsound_local(loc, "sparks", 50, TRUE)
		return TRUE

/obj/machinery/power/emitter/proc/get_initial_fire_delay()
	return 10 SECONDS

/obj/machinery/power/emitter/proc/get_rand_burst_delay()
	return rand(min_burst_delay, max_burst_delay)

/obj/machinery/power/emitter/proc/get_burst_delay()
	return 0.2 SECONDS // This value doesn't really affect normal emitters, but *does* affect subtypes like the gyrotron that can have very long delays

/obj/machinery/power/emitter/proc/get_emitter_beam()
	return new /obj/item/projectile/beam/emitter(get_turf(src))

/singleton/public_access/public_method/toggle_emitter
	name = "toggle emitter"
	desc = "Toggles whether or not the emitter is active. It must be unlocked to work."
	call_proc = TYPE_PROC_REF(/obj/machinery/power/emitter, activate)

/singleton/public_access/public_variable/emitter_active
	expected_type = /obj/machinery/power/emitter
	name = "emitter active"
	desc = "Whether or not the emitter is firing."
	can_write = FALSE
	has_updates = FALSE

/singleton/public_access/public_variable/emitter_active/access_var(obj/machinery/power/emitter/emitter)
	return emitter.active

/singleton/public_access/public_variable/emitter_locked
	expected_type = /obj/machinery/power/emitter
	name = "emitter locked"
	desc = "Whether or not the emitter is locked. Being locked prevents one from changing the active state."
	can_write = FALSE
	has_updates = FALSE

/singleton/public_access/public_variable/emitter_locked/access_var(obj/machinery/power/emitter/emitter)
	return emitter.locked

/singleton/stock_part_preset/radio/receiver/emitter
	frequency = BUTTON_FREQ
	receive_and_call = list("button_active" = /singleton/public_access/public_method/toggle_emitter)
