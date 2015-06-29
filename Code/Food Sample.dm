/*
 * Copyright � 2014 Duncan Fairley
 * Distributed under the GNU Affero General Public License, version 3.
 * Your changes must be made public.
 * For the full license text, see LICENSE.txt.
 */

obj/Trophy
	name = "Trophy"
	icon = 'trophies.dmi'
	Gold
		icon_state = "Gold"
	Yellow
		icon_state = "Yellow"
	Silver
		icon_state = "Silver"
	Bronze
		icon_state = "Bronze"
mob/Cow
	icon = 'Cow.dmi'
	Immortal = 1
	New()
		..()
		walk_rand(src,8)
		Moo()
	proc/Moo()
		spawn()while(src)
			hearers(src) << "Cow: [pick("MooooooOOOoOo!","Moo!","MOOOOOOOOOOOOOOOOOOOOOOOOO","Moooooo!","Moo moo moo!")]"
			sleep(600)

mob/GM/verb/Grant_All_Spells(mob/M in Players)
			set category="Staff"
			set popup_menu = 0
			M.verbs += typesof(/mob/Spells/verb)
			M<<"[usr] has given you <u>All</u> spells."

mob/GM/verb/Give_All_Quidditch(mob/M in Players)
			set category="Staff"
			set popup_menu = 0
			M.verbs += /mob/Quidditch/verb/Announce_To_Spectators
			M.verbs += /mob/Quidditch/verb/Setup_Match
			M.verbs += /mob/Quidditch/verb/Start_Match
			M.verbs += /mob/Quidditch/verb/End_Match
			M.verbs += /mob/Quidditch/verb/Clear_Match
			M.verbs += /mob/Quidditch/verb/Readd_Member
			M<<"[usr] has given you <u>All</u> Quidditch Moderation verbs."