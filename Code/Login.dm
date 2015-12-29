/*
 * Copyright © 2014 Duncan Fairley
 * Distributed under the GNU Affero General Public License, version 3.
 * Your changes must be made public.
 * For the full license text, see LICENSE.txt.
 */
/*mob/verb/NewVault1()

	//THIS IS THE FUNCTION FOR CREATING ADDITIONAL VAULT TEMPLATES

	var/height = 10
	var/width = 9 //Width must be odd.
	var/midx = (width+1)/2
	var/swapmap/map = new /swapmap("vault1",width,height,1)
	map.BuildRectangle(map.LoCorner(),map.HiCorner(),/turf/roofb)
	map.BuildFilledRectangle(get_step(map.LoCorner(),NORTHEAST),get_step(map.HiCorner(),SOUTHWEST),/turf/floor)
	map.BuildFilledRectangle(locate(map.x1+1,map.y1+height-2,map.z1),locate(map.x1+width-2,map.y1+height-2,map.z1),/turf/Hogwarts_Stone_Wall)
	map.BuildFilledRectangle(locate(map.x1+midx-1,map.y1+1,map.z1),locate(map.x1+midx-1,map.y1+1,map.z1),/obj/teleport/leavevault)
	map.Save()


mob/verb/NewVaultCustom(var/height as num, var/width as num)

	if(width % 2 == 0) width--

	var/midx = (width+1)/2
	var/swapmap/map = new /swapmap("vault_luxury",width,height,1)
	map.BuildRectangle(map.LoCorner(),map.HiCorner(),/turf/roofb)
	map.BuildFilledRectangle(get_step(map.LoCorner(),NORTHEAST),get_step(map.HiCorner(),SOUTHWEST),/turf/floor)
	map.BuildFilledRectangle(locate(map.x1+1,map.y1+height-2,map.z1),locate(map.x1+width-2,map.y1+height-2,map.z1),/turf/Hogwarts_Stone_Wall)


	map.BuildFilledRectangle(locate(map.x1+midx-1,map.y1+1,map.z1),locate(map.x1+midx-1,map.y1+1,map.z1),/obj/teleport/leavevault)
	map.Save()*/

mob/test/verb
	enter_vault(ckey as text)
		set category = "Vault Debug"
		var/swapmap/map = SwapMaps_Find("[ckey]")
		if(!map)
			map = SwapMaps_Load("[ckey]")
		if(!map)
			usr << "<i>Couldn't find map.</i>"
		else
			var/width = (map.x2+1) - map.x1
			usr.loc = locate(map.x1 + round((width)/2), map.y1+1, map.z1 )
	load_undroppables_into_mob(mob/M as mob in Players)
		set category = "Vault Debug"
		var/swapmap/map = SwapMaps_Find("[M.ckey]")
		if(!map)
			map = SwapMaps_Load("[M.ckey]")
		if(!map)
			usr << "<i>Couldn't find map.</i>"
		else
			for(var/turf/T in map.AllTurfs())
				for(var/obj/O in T)
					if(!(text2path("[O.type]/verb/Drop") in O.verbs) && !istype(O,/obj/teleport/leavevault) )
						O.loc = M
			M:Resort_Stacking_Inv()

	Change_Vault(var/vault as text, var/mob/Player/p in Players)
		set category = "Vault Debug"
		if(fexists("[swapmaps_directory]/tmpl_vault[vault].sav"))
			p.change_vault(vault)
			usr << infomsg("Vault changed")
		else
			usr << errormsg("Vault don't exist.")

mob/Player/proc/change_vault(var/vault)
	var/swapmap/map = SwapMaps_Find("[ckey]")
	if(!map)
		map = SwapMaps_Load("[ckey]")
	if(map)

		for(var/obj/items/i in map)
			i.loc = src
		if(!map.InUse())
			for(var/turf/t in map.AllTurfs())
				for(var/obj/items/i in t)
					i.loc = src
			map.Unload()
			src:Resort_Stacking_Inv()
		else
			src << errormsg("Please evacuate everyone from your vault first.")
			return

	if(!islist(global.globalvaults))
		global.globalvaults = list()
	var/vault/v = new
	v.tmpl = vault
	global.globalvaults[src.ckey] = v
	map = SwapMaps_CreateFromTemplate("vault[vault]")
	if(!map)
		world.log << "ERROR: proc: change_vault() Could not create \"[vault]\" swap map template (vault[vault])"
		return 0

	if(vault == "_hq")
		for(var/i = 1 to 5)
			var/obj/Hogwarts_Door/d = locate("vaultDoor[i]")
			d.tag = null
			d.vaultOwner = ckey

	map.SetID("[src.ckey]")
	map.Save()
	return 1


obj/teleport
	var/dest = ""
	var/pass
	invisibility = 2
	portkey
		icon='portal.dmi'
		icon_state="portkey"
		name = "Port key"
		invisibility = 0
	proc/Teleport(mob/Player/M)
		if(dest)
			if(pass && pass != "")
				var/pw = input(M, "You feel this spot was enchanted with a password protected teleporting spell","Teleport","") as null|text
				if(!pw || M.loc != src.loc) return
				if(pw == pass)
					M<<"<font color=green><b>Authorization Confirmed."
				else
					M<<"<font color=red><b>Authorization Denied."
					return

			var/atom/A = locate(dest) //can be some turf, or some obj
			if(A)
				if(isobj(A))
					A = A.loc
				M:Transfer(A)
				M.lastproj = world.time + 10
				M.removePath()
				if(M.classpathfinding)
					M.Class_Path_to()
				else if(M.pathdest)
					M.pathTo(M.pathdest)
				return 1
	entervault
		Teleport(mob/M)
			if(M.key)
				var/list/accessible_vaults = M.get_accessible_vaults()
				var/hasownvault = 	fexists("[swapmaps_directory]/map_[usr.ckey].sav")
				if(hasownvault || accessible_vaults.len)
					var/list/result = list()
					for(var/ckey in accessible_vaults)
						result[sql_get_name_from(ckey)] = ckey
					var/chosenvault
					var/response
					if(result.len && hasownvault)
						response = input("Which vault do you wish to enter?") as null|anything in result + "My own"
						if(response == "My own")
							chosenvault = usr.ckey
					else if(result.len)
						response = input("Which vault do you wish to enter?") as null|anything in result
					else if(hasownvault)
						chosenvault = usr.ckey
					if(usr.loc != src.loc) return
					if(chosenvault == usr.ckey)
						usr << npcsay("Vault Master: Welcome back to your vault, [usr].[pick(" Remember good security! If you let someone inside and they steal something, there's not much you can do about it!!"," Only let people into your vault if you completely trust them!","")]")
					else
						if(!response) return
						usr << npcsay("Vault Master: Welcome to [response]'s vault, [usr].")
						chosenvault = result[response]
					var/swapmap/map = SwapMaps_Find("[chosenvault]")
					if(!map)
						map = SwapMaps_Load("[chosenvault]")
					var/width = (map.x2+1) - map.x1
					usr.loc = locate(map.x1 + round((width)/2), map.y1+1, map.z1 )
				else
					M << npcsay("Vault Master: You don't have a vault here, [usr]. Come speak to me and let's see if we can change that.")
	leavevault
		icon = 'turf.dmi'
		icon_state = "exit"
		dest="leavevault"
		invisibility = 0
		Teleport(mob/M)
			if(..())
				unload_vault()

	desert_exit
		icon = 'DesertTeleport.dmi'
		dest = "teleportPointCoS Floor 3"
		invisibility = 0
		Teleport(mob/M)
			if(prob(10)) return
			if(prob(40))
				..()
				M << infomsg("You magically found yourself at the entrance!")
			else
				M:Transfer(locate(rand(4,97), rand(4,97), rand(4,6)))

		New()
			..()
			wander()

		proc/wander()
			set waitfor = 0
			var/turf/target
			while(src)
				if(!target || loc == target)
					target = locate(rand(4,97), rand(4,97), z)

				var/turf/t = get_step_towards(loc, target)
				if(t)
					loc = t
				else
					target = null
				sleep(8)

var/tmp/vault_last_exit
proc/unload_vault(updateTime = TRUE)
	if(vault_last_exit && updateTime)
		vault_last_exit = world.time
		return

	var/const/VAULT_TIMEOUT = 600
	vault_last_exit = world.time

	spawn(VAULT_TIMEOUT)
		while(vault_last_exit)
			if(world.time - vault_last_exit >= VAULT_TIMEOUT)
				var/list/custom_loaded = list()
				for(var/customMap/c in loadedMaps)
					custom_loaded += c.swapmap

				for(var/swapmap/map in (swapmaps_loaded ^ custom_loaded))
					if(!map.InUse())
						for(var/turf/T in map.AllTurfs())
							for(var/mob/A in T)
								if(!A.key)del(A)
						map.Unload()
				vault_last_exit = null
			sleep(VAULT_TIMEOUT)


mob/GM/verb/UnloadMap()
	set category = "Custom Maps"
	if(!length(loadedMaps))
		src << errormsg("No maps are loaded.")
		return
	var/customMap/map = input("Unload which map?") as null|anything in loadedMaps
	if(!map) return
	if(map.swapmap.InUse())
		alert("That map currently has a player on it.")
		return
	map.swapmap.UnloadNoSave()
	global.loadedMaps.Remove(map)
	src << infomsg("Map name \"[map.name]\" has been unloaded.")
mob/GM/verb/DeleteMap()
	set category = "Custom Maps"
	if(!length(customMaps))
		src << errormsg("No maps currently exist.")
		return
	var/customMap/map = input("Delete which map?") as null|anything in customMaps
	if(!map) return
	if(map.swapmap && map.swapmap.InUse())
		alert("That map currently has a player on it.")
		return
	fdel("[swapmaps_directory]/map_custom_[ckey(map.name)].sav")
	global.loadedMaps.Remove(map)
	global.customMaps.Remove(map)
	Save_World()
	src << infomsg("Map name \"[map.name]\" has been deleted.")
mob/GM/verb/CopyMap()
	set category = "Custom Maps"
	var/customMap/newmap = new()
	var/newname = input("What do you name the new map? (Won't be shown to players)") as text|null
	if(!newname) return
	if(length(newname) > 19)
		alert("Keep it less than 20 characters.")
		return
	if(fexists("[swapmaps_directory]/map_custom_[ckey(newname)].sav"))
		alert("Map name already exists.")
		return
	newmap.name = newname
	var/customMap/copymap = input("Which map do you want to make a copy of?") as null|anything in customMaps
	if(!copymap) return
	var/result = fcopy("[swapmaps_directory]/map_custom_[ckey(copymap.name)].sav","[swapmaps_directory]/map_custom_[ckey(newname)].sav")
	if(result)
		src << infomsg("A copy of [copymap.name] has been created and named [newname]. It has not been loaded.")
		global.customMaps.Add(newmap)
		Save_World()
	else
		src << errormsg("Report error ID 3feOP to Murrawhip.")
mob/GM/verb/NewMap()
	set category = "Custom Maps"
	var/customMap/newmap = new()
	var/newname = input("What do you name the new map? (Won't be shown to players)") as text|null
	if(!newname) return
	if(length(newname) > 19)
		alert("Keep it less than 20 characters.")
		return
	if(fexists("[swapmaps_directory]/map_custom_[ckey(newname)].sav"))
		alert("Map name already exists.")
		return
	newmap.name = newname
	var/swapmap/swapmap = new("custom_[ckey(newname)]")
	swapmap.Save()
	newmap.swapmap = swapmap
	src.loc = locate(swapmap.x1, swapmap.y1, swapmap.z1)
	global.loadedMaps.Add(newmap)
	global.customMaps.Add(newmap)
	Save_World()
	src << infomsg("Your new map has been created. <b>Note that your map will never be saved automatically. You must use SaveMap.</b>")
proc/WhichcustomMap(mob/M)
	for(var/customMap/map in global.loadedMaps)
		if(M.z == map.swapmap.z1 &&\
			M.x >= map.swapmap.x1 &&\
			M.x <= map.swapmap.x2 &&\
			M.y >= map.swapmap.y1 &&\
			M.y <= map.swapmap.y2)
			return map
mob/GM/verb/SaveMap()
	set category = "Custom Maps"
	if(!length(loadedMaps))
		src << errormsg("No maps are currently loaded.")
		return
	var/customMap/map = input("Save which map?") as null|anything in loadedMaps
	if(!map) return
	if(map.swapmap.InUse())
		alert("That map currently has a player on it.")
		return

	if(!admin)
		for(var/turf/T in map.swapmap.AllTurfs())
			for(var/atom/movable/a in T)

				if(istype(a, /obj/items))
					a.Dispose()

				else if(istype(a, /mob/TalkNPC/EventMob))
					a.Dispose()

	map.swapmap.Save()
	src << infomsg("Map name \"[map.name]\" has been saved.")
proc
	AccessibleTurfs(turf/t)
		var/ret[] = block(locate(max(t.x-1,1),max(t.y-1,1),t.z),locate(min(t.x+1,world.maxx),min(t.y+1,world.maxy),t.z)) - t
		for(var/turf/i in ret)
			if(t.type != i.type)
				ret -= i
		return ret
mob/GM/verb/FloodFill(path as null|anything in typesof(/turf)|typesof(/area))
	set category = "Custom Maps"
	usr << errormsg("Note that the flood ignores objects including doors. It fills via the type of turf that you are standing on, and replaces it with the type you select.")
	if(!path)return
	if(!admin&&z < SWAPMAP_Z)
		src << errormsg("You can only use it inside swap maps.")
		return
	var/Region/r = new(usr.loc, /proc/AccessibleTurfs)
	for(var/T in r.contents)
		new path (T)
mob/GM/verb/LoadMap()
	set category = "Custom Maps"
	if(!length(customMaps))
		src << errormsg("No maps currently exist.")
		return
	var/customMap/map = input("Load which map?") as null|anything in customMaps
	if(!map) return
	if(map.swapmap)
		src << infomsg("\"[map.name]\" is already loaded. Teleporting there now.")
	else
		map.swapmap = SwapMaps_Load("custom_[ckey(map.name)]")
		src << infomsg("Loading \"[map.name]\". Teleporting there now.")
	src.loc = locate(map.swapmap.x1, map.swapmap.y1, map.swapmap.z1)
	global.loadedMaps.Remove(map)
	global.loadedMaps.Add(map)
var/list/customMap/customMaps = list()
var/tmp/list/customMap/loadedMaps = list()
customMap
	var/name = ""
	var/tmp/swapmap/swapmap = null
vault
	var/list/allowedpeople = list()	//ckeys of people with permission to enter
	var/tmpl = "1"// used template, 1 by default
	proc/can_ckey_enter(ckey)
		return (ckey in allowedpeople)
	proc/add_ckey_allowedpeople(ckey)
		allowedpeople += ckey
	proc/remove_ckey_allowedpeople(ckey)
		allowedpeople -= ckey
	proc/name_ckey_assoc()
		//Returns an associated list in list[ckey] = name format
		var/list/result = list()
		for(var/V in src.allowedpeople)
			result[sql_get_name_from(V)] = V
		return result
var/list/vault/globalvaults = list()//Associated with ckey of owner

mob/proc/get_accessible_vaults()
	var/list/accessible_vaults = list()
	for(var/ckey in globalvaults)
		var/vault/V = globalvaults[ckey]
		if(V.can_ckey_enter(src.ckey))
			accessible_vaults += ckey
	return accessible_vaults

/*client/var/verifiedtelnet = 0
client/var/telnetchatmode = "say"
client/var/failedtries = 0
var/telnetdisabled = 0
client/Command(T)
	if(telnetdisabled) del(src)
	if(copytext(T,1,7) == "apples")
		mob.icon = 'telnet.dmi'
		verifiedtelnet = 1
		mob.name = copytext(T,8)
		usr << "Welcome, [mob.name]. Type help for a list of commands."
	else if(verifiedtelnet)
		if(copytext(T,1,5) == "help")
			usr << "ooc						Change to OOC mode"
			usr << "say						Change to Say mode"
			usr << "\[password\] \[name\]	Change to specified name"
			usr << "who						View who list"
		else if(copytext(T,1,4) == "ooc")
			telnetchatmode = "ooc"
		else if(copytext(T,1,4) == "say")
			telnetchatmode = "say"
		else if (copytext(T,1,4) == "who")
			for(var/client/C)
				usr << "[C.mob.name] ([C.key])"
		else
			if(telnetchatmode == "say")
				for(var/mob/M in hearers())
					if(!M.muff)
						M<<"<font size=2><font color=red><b> <font color=red>[usr.name]</font> </b>:<font color=white> [T]"
					else
						if(rand(1,3)==1) M<<"<i>You hear an odd ringing sound.</i>"
			else
				world << "<b><font face='Comic Sans MS'><font color=green><font size=1>OOC></b><font face='Comic San MS'><font size=2><b><font color=blue>[mob.name]  :</font></b> <font color=white><font size=2> [T]"
	else
		usr << "You can sign in by typing the password followed by your name. (Seperated by a space)"
		failedtries++
		if(failedtries>4)del(src)*/
mob/see_in_dark = 1
client/view = "17x17"
client/New()
	..()
	screen_x_tiles = 17
	screen_y_tiles = 17
client/var/screen_x_tiles = 0
client/var/screen_y_tiles = 0
mob/proc/setsplitter()
	if(!betamapmode)
		//mainvsplit
		var/wholewidth = winget(src,"mainvsplit","size")
		var/xpos = findtext(wholewidth,"x")
		wholewidth = text2num(copytext(wholewidth,1,xpos))
		var/mapwidth = winget(src,"mapwindow","size")
		xpos = findtext(mapwidth,"x")
		mapwidth = text2num(copytext(mapwidth,1,xpos))
		mapwidth = 32*17
		var/percentage = (mapwidth / wholewidth) * 100
		winset(src,"mainvsplit","splitter=[percentage]")

client/verb/resizeMap()
	set name=".resizeMap"
	if(!istype(mob,/mob/Player))return
	var/obj/screenobj/conjunct/C = locate() in screen
	if(mob&&mob.betamapmode)
		var/size = winget(src,"mapwindow","size")
		var/xpos = findtext(size,"x")
		screen_x_tiles = round( text2num(copytext(size,1,xpos)) / 32) + 1
		screen_y_tiles = round( text2num(copytext(size,xpos+1)) / 32)

		screen_x_tiles = min(screen_x_tiles, 50)
		screen_y_tiles = min(screen_y_tiles, 50)

		screen_x_tiles = max(screen_x_tiles, 3)
		screen_y_tiles = max(screen_y_tiles, 3)

		view = "[screen_x_tiles]x[screen_y_tiles]"
		if(C) C.screen_loc = view2screenloc(view)
	else
		//NEED TO RESET TO OLD VERSIO HERRREEE
		view="17x17"
		if(C) C.screen_loc = view2screenloc(view)
		screen_x_tiles = 17
		screen_y_tiles = 17
mob/var/betamapmode = 1
mob/verb/ToggleBetaMapMode()
	set name = ".ToggleBetaMapMode"
	if(winget(src,"menu.betamapmode","is-checked") == "true")
		betamapmode = 1
	else
		betamapmode = 0
		setsplitter()
	client.resizeMap()
mob/verb/EnableBetaMapMode()
	set name = ".EnableBetaMapMode"
	betamapmode = 1
	client.resizeMap()
mob/verb/DisableBetaMapMode()
	set name = ".DisableBetaMapMode"
	betamapmode = 0
	setsplitter()
	client.resizeMap()

/mob/proc/GenerateNameOverlay(r,g,b,de=0)
	var/outline = "#000"
	//if(30*r+59*g+11*b > 7650) outline = "#000"
	if(src.pname&&src.key)
		if(de)
			namefont.QuickName(src, "Robed Figure", rgb(r,g,b), outline, top=1)
		else
			namefont.QuickName(src, src.pname, rgb(r,g,b), outline, top=1)
	else
		if(de)
			namefont.QuickName(src, "Robed Figure", rgb(r,g,b), outline, top=1)
		else
			namefont.QuickName(src, src.name, rgb(r,g,b), outline, top=1)

mob/test/verb/Tick_Lag(newnum as num)
	world.tick_lag = newnum
mob/test/verb/CurrentRefNum()
	var/obj/o = new()
	src << "\ref[o]"
var/list/housepointsGSRH = new/list(6)

mob/test/verb/Modify_Housepoints()

	housepointsGSRH[1] = input("Select Gryffindor's housepoints:","Housepoints",housepointsGSRH[1]) as num
	housepointsGSRH[2] = input("Select Slytherin's housepoints:","Housepoints",housepointsGSRH[2]) as num
	housepointsGSRH[3] = input("Select Ravenclaw's housepoints:","Housepoints",housepointsGSRH[3]) as num
	housepointsGSRH[4] = input("Select Hufflepuff's housepoints:","Housepoints",housepointsGSRH[4]) as num
	housepointsGSRH[5] = input("Select Auror's housepoints:","Housepoints",housepointsGSRH[5]) as num
	housepointsGSRH[6] = input("Select Deatheater's housepoints:","Housepoints",housepointsGSRH[6]) as num
	Save_World()
mob/var/tmp/Rictusempra
var/radioOnline = 0

proc/check(msg as text)
    var/search = list("\n")//this is a list of stuff you want to make sure is not in the msg
    for(var/c in search)//search through all the things in the list
        var/pos = findtext(msg,c)//tells the position of the unwanted text
        while(pos)//loops through the whole message to make sure there is no more unwanted text
            msg = "[copytext(msg,1,pos)][copytext(msg,pos+1)]"//It makes the unwanted text(in this case "\n") display in the chat rather than it maknig a new line.
            pos = findtext(msg,c,pos)//looks for anymore unwanted text after the first one is found
    return html_encode(msg)
var/list/illegalnames = list(
	"robed figure",
	"harry",
	"potter",
	"weasley",
	"hermione",
	"granger",
	"albus",
	"dumbledore",
	"malfoy",
	"lestrange",
	"sirius",
	"voldemort",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"0")
//client
//	script = "<STYLE>BODY {background: black; color: white; font-family: Arial,sans-serif}a:link {color: #3636F5}</STYLE>"
//	macros return "Attack"

var/DevMode


world
	hub = "TheWizardsChronicles.TWC"
	name = "The Wizards' Chronicles"
	turf=/turf/blankturf
	view="17x17"
var/world/VERSION = "16.47"

world/proc/playtimelogger()
	return
	var/today_d = time2text(world.realtime,"DD")
	var/today_m = time2text(world.realtime,"MM")
	var/today_y = time2text(world.realtime,"YY")
	var/today_h = time2text(world.timeofday,"hh")
	for(var/client/C)
		var/sql = "SELECT ckey FROM tblPlayinglogs WHERE ckey=[mysql_quote(C.ckey)] AND day='[today_d]' AND month='[today_m]' AND year='[today_y]'"
		var/DBQuery/qry = my_connection.NewQuery(sql)
		qry.Execute()
		if(qry.RowCount() > 0)
			//Already has a listing for today - update it
			sql = "UPDATE tblPlayinglogs SET `[today_h]`='1' WHERE ckey=[mysql_quote(C.ckey)] AND day='[today_d]' AND month='[today_m]' AND year='[today_y]'"
			qry = my_connection.NewQuery(sql)
			qry.Execute()
			if(qry.RowsAffected() < 1 && qry.ErrorMsg())
				world.log << "0 rows were affected - (([sql])) - Errormsg: [qry.ErrorMsg()]"
		else
			//Create a listing for today and populate it
			sql = "INSERT INTO tblPlayinglogs(ckey,day,month,year,`[today_h]`) VALUES('[C.ckey]','[today_d]','[today_m]','[today_y]','1')"
			qry = my_connection.NewQuery(sql)
			qry.Execute()
			if(qry.RowsAffected() < 1 && qry.ErrorMsg())
				world.log << "0 rows were affected - (([sql])) - Errormsg: [qry.ErrorMsg()]"
		sleep(2)
world/proc/worldlooper()
	sleep(9000)
	spawn()
		world.playtimelogger()
	if(radioEnabled)
		var/rndnum = rand(1,2)
		for(var/client/C)
			sleep(2)
			if(!C) continue
			if(winget(C,"radio_enabled","is-checked") == "false")
				switch(rndnum)
					if(1)
						C.mob << "<font color = white><b><h3>TWC Radio is broadcasting. Click <a href='http://listen.hotdogradio.com/?ID=TWC'>here</a> to listen.</h3></b></font><br>"
					if(2)
						C.mob << "<font color = white><b><h3>You should probably listen to TWC Radio! Click <a href='http://listen.hotdogradio.com/?ID=TWC'>here</a> to listen!</h3></b></font><br>"
	spawn()worldlooper()
mob
	create_character
		proc/name_filter(name)
			//Returns reason that name is not allowed, or null if it is accepted
			//Format of returned message is "Name is invalid as it [error]"
			//Also removes any non-allowed character
			var/list/allowed_characters = list(
				"a",
				"b",
				"c",
				"d",
				"e",
				"f",
				"g",
				"h",
				"i",
				"j",
				"k",
				"l",
				"m",
				"n",
				"o",
				"p",
				"q",
				"r",
				"s",
				"t",
				"u",
				"v",
				"w",
				"x",
				"y",
				"z",
				" ")
			var/list/unallowed_names = list(
				"harry",
				"snape",
				"hermoine",
				"voldemort",
				"dumbledore",
				"riddle",
				"potter",
				"granger",
				"malfoy",
				"weasley",
				"lestrange",
				"sirius",
				"riddle",
				"lestrange",
				"black",
				"marvello",
				"1",
				"2",
				"3",
				"4",
				"5",
				"6",
				"7",
				"8",
				"9",
				"0")
			var/list/foundinvalids = ""
			alert(length(name))
			for(var/i=1;i<length(name)+1;i++)
				//Checks each character to see if it's a valid character - informs the user to remove it
				if(! (lowertext(copytext(name,i,i+1)) in allowed_characters))
					//Invalid character
					if(length(foundinvalids))
						foundinvalids += ", [copytext(name,i,i+1)]"
					else
						foundinvalids += "[copytext(name,i,i+1)]"
			if(foundinvalids)
				return "contains the following invalid characters, [foundinvalids]"
			if(length(name) < 3)
				return "is less than 3 characters long"
			else if(length(name) > 16)
				return "is more than 16 characters long"
			for(var/unallowed_name in unallowed_names)
				if(findtext(name, unallowed_name))
					return "contains \"[unallowed_name]\""
		proc/filtername(var/charname)
			if(charname=="" || charname == " ")
				return 1
			for(var/W in illegalnames)
				if(findtext(charname,W))
					return 1
			return 0
		Login()
			if(DevMode==1)
				if(!src.Gm)
					src<<"<font color=red><p align=center> || <b>Access Denied</b>|| <p align=center> The server is currently in Maintinence Mode. Access is restricted to Game Masters only.</p>"

					sleep(1)
					del src
				else
					src<<"<b><p align=center> || <b>Access Granted</b> || <p align=center>You have been recognized as a Game Master. The server is currently in maintience mode. Access is permitted to staff only. Welcome.</p>"


			var/mob/Player/character=new()
			//character.savefileversion = currentsavefilversion
			var/desiredname = input("What would you like to name your Harry Potter: The Wizards' Chronicles character? Keep in mind that you cannot use a popular name from the Harry Potter franchise, nor numbers or special characters.")
			var/passfilter = name_filter(desiredname)
			while(passfilter)
				alert("Your desired name is not allowed as it [passfilter].")
				desiredname = input("Please select a name that does not use a popular name from the Harry Potter franchise, nor numbers or special characters.")
				passfilter = name_filter(desiredname)
			var/charname = desiredname
			charname=copytext(charname,1,24/*the 20 is max name length*/)
			charname = addtext(uppertext(copytext(charname,1,2)),copytext(charname,2,length(charname)+1))
			character.name="[html_encode(charname)]"
			switch(input(src,"You are allowed to choose a House.","House Selection") in list ("Male Gryffindor","Female Gryffindor","Male Slytherin","Female Slytherin","Male Ravenclaw","Female Ravenclaw","Male Hufflepuff","Female Hufflepuff"))
				if("Male Gryffindor")
					character.verbs += /mob/GM/verb/Gryffindor_Chat
					character.House="Gryffindor"
					character.Gender="Male"
					character.icon='MaleGryffindor.dmi'
				//	character<<"<font color=red><font size=3>You are a Gryffindor. Do NOT tell anyone in another house your Common Room Password! The password to the Gryffindor Common Room is, <font color=blue>Fortuna"
				if("Female Gryffindor")
					character.House="Gryffindor"
					character.Gender="Female"
					character.verbs += /mob/GM/verb/Gryffindor_Chat
					character.icon='FemaleGryffindor.dmi'
				//	character<<"<font color=red><font size=3>You are a Gryffindor. Do NOT tell anyone in another house your Common Room Password! The password to the Gryffindor Common Room is, <font color=blue>Fortuna"
				if("Male Slytherin")
					character.House="Slytherin"
					character.Gender="Male"
					character.verbs += /mob/GM/verb/Slytherin_Chat
					character.icon='MaleSlytherin.dmi'
				//	character<<"<font size=3><font color=red>You are a Slytherin. Do NOT tell anyone in another house your Common Room Password! The password to the Slytherin Common Room is, <font color=blue>Kedavra"
				if("Female Slytherin")
					character.House="Slytherin"
					character.Gender="Female"
					character.verbs += /mob/GM/verb/Slytherin_Chat
					character.icon='FemaleSlytherin.dmi'
				if("Male Ravenclaw")
					character.House="Ravenclaw"
					character.Gender="Male"
					character.verbs += /mob/GM/verb/Ravenclaw_Chat
					character.icon='MaleRavenclaw.dmi'
				if("Female Ravenclaw")
					character.House="Ravenclaw"
					character.Gender="Female"
					character.verbs += /mob/GM/verb/Ravenclaw_Chat
					character.icon='FemaleRavenclaw.dmi'
				if("Male Hufflepuff")
					character.House="Hufflepuff"
					character.Gender="Male"
					character.verbs += /mob/GM/verb/Hufflepuff_Chat
					character.icon='MaleHufflepuff.dmi'
				if("Female Hufflepuff")
					character.House="Hufflepuff"
					character.Gender="Female"
					character.verbs += /mob/GM/verb/Hufflepuff_Chat
					character.icon='FemaleHufflepuff.dmi'
				//	character<<"<font size=3><font color=red>You are now a Hufflepuff. Common Room password is <font size=3><font color=red>Maroon</font><p><b>Dont Tell Anyone Outside of Your House or you will be expelled."

			character.Rank="Player"
			character.baseicon = character.icon
			character.Year="1st Year"
			if(character.Gender=="Female")
				character.gender = FEMALE
			else if(character.Gender=="Male")
				character.gender = MALE
			//character.StatPoints+=10
			//character.verbs += /mob/Player/verb/Use_Statpoints
			src<<"<b><font size=2><font color=#3636F5>Welcome to Harry Potter: The Wizards Chronicles</font> <u><a href='http://wizardschronicles.com/?ver=[VERSION]'>Version [VERSION]</a></u></b> <br>Visit the forums <a href=\"http://forum.wizardschronicles.com\">here.</a>"
			//src<<"<b><font size=2><font color=blue>Welcome to Harry Potter: The Wizards Chronicles</font> <u><a href='?src=\ref[src];action=view_changelog'>Version [VERSION]</a></u></b> <br>Visit the forums <a href=\"http://www.wizardschronicles.com\">here.</a>"
			src<<"<b>You are in the entrance to Diagon Alley."
			src<<"<b><u>Ollivander has a wand for you. Go up, and the first door on your right is the entrance to Ollivander's wand store.</u></b>"
			src<<"<h3>For a full player guide, visit http://guide.wizardschronicles.com.</h3>"
			var/oldmob = src
			src.client.mob = character
			character.gold = new /gold(100)
			character.goldinbank = new /gold(100)
			character.client.eye = character
			character.client.perspective = MOB_PERSPECTIVE
			character.loc=locate(45,60,26)
			character.notmonster=1
			character.verbs += /mob/Spells/verb/Inflamari
			for(var/client/C)
				if(C.mob)
					if(C.mob.Gm) C.mob << "<font size=2 color=#C0C0C0><B><I>[character][character.refererckey==C.ckey ? "(referral)" : ""] ([character.client.address])([character.ckey])([character.client.connection == "web" ? "webclient" : "dreamseeker"]) logged in.</I></B></font>"
					else C.mob << "<font size=2 color=#C0C0C0><B><I>[character][character.refererckey==C.ckey ? "(referral)" : ""] logged in.</I></B></font>"
			character.Teleblock=0
			if(!character.Interface) character.Interface = new(character)
			character.startQuest("Tutorial: The Wand Maker")
			character.BaseIcon()
			src = null
			spawn()
				sql_check_for_referral(character)
			del(oldmob)
mob/var
	extraMHP = 0
	extraMMP = 0
	extraDmg = 0
	extraDef = 0

	tmp
		clothDmg = 0
		clothDef = 0
mob/Player
	player=1
	NPC=0

	proc
		addNameTag()
			underlays = list()
			switch(House)
				if("Hufflepuff")
					GenerateNameOverlay(242,228,22)
				if("Slytherin")
					GenerateNameOverlay(41,232,23)
				if("Gryffindor")
					GenerateNameOverlay(240,81,81)
				if("Ravenclaw")
					GenerateNameOverlay(13,116,219)
				if("Ministry")
					GenerateNameOverlay(255,255,255)

	verb
		Use_Statpoints()
			set category = "Commands"
			if(usr.StatPoints>0)
				switch(input("Which stat would you like to improve?","You have [usr.StatPoints] stat points.")as null|anything in list ("Mana Points","Damage","Defense"))
					if("Health")
						if(src.StatPoints>0)
							var/SP = round(input("How many stat points do you want to put into Health? You have [usr.StatPoints]",,usr.StatPoints) as num|null)
							if(!SP || SP < 0)return
							if(SP <= usr.StatPoints)
								var/addstat = 10*SP
								usr.extraMHP+=addstat
								usr<<infomsg("You gained [addstat] HP!")
								usr.StatPoints -= SP
							else
								usr <<errormsg("You cannot put [SP] stat points into Health as you only have [usr.StatPoints]")
					if("Mana Points")
						if(src.StatPoints>0)
							var/SP = round(input("How many stat points do you want to put into Mana Points? You have [usr.StatPoints]",,usr.StatPoints) as num|null)
							if(!SP || SP < 0)return
							if(SP <= usr.StatPoints)
								var/addstat = 10*SP
								usr.extraMMP+=addstat
								usr<<infomsg("You gained [addstat] MP!")
								usr.StatPoints -= SP
							else
								usr <<errormsg("You cannot put [SP] stat points into Mana Points as you only have [usr.StatPoints]")
					if("Damage")
						if(src.StatPoints>0)
							var/SP = round(input("How many stat points do you want to put into Damage? You have [usr.StatPoints]",,usr.StatPoints) as num|null)
							if(!SP || SP < 0)return
							if(SP <= usr.StatPoints)
								var/addstat = 1*SP
								usr.extraDmg+=addstat
								usr<<infomsg("You gained [addstat] damage!")
								usr.StatPoints -= SP
							else
								usr <<errormsg("You cannot put [SP] stat points into Damage as you only have [usr.StatPoints]")
					if("Defense")
						if(src.StatPoints>0)
							var/SP = round(input("How many stat points do you want to put into Defense? You have [usr.StatPoints]",,usr.StatPoints) as num|null)
							if(!SP || SP < 0)return
							if(SP <= usr.StatPoints)
								var/addstat = 3*SP
								usr.extraDef+=addstat
								usr<<infomsg("You gained [addstat] defense!")
								usr.StatPoints -= SP
							else
								usr <<errormsg("You cannot put [SP] stat points into Defense as you only have [usr.StatPoints]")
				usr.resetMaxHP()
				usr.updateHPMP()
				if(usr.StatPoints == 0)
					usr.verbs.Remove(/mob/Player/verb/Use_Statpoints)
			else
				usr.verbs.Remove(/mob/Player/verb/Use_Statpoints)

	proc
		Saveme()
			if(prevname)
				derobe = 0
				name = prevname

	Login()
		//..()
		dance = 0
		if(Gender=="Female")
			gender = FEMALE
		else if(Gender=="Male")
			gender = MALE
		Resort_Stacking_Inv()
		shielded = 0
		resetSettings()
		if(usr.StatPoints<1)usr.verbs.Remove(/mob/Player/verb/Use_Statpoints)
		shieldamount = 0
		mouse_drag_pointer = MOUSE_DRAG_POINTER
		if(client.connection == "web")
			winset(src, "mapwindow.map", "icon-size=32")
		spawn()
			var/mob/multikey
			for(var/mob/Player/p in Players)
				if(client == p.client) continue
				if(client.connection == "web")
					if(p.client.address == client.address || p.client.computer_id == client.computer_id)
						multikey = p
						break
				else
					if(p.client.computer_id == client.computer_id)
						multikey = p
						break

			if(multikey)
				for(var/mob/Player/p in Players)
					if(p.Gm)
						p << "<h2>Multikeyers: [multikey](key: [multikey.key] | ip: [multikey.client.address]) & just logged in: [src] (key: [key] | ip: [client.address]) ([client.connection == "web" ? "webclient" : "dreamseeker"])</h2>"
		listenooc = 1
		listenhousechat = 1
		invisibility = 0
		alpha = 255
		switch(key)
			if("Murrawhip")
				src.verbs+=typesof(/mob/GM/verb/)
				src.verbs+=typesof(/mob/Spells/verb/)
				src.verbs+=typesof(/mob/test/verb/)
				src.verbs+=typesof(/mob/Quidditch/verb)
				src.Gm=1
				src.shortapparate=1
				src.draganddrop=1
				src.admin=1
				//src.icon = 'Murrawhip.dmi'
				//src.icon_state = ""
			if("Rotem12")
				src.verbs+=typesof(/mob/GM/verb/)
				src.verbs+=typesof(/mob/Spells/verb/)
				src.verbs+=typesof(/mob/test/verb/)
				src.verbs+=typesof(/mob/Quidditch/verb)
				src.Gm=1
				src.draganddrop=1
				src.admin=1


		//spawn()world.Export("http://www.wizardschronicles.com/player_stats_process.php?playername=[name]&level=[level]&house=[House]&rank=[Rank]&login=1&ckey=[ckey]&ip_address=[client.address]")
		timelog = world.realtime
		if(timerMute > 0)
			src << "<u>You're muted for [timerMute] minute[timerMute==1 ? "" : "s"].</u>"
			spawn() mute_countdown()
		if(timerDet > 0)
			src << "<u>You're in detention for [timerDet] minute[timerDet==1 ? "" : "s"].</u>"
			spawn() detention_countdown()
		addNameTag()
		Players.Add(src)
		bubblesort_atom_name(Players)
		if(housecupwinner)
			src << "<b><font color=#CF21C0>[housecupwinner] is the House Cup winner for this month. They receive +25% drop rate/gold/XP from monster kills.</font></b>"
		if(classdest)
			src << announcemsg("[curClass] class is starting. Click <a href=\"?src=\ref[src];action=class_path;latejoiner=true\">here</a> for directions.")
		updateHPMP()
		if(!Interface) Interface = new(src)
		isDJ(src)
		checkMail()
		buildActionBar()
		logintime = world.realtime
		spawn()
			//CheckSavefileVersion()
			if(istype(src.loc.loc,/area/arenas) && !rankedArena)
				src.loc = locate(50,22,15)
			unreadmessagelooper()
			sql_update_ckey_in_table(src)
			sql_update_multikey(src)
			src.client.update_individual()
			if(global.clanwars && (src.Auror || src.DeathEater))
				src.ClanwarsInfo()
			winset(src,null,"barHP.is-visible=true;barMP.is-visible=true")

			loc.loc.Enter(src, src.loc)
			loc.loc.Entered(src, src.loc)
			src.ApplyOverlays(0)
			BaseIcon()

	proc/ApplyOverlays(ignoreBonus = 1)
		src.overlays = list()
		if(Lwearing)
			var/mob/Player/var/list/tmpwearing = Lwearing
			Lwearing = list()

			if(!ignoreBonus)
				clothDmg = 0
				clothDef = 0

			for(var/obj/items/wearable/W in tmpwearing)
				var/b = W.bonus
				W.bonus = -1
				W.Equip(src,1)
				W.bonus = b

				if(!ignoreBonus)
					if(b & W.DAMAGE)
						clothDmg += 10 * W.quality * W.scale
					if(b & W.DEFENSE)
						clothDef += 30 * W.quality * W.scale

			if(!ignoreBonus)
				resetMaxHP()

		if(src.away)
			src.ApplyAFKOverlay()

	verb
		Say(t as text)
			if(!usr.mute)
				if(usr.silence)
					src << "Your tongue is stuck to the roof of your mouth. You can't speak."
					return
				if(usr.Rictusempra==1)
					if(usr.Rictalk==1)
						return
					else
						hearers(client.view) << "[usr.name] tries to speak but only laughs uncontrollably."
						usr.Rictalk=1
						return
				else
					if(usr.spam<=5 || Gm)
						if(t)
							t=check(t)//run the text through the cleaner
							t = copytext(t,1,500)
							if(copytext(t,1,5)=="\[me]")
								hearers(client.view)<<"<i>[usr] [copytext(t,5)]</i>"
							else if(copytext(t,1,4)=="\[w]")
								if(name == "Robed Figure")
									range(1)<<"<font size=2><font color=red><b><font color=red>[usr]</font> whispers: <i>[copytext(t,4)]</i>"
								else
									range(1)<<"<font size=2><font color=red><b>[Tag] <font color=red>[usr]</font> whispers: <i>[copytext(t,4)]</i>"

							else
								var/silent = FALSE
								if(cmptext(copytext(t, 1, 18),"restricto maxima "))
									if(src.Gm)
										hearers()<<"[usr] encases the area within a magical barrier."
										var/value = copytext(t, 18, 19)
										if(value == "") value = 5
										else if(text2num(value) < 1) value = 5
										else value = text2num(value)
										for(var/turf/T in (oview(value) - oview(value-1)))
											var/inflamari = /obj/Force_Field
											flick('mist.dmi',T)
											T.overlays += inflamari
											T.density=1
											T.invisibility=0
								else if(cmptext(copytext(t, 1, 10),"eat slugs"))
									if(/mob/Spells/verb/Eat_Slugs in verbs)
										silent = usr:Eat_Slugs(copytext(t, 11))

								if(!silent)
									for(var/mob/M in hearers(client.view))
										if(!M.muff)
											if(prevname)
												M<<"<font size=2><font color=red><b><font color=red> [usr]</font></b> :<font color=white> [t]"
											else
												M<<"<font size=2><font color=red><b>[Tag] <font color=red>[usr]</font> [GMTag]</b>:<font color=white> [t]"
										else
											if(rand(1,3)==1) M<<"<i>You hear an odd ringing sound.</i>"


							if(usr.name=="Robed Figure")
								chatlog << "<font size=2 color=red><b>[usr.prevname] (ROBED)</b></font><font color=white> says '[t]'</font>"+"<br>"//This is what it adds to the log!
							else
								chatlog << "<font size=2 color=red><b>[usr]</b></font><font color=white> says '[t]'</font>"+"<br>"//This is what it adds to the log!
							if(t == ministrypw)
								if(istype(usr.loc,/turf/gotoministry))
									if(usr.name in ministrybanlist)
										view(src) << "<b>Toilet</b>: <i>The Ministry of Magic is not currently open to you. Sorry!</i>"
									else
										oviewers() << "[usr] disappears."
										if(usr.flying)
											usr.flying = 0
											usr.density = 1
											usr << "You've been knocked off your broom."
										var/atom/a = locate("ministryentrance")
										var/turf/dest = isturf(a) ? a : a.loc
										for(var/client/C)
											if(C.eye)
												if(C.eye == usr && C.mob != usr)
													C << "<b><font color = white>Your Telendevour wears off.</font></b>"
													C.eye=C.mob
										usr.loc = dest
							if(usr.House == "Ministry")
								switch(lowertext(t))
									if("code black")
										var/area/ministry_of_magic/A = locate(/area/ministry_of_magic)
										if(A.code_black)
											A.code_black = 0
											for(var/mob/M in Players)
												if(M.Auror)
													M << "<b><font color=red>Ministry of Magic - Code Black cancelled</font></b>"
											if(!usr.Auror)
												usr << "<b><font color=red>Ministry of Magic - Code Black cancelled</font></b>"
										else
											for(var/mob/M in Players)
												if(M.Auror)
													M << "<b><font color=red>Ministry of Magic is under attack. Code Black initiated</font></b>"
											if(!usr.Auror)
												usr << "<b><font color=red>Ministry of Magic is under attack. Code Black initiated</font></b>"
											A.code_black = 1
											var/list/turf/seeds = list()
											for(var/turf/T in A)
												if(rand(1,13)==1)
													seeds += T
											var/obj/items/Smoke_Pellet/Pellet
											while(A.code_black)
												for(var/turf/T in seeds)
													Pellet = new(T)
													spawn(rand(1,30))Pellet.Explode()
												sleep(150)

									if("change ministry password")
										if(key=="Murrawhip")
											var/input = input("New password?", "Ministry Password", ministrypw) as null|text
											if(!input) return
											else
												ministrypw = input
											hearers() << "<b><font color=red>Password Changed</font></b>"
									if("unlock office")
										var/obj/brick2door/door = locate("ministryoffice")
										if(!door)return
										door.door = 1
										view(door) << "<i>You hear the door unlock.</i>"
									if("lock office")
										var/obj/brick2door/door = locate("ministryoffice")
										if(!door)return
										door.door = 0
										view(door) << "<i>You hear the door lock.</i>"
							switch(lowertext(t))
								/*if("close hogwarts")
									if(src.admin)
										for(var/turf/Hogwarts_Exit/T in world)
											T.icon = 'Wall1.dmi'
											T.density = 1
										Players<<"[usr] has closed Hogwarts"
										for(var/turf/Hogwarts/T in world)
											T.icon = 'Turf.dmi'
											T.icon_state = "grille"
											T.density = 1*/
								if("open event")
									if(src.admin)
										hearers()<<"Done."
										for(var/turf/Arena/T in world)
											T.icon = null
											T.density = 0
								if("close event")
									if(src.admin)
										hearers()<<"Done."
										for(var/turf/Arena/T in world)
											T.icon = 'Turf.dmi'
											T.icon_state = "grille"
											T.density = 1
								/*if("colloportus gate")
									if(src.Gm)
										sleep(20)
										hearers()<<"<font size=1>[usr] has locked the door</font>"
										for(var/turf/Gate/T in oview(5))
											T.door=0
											T.bumpable=0*/
								if("colloportus")
									if(src.Gm)
										sleep(20)
										hearers()<<"<font size=1>[usr] has locked the door.</font>"
										if(classdest)
											usr << errormsg("Friendly reminder: Class guidance is still on.")
										for(var/obj/Hogwarts_Door/T in oview(client.view))
											T.door=0
											T.bumpable=0
								if("alohomora")
									if(src.Gm)
										sleep(20)
										view(client.view)<<"<font size=1>[usr] has unlocked the door.</font>"
										for(var/obj/Hogwarts_Door/T in oview(client.view))
											flick('Alohomora.dmi',T)
											T.door=1
											T.bumpable=1
								/*if("alohomora gate")
									if(src.Gm)
										sleep(20)
										hearers()<<"<font size=1>[usr] has unlocked the Door</font>"
										for(var/turf/Gate/T in oview())
											flick('Alohomora.dmi',T)
											T.door=1
											T.bumpable=1
											T.door=1
											T.bumpable=1*/
								if("quillis")
									if(src.Gm)
										for(var/obj/Desk/T in view(client.view))
											var/scroll = /obj/items/scroll
											flick('mist.dmi',T)
											new scroll(T.loc)
										hearers()<<"[usr] flicks \his wand, causing scrolls to appear on the desks."
								if("quillis deletio")
									if(src.Gm)
										for(var/obj/items/scroll/T in oview(client.view))
											flick('mist.dmi',T)
											del T
										hearers()<<"[usr] flicks \his wand, causing scrolls to vanish"

								if("disperse")
									if(src.Gm)
										for(var/turf/T in view(client.view))
											if(length(T.overlays))
												T.overlays += image('mist.dmi',layer=10)
												spawn(9)
													T.overlays = null
													T.density=initial(T.density)
									if(/mob/Spells/verb/Disperse in verbs)
										usr:Disperse()

								if("save me")
									src.Save()
									hearers()<<"[src] has been saved."
								if("save world")
									if(usr.admin)
										for(var/client/C)
											if(C.mob)C.mob.Save()
											//C<<"You've been automatically saved."
											sleep(1)
										Save_World()
										src<<infomsg("The world has been saved.")
								if("clear admin log")
									if(src.admin)
										src<<infomsg("The Admin logs have been deleted.")
										fdel("Logs/Adminlog.html")
								if("clear gold log")
									if(src.admin)
										src<<infomsg("The Gold logs have been deleted.")
										fdel("Logs/Goldlog.html")
								if("clear kill log")
									if(src.admin)
										src<<infomsg("The Kill logs have been deleted.")
										fdel("Logs/kill_log.html")
								if("clear event log")
									if(src.admin)
										src<<infomsg("The Event logs have been deleted.")
										fdel("Logs/event_log.html")
								if("clear class log")
									if(src.admin)
										src<<infomsg("The Class logs have been deleted.")
										fdel("Logs/classlog.html")
								if("clear radio log")
									if(src.admin)
										src<<infomsg("The Radio logs have been deleted.")
										fdel("Logs/DJlog.html")
								if("clear log")
									if(src.admin)
										src<<infomsg("The Chat logs have been deleted.")
										fdel("Logs/chatlog.html")
								if("afk check")
									if(Gm)
										if(alert("AFK Check was last used about [round((world.realtime - lastusedAFKCheck) / 10 / 60)] minutes ago. Do you want to use it now?",,"Yes","No") == "Yes")
											src<<infomsg("Checking for AFK trainers...")
											for(var/mob/A in world)
												if(A.key&&A.Gm)
													A << infomsg("[src] uses AFK Check")
											AFK_Train_Scan()
											src << infomsg("AFK Check Complete.")
								if("disable ooc")
									if(src.Gm)
										OOCMute=1
										src<<infomsg("OOC has been disabled.")
								if("enable ooc")
									if(src.Gm)
										src<<infomsg("OOC has been enabled.")
										OOCMute = 0
								if("access admin log files")
									if(src.admin==1)
										usr <<browse(file("Logs/Adminlog.html"))
										src<<infomsg("Access Granted.")
								if("access gold log files")
									if(src.admin==1)
										usr <<browse(goldlog)
										src<<infomsg("Access Granted.")
								if("access log files")
									if(src.admin==1)
										usr <<browse("<body bgcolor=\"black\"> [file2text(chatlog)]</body>","window=1")
										src<<infomsg("Access Granted.")
								if("restricto")
									if(src.Gm)
										hearers()<<"[usr] encases \himself within a magical barrier."
										for(var/turf/T in view(1))
											var/inflamari = /obj/Force_Field
											flick('mist.dmi',T)
											T.overlays += inflamari
											T.density=1
											T.invisibility=0
								if("clanevent1")
									if(src.admin)
										if(!clanevent1)
											clanevent1 = 1
											clanevent1_respawntime = input("Seconds before respawn of destroyed pillar?",,600)
											clanevent1_pointsgivenforpillarkill = input ("Number of points given for destroyed pillar?",,25)
											clanevent1_pointsgivenforkill = input ("Number of points given for player kill?",,1)
											var/MHP = input("Hits required to destroy pillar?",,100)
											for(var/obj/clanpillar/C in world)
												C.enable(MHP)
										else
											clanevent1 = 0
											for(var/obj/clanpillar/C in world)
												C.disable()
							if(!Gm)
								usr.spam++
								spawn(30)
									usr.spam--
			else
				usr << errormsg("You can't send messages while you are muted.")
		OOC(T as text)
			set desc = "Speak on OOC"
			if(!usr.listenooc)
				usr << "Your OOC is turned off."
				return
			if(usr.mute)
				usr << errormsg("You can't send messages while you are muted.")
				return
			if(OOCMute)
				usr<<"Access to the OOC Chat System has been restricted by a Staff Member."
			else
				if(usr.spam<=5)
					if(!usr.MuteOOC)
						if(T)
							T = copytext(T,1,300)
							T = check(T)
							for(var/client/C)

								if(C.mob)if(C.mob.type == /mob/Player)if(C.mob.listenooc)
									if(usr.name=="Robed Figure")
										C << "<b><a href=\"?src=\ref[C.mob];action=pm_reply;replynametext=[formatName(src)]\" style=\"font-size:1;font-family:'Comic Sans MS';text-decoration:none;color:green;\">OOC></a></font></b><b><font size=2 color=#3636F5>[usr.prevname] [usr.GMTag]:</font></b> <font color=white size=2> [T]</font>"
									else
										C << "<b><a href=\"?src=\ref[C.mob];action=pm_reply;replynametext=[formatName(src)]\" style=\"font-size:1;font-family:'Comic Sans MS';text-decoration:none;color:green;\">OOC></a></font></b><b><font size=2 color=#3636F5>[usr] [usr.GMTag]:</font></b> <font color=white size=2> [T]</font>"


							if(usr.name=="Robed Figure")
								chatlog << "<font color=blue><b>[usr.prevname] (ROBED)</b></font><font color=green> OOC's '[T]'</font>"+"<br>"//This is what it adds to the log!
							else
								chatlog << "<font color=blue><b>[usr]</b></font><font color=green> OOC's '[T]'</font>"+"<br>"//This is what it adds to the log!
							usr.spam++
							spawn(30)
								usr.spam--
							if(findtext(T, "://"))
								usr.spam++
								spawn(40)
									usr.spam--
						else
							usr<<"Please enter something."
					else
						usr << errormsg("OOC is muted.")
				else
					spam+=0.1
					spawn(300)
						spam-=0.1
					if(spam > 7)
						Auto_Mute(15, "spammed OOC")
//					usr.Auto_Ban()
				//	else
				//		usr.Auto_Mute()




		Listen_OOC()
			set name = ""
			listenooc = !listenooc
			src << "You are now [listenooc ? "listening" : "<b>not</b> listening"] to the OOC channel."
		Listen_Housechat()
			set name = ""
			listenhousechat = !listenhousechat
			src << "You are now [listenhousechat ? "listening" : "<b>not</b> listening"] to your house channel."

		Who()
			var/online=0
			for(var/mob/Player/M in Players)
				online++
				src << "\icon[wholist[M.House ? M.House : "Empty"]] <B><font color=blue><font size=1>Name:</font> </b><font color=white>[M.prevname ? M.prevname : M.name]<font color=white></b>[M.status] <b><font color=red>Key: </b>[M.key] <b><font size=1><font color=purple> Level: </b>[M.level >= lvlcap ? "[getSkillGroup(M.ckey)] \icon[M.getRankIcon()]" : M.level] <b><font color=green>Rank: </b>[M.Rank == "Player" ? M.Year : M.Rank]</font> </SPAN></B>"

			usr << "[online] players online."
			var/logginginmobs = ""
			for(var/client/C)
				if(C.mob && !(C.mob in Players))
					if(logginginmobs == "")
						logginginmobs += "[C.key]"
					else
						logginginmobs += ", [C.key]"
			if(logginginmobs != "")
				usr << "Logging in: [logginginmobs]."


		AFK()
			if(!usr.away)
				usr.away = 1
				usr.here=usr.status
				usr.status=" (AFK)"
				Players<<"~ <font color=red>[usr]</font> is <u>AFK</u> ~"
				ApplyAFKOverlay()
			else
				usr.away = 0
				usr.status=usr.here
				Players<<"<font color=red>[usr]</font> is no longer AFK."
				RemoveAFKOverlay()

mob
	proc/ApplyAFKOverlay()
		RemoveAFKOverlay()

		if(!away) return

		var/mob/Player/user = src
		if(locate(/obj/items/wearable/afk/pimp_ring) in user.Lwearing)
			if(src.House=="Slytherin")
				src.overlays += image('AFK.dmi', icon_state = "S")
			else if(src.House=="Gryffindor")
				src.overlays += image('AFK.dmi', icon_state = "G")
			else if(src.House=="Hufflepuff")
				src.overlays += image('AFK.dmi', icon_state = "H")
			else
				src.overlays += image('AFK.dmi', icon_state = "R")
		else if(locate(/obj/items/wearable/afk/hot_chocolate) in user.Lwearing)
			src.overlays+=image('AFK.dmi',icon_state="AFK2")
		else if(locate(/obj/items/wearable/afk/heart_ring) in user.Lwearing)
			src.overlays+=image('AFK.dmi',icon_state="AFK3")
		else
			src.overlays+=image('AFK.dmi',icon_state="AFK1")

mob
	proc/RemoveAFKOverlay()
		overlays-=image('AFK.dmi',icon_state="AFK1")
		overlays-=image('AFK.dmi',icon_state="AFK2")
		overlays-=image('AFK.dmi',icon_state="AFK3")
		overlays-=image('AFK.dmi',icon_state="S")
		overlays-=image('AFK.dmi',icon_state="G")
		overlays-=image('AFK.dmi',icon_state="H")
		overlays-=image('AFK.dmi',icon_state="R")


mob/Player
	Stat()
		if(statpanel("Stats"))
			stat("Name:",src.name)
			stat("Year:",src.Year)
			stat("Gold:",comma(src.gold))
			stat("Level:",src.level)
			stat("HP:","[src.HP]/[src.MHP+src.extraMHP]")
			stat("MP:","[src.MP]/[src.MMP+src.extraMMP] ([src.extraMMP/10])")
			if (src.level>500)
				stat("Damage:","[src.Dmg+src.extraDmg] ([src.extraDmg])")
				stat("Defense:","[src.Def+src.extraDef] ([src.extraDef/3])")
			stat("House:",src.House)
			if(level >= lvlcap && rankLevel)
				var/percent = round((rankLevel.exp / rankLevel.maxExp) * 100)
				stat("Experience Rank: ", "[rankLevel.level]   Exp: [comma(rankLevel.exp)]/[comma(rankLevel.maxExp)] ([percent]%)")
				stat("\icon[getRankIcon()]")
			else
				var/percent = round((Exp / Mexp) * 100)
				stat("EXP:", "[comma(src.Exp)]/[comma(src.Mexp)] ([percent]%)")
			if(wand && (wand.exp + wand.quality > 0))
				var/percent = round((wand.exp / wand.maxExp()) * 100)
				stat("Wand:", "Level: [wand.quality * 10]   Exp: [comma(wand.exp)]/[comma(wand.maxExp())] ([percent]%)")
			stat("Stat points:",src.StatPoints)
			stat("Spell points:",src.spellpoints)
			if(learning)
				stat("Learning:", learning.name)
				stat("Uses required:", learning.uses)
			if(admin)
				stat("CPU:",world.cpu)
			stat("---House points---")
			stat("Gryffindor",housepointsGSRH[1])
			stat("Slytherin",housepointsGSRH[2])
			stat("Ravenclaw",housepointsGSRH[3])
			stat("Hufflepuff",housepointsGSRH[4])
			if(src.Auror)
				stat("---Clan points---")
				stat("-Aurors-",housepointsGSRH[5])
			if(src.DeathEater)
				stat("---Clan points---")
				stat("-Deatheaters-",housepointsGSRH[6])
			stat("","")
			if(currentEvents)
				stat("Current Events:","")
				for(var/key in currentEvents)
					stat("", key)
			if(currentArena)
				if(currentArena.roundtype == HOUSE_WARS)
					stat("Arena:")
					stat("Gryffindor",currentArena.teampoints["Gryffindor"])
					stat("Slytherin",currentArena.teampoints["Slytherin"])
					stat("Hufflepuff",currentArena.teampoints["Hufflepuff"])
					stat("Ravenclaw",currentArena.teampoints["Ravenclaw"])
				else if(currentArena.roundtype == CLAN_WARS)
					stat("Arena:")
					stat("Aurors",currentArena.teampoints["Aurors"])
					stat("Deatheaters",currentArena.teampoints["Deatheaters"])
				else if(currentArena.roundtype == FFA_WARS)
					stat("Arena: (Players Alive)")
					for(var/mob/M in currentArena.players)
						stat("-",M.name)
			if(currentMatches.arenas)
				stat("Matchmaking:", "(Click to spectate. Click again to stop.)")
				for(var/arena/a in currentMatches.arenas)
					stat(a.spectateObj)


		if(statpanel("Items"))
			for(var/obj/stackobj/S in contents)
				stat("Click to expand stacked items.")
				break
			for(var/obj/O in src.contents)
				if(istype(O,/obj/stackobj))
					stat("+",O)
					if(O:isopen)
						for(var/obj/B in O:contains)
							stat("-",B)
					//	stat(O:contains)//Display all the objects inside the stack obj
				else
					if(istype(src,/mob/Player))
						if(!src:stackobjects || !(src:stackobjects.Find(O.type))) //If there's NOT a stack object for this obj type, print it
							stat(O)
obj
	stackobj
		var/isopen=0
		var/containstype
		var/list/obj/contains = list()
		mouse_over_pointer = MOUSE_HAND_POINTER
		name = "(Click to Expand)"
		Click()
			if(src in usr)
				isopen = !isopen
		verb
			Drop_All()
				set category = null
				var/tmpname = ""
				//var/isscroll=0
				for(var/obj/items/O in contains)
					var/founddrop = 0
					for(var/V in O.verbs)
						if(V:name == "Drop")
							founddrop =1
							break
					if(!founddrop)
						usr << errormsg("This type of item can't be dropped.")
						return
					//tmpname = O.name
					//if(istype(O,/obj/items/scroll))
				//		isscroll = 1
					//O.Move(usr.loc)
					tmpname = O.name
					O.drop(usr, O.stack)
				hearers(owner) << infomsg("[usr] drops all of \his [tmpname] items.")
				/*if(isscroll)
					hearers(usr) << "[usr] drops all of \his scrolls."
				else
					switch(copytext(tmpname,length(tmpname)))//Check last letter for pluralizness
						if("f")
							hearers(usr) << "[usr] drops all of \his [copytext(tmpname,1,length(tmpname))]ves."
						if("s")
							hearers(usr) << "[usr] drops all of \his [tmpname]."
						else
							hearers(usr) << "[usr] drops all of \his [tmpname]s."
				*/
				del(src)


mob/Player/var/tmp/list/obj/stackobj/stackobjects

mob/proc/Resort_Stacking_Inv()
	if(!istype(src,/mob/Player))
		world.log << "[src] is of the wrong type ([src.type]) in /mob/proc/Resort_Stacking_Inv()"
		return
	var/list/counts = list()

	for(var/obj/O in contents)
		//if(istype(O,/Spell)) continue
		if(istype(O,/obj/stackobj))
			O.loc = null
		else
			counts[O.type]++
	if(length(counts))
		var/list/obj/stackobj/tmpstackobjects = list()
		for(var/V in counts)
			if(counts[V] > 1)
				var/obj/stackobj/stack = new()
				var/obj/tmpV = new V
				stack.containstype = V
				if(src:stackobjects)
					if(src:stackobjects[V])
						var/obj/stackobj/tmpstack = src:stackobjects[V]
						stack.isopen = tmpstack.isopen
				stack.icon = tmpV.icon
				stack.icon_state = tmpV.icon_state
	//			stack.name = tmpV.name
				contents += stack
				for(var/obj/O in contents)
					if(istype(O,stack.containstype))
						stack.contains += O
				var/c = 0
				for(var/obj/items/i in stack.contains)
					c += i.stack
				stack.suffix = "<font color=red>(x[c])</font>"
				tmpstackobjects[V] = stack
		src:stackobjects = tmpstackobjects
	else
		src:stackobjects = null
mob/proc/Check_Death_Drop()
	usr=src
	for(var/obj/drop_on_death/O in src)
		O.Drop()

mob/proc/Death_Check(mob/killer = src)
	killer.updateHPMP()
	src.updateHPMP()
	if(src.HP<1)
		if(src.player)
			Check_Death_Drop()
			for(var/turf/duelsystemcenter/T in duelsystems)
				if(T.D)
					if(T.D.player1 == src)
						range(8,T) << "<i>[T.D.player1] has lost the duel. [T.D.player2] is the winner!</i>"
						del T.D
					else if(T.D.player2 == src)
						range(8,T) << "<i>[T.D.player2] has lost the duel. [T.D.player1] is the winner!</i>"
						del T.D
			for(var/obj/items/portduelsystem/T in duelsystems)
				if(T.D)
					if(T.D.player1 == src)
						range(8,T) << "<i>[T.D.player1] has lost the duel. [T.D.player2] is the winner!</i>"
						del T.D
					else if(T.D.player2 == src)
						range(8,T) << "<i>[T.D.player2] has lost the duel. [T.D.player1] is the winner!</i>"
						del T.D
			if(src.arcessoing == 1)
				hearers() << "[src] stops waiting for a partner."
				src.arcessoing = 0
			else if(ismob(arcessoing))
				hearers() << "[src] pulls out of the spell."
				stop_arcesso()
			if(src.Detention)
				sleep(1)
				flick('teleboom.dmi',src)
				return
				//src<<"<b><font color=red>Advice:</b></font> You can't kill yourself to get out of detention. Attempt to do it again and all of your spells will be erased from your memory."
			if(src.Immortal==1)
				src<<"[killer] tried to knock you out, but you are immortal."
				killer<<"<font color=blue><b>[src] is immortal and cannot die.</b></font>"
				return
			if(src.monster==1)
				del src
				return
			if(istype(src.loc.loc,/area/hogwarts/Duel_Arenas))
				src.followplayer=0
				src.HP=src.MHP+src.extraMHP
				src.MP=src.MMP+src.extraMMP
				src.updateHPMP()
				flick('mist.dmi',src)
				var/mob/Player/p = src
				switch(src.loc.loc.type)
					if(/area/hogwarts/Duel_Arenas/Main_Arena_Bottom)
						p.Transfer(locate("DuelArena_Death"))
					if(/area/hogwarts/Duel_Arenas/Matchmaking/Main_Arena_Top)
						var/obj/o = pick(duel_chairs)
						p.Transfer(o.loc)
					if(/area/hogwarts/Duel_Arenas/Slytherin)
						p.Transfer(locate("Slyth_Death"))
					if(/area/hogwarts/Duel_Arenas/Gryffindor)
						p.Transfer(locate("Gryffin_Death"))
					if(/area/hogwarts/Duel_Arenas/Ravenclaw)
						p.Transfer(locate("Raven_Death"))
					if(/area/hogwarts/Duel_Arenas/Hufflepuff)
						p.Transfer(locate("Huffle_Death"))
					if(/area/hogwarts/Duel_Arenas/Matchmaking/Duel_Class)
						p.Transfer(locate("DuelClass_Death"))
					if(/area/hogwarts/Duel_Arenas/Defence_Against_the_Dark_Arts)
						p.Transfer(locate("DADA_Death"))
					if(/area/hogwarts/Duel_Arenas/Main_Arena_Lobby)
						var/obj/Bed/B = pick(Beds)
						p.Transfer(B.loc)
						src.dir = SOUTH
				flick('dlo.dmi',src)
				src<<"<i>You were knocked out by <b>[killer]</b>!</i>"
				if(src.removeoMob) spawn()src:Permoveo()
				src.sight &= ~BLIND
				return
			if(src.loc.loc.type == /area/hogwarts/Hospital_Wing)
				src.HP=src.MHP+src.extraMHP
				src.updateHPMP()
				return
			if(src.loc.loc.type == /area/Underwater)
				src.followplayer=0
				src.HP=src.MHP+src.extraMHP
				src.MP=src.MMP+src.extraMMP
				src.updateHPMP()
				flick('mist.dmi',src)
				src.loc=locate(8,8,9)
				flick('dlo.dmi',src)
				src<<"<i>You were knocked out by <b>[killer]</b>!</i>"
				if(src.removeoMob) spawn()src:Permoveo()
				src.sight &= ~BLIND
				return

			if(src.loc.loc.type in typesof(/area/arenas/MapThree/WaitingArea))
				killer << "Do not attack in the waiting area.."
				src.HP = src.MHP+extraMHP
				return
			if(src.loc.loc.type in typesof(/area/arenas/MapThree/PlayArea))
				if(currentArena)
					var/list/players = range(8,currentArena.speaker)|currentArena.players
					if(killer != src)
						players << "<b>Arena</b>: [killer] killed [src]."
					else
						players << "<b>Arena</b>: [killer] killed themself."
					currentArena.players.Remove(src)
					src.HP=src.MHP+extraMHP
					src.MP=src.MMP+extraMMP
					src.updateHPMP()
					if(currentArena.players.len == 1)
						var/mob/winner
						for(var/mob/M in currentArena.players)
							winner = M
						players << "<b>Arena</b>: [winner] wins the round!"
						var/turf/T = pick(MapThreeWaitingAreaTurfs)
						winner.loc = T
						winner.density = 1
						for(var/mob/Z in view(8,currentArena.speaker))
							Z << "<b>You can leave at any time when a round hasn't started by <a href=\"byond://?src=\ref[Z];action=arena_leave\">clicking here.</a></b>"

						var/RandomEvent/FFA/e = locate() in events
						if(e)
							e.winner = winner

						del(currentArena)
					else if(currentArena.players.len == 0)
						var/mob/winner
						winner = src
						players << "<b>Arena</b>: [winner] wins the round!"
						var/turf/T = pick(MapThreeWaitingAreaTurfs)
						winner.loc = T
						winner.density = 1
						for(var/mob/Z in view(8,currentArena.speaker))
							Z << "<b>You can leave at any time when a round hasn't started by <a href=\"byond://?src=\ref[Z];action=arena_leave\">clicking here.</a></b>"
						del(currentArena)
					var/turf/T = pick(MapThreeWaitingAreaTurfs)
					src.loc = T
					density = 1
					return
				else
					killer << "Do not attack before a round has started."
					src.HP = src.MHP+extraMHP
					return
			if(clanwars)
			//world clanwars
				if(killer.aurorrobe && src.DeathEater)
					src << "You were killed by [killer] of the Aurors."
					housepointsGSRH[5] += 1
					clanwars_event.add_auror(1)

					if(clanevent1_pointsgivenforkill)
						housepointsGSRH[5] += clanevent1_pointsgivenforkill
						clanwars_event.add_auror(clanevent1_pointsgivenforkill)
				else if(killer.derobe && src.Auror)
					src << "You were killed by a [killer]."
					housepointsGSRH[6] += 1
					clanwars_event.add_de(1)

					if(clanevent1_pointsgivenforkill)
						housepointsGSRH[6] += clanevent1_pointsgivenforkill
						clanwars_event.add_de(clanevent1_pointsgivenforkill)
			if(src.loc.loc.type in typesof(/area/arenas/MapTwo))
			/////CLAN WARS//////
				if(!(src.derobe && killer.derobe)&&!(src.aurorrobe && killer.aurorrobe))
					if(currentArena)
						if (currentArena.roundtype == CLAN_WARS)
							if(killer.aurorrobe)
								currentArena.Add_Point("Aurors",1)
								src << "You were killed by [killer] of the Aurors"
								killer << "You killed [src]"
							else if(killer.derobe)
								currentArena.Add_Point("Deatheaters",1)
								src << "You were killed by [killer]."
								killer << "You killed [src] of the Aurors"
				else if(src == killer)
					src << "You killed yourself!"
				else
					src << "You were killed by [killer], from your own team!"
					killer << "You killed [src] of your own team!"
				if(currentArena)
					if(currentArena.plyrSpawnTime > 0)
						src << "<i>You must wait [currentArena.plyrSpawnTime] seconds until you respawn.</i>"
				var/obj/Bed/B
				if(derobe)
					B = pick(Map2DEbeds)
				else if(aurorrobe)
					B = pick(Map2Aurorbeds)
				src.loc = B.loc
				src.dir = SOUTH
				if(currentArena)
					src.GMFrozen = 1
					spawn()currentArena.handleSpawnDelay(src)
				src.HP=src.MHP+extraMHP
				src.MP=src.MMP+extraMMP
				src.updateHPMP()
				return
			/////HOUSE WARS/////
			if(src.loc.loc.type in typesof(/area/arenas/MapOne))
				if(src.House != killer.House)
					if(currentArena)
						if(currentArena.roundtype == HOUSE_WARS && currentArena.started)
							currentArena.Add_Point(killer.House,1)
							src << "You were killed by [killer] of [killer.House]"
							killer << "You killed [src] of [src.House]"
				else if(src == killer)
					src << "You killed yourself!"
				else
					src << "You were killed by [killer], from your own team!"
					killer << "You killed [src] of your own team!"
				if(currentArena)
					if(currentArena.plyrSpawnTime > 0)
						src << "<i>You must wait [currentArena.plyrSpawnTime] seconds until you respawn.</i>"
				var/obj/Bed/B
				switch(House)
					if("Gryffindor")
						B = pick(Map1Gbeds)
					if("Hufflepuff")
						B = pick(Map1Hbeds)
					if("Slytherin")
						B = pick(Map1Sbeds)
					if("Ravenclaw")
						B = pick(Map1Rbeds)
				src.loc = B.loc
				src.dir = SOUTH
				if(currentArena)
					src.GMFrozen = 1
					spawn()currentArena.handleSpawnDelay(src)
				src.HP=src.MHP+extraMHP
				src.MP=src.MMP+extraMMP
				src.updateHPMP()
				return
			var/obj/Bed/B
			if(src.derobe)
				B = pick(DEBeds)
			else if(src.aurorrobe)
				B = pick(AurorBeds)
			else
				B = pick(Beds)
			if(!src.Detention)
				if(killer != src && !src:rankedArena)
					if(killer.client && src.client && killer.loc.loc.name != "outside")
						if(killer.name == "Robed Figure")
							if(src.name == "Robed Figure")
								file("Logs/kill_log.html") << "[time2text(world.realtime,"MMM DD YYYY - hh:mm:ss")]: [killer.prevname](DE robed) killed [src.prevname](DE robed): [src.loc.loc](<a href='?action=teleport;x=[src.x];y=[src.y];z=[src.z]'>Teleport</a>)<br>"
							else
								file("Logs/kill_log.html") << "[time2text(world.realtime,"MMM DD YYYY - hh:mm:ss")]: [killer.prevname](DE robed) killed [src]: [src.loc.loc](<a href='?action=teleport;x=[src.x];y=[src.y];z=[src.z]'>Teleport</a>)<br>"
						else
							if(src.name == "Robed Figure")
								file("Logs/kill_log.html") << "[time2text(world.realtime,"MMM DD YYYY - hh:mm:ss")]: [killer] killed [src.prevname](DE robed): [src.loc.loc](<a href='?action=teleport;x=[src.x];y=[src.y];z=[src.z]'>Teleport</a>)<br>"
							else
								file("Logs/kill_log.html") << "[time2text(world.realtime,"MMM DD YYYY - hh:mm:ss")]: [killer] killed [src]: [src.loc.loc](<a href='?action=teleport;x=[src.x];y=[src.y];z=[src.z]'>Teleport</a>)<br>"
					if(killer.client && get_dist(src, killer) == 1 && get_dir(src, killer) == turn(src.dir,180))
						src << "<i>You were knocked out by <b>someone from behind</b> and sent to the Hospital Wing!</i>"
					else
						src << "<i>You were knocked out by <b>[killer]</b> and sent to the Hospital Wing!</i>"

				src:nofly()
				if(src.removeoMob) spawn()src:Permoveo()

				src.followplayer=0
				Zitt = 0
				src.HP=src.MHP+extraMHP
				src.MP=src.MMP+extraMMP
				src.updateHPMP()
				src.gold.add(-gold.get() / 2)
				if(src.level < lvlcap)
					src.Exp = round(src.Exp / 2)
				src.sight &= ~BLIND
				flick('mist.dmi',src)
				if(!src:rankedArena)
					src:Transfer(B.loc)
					src.dir = SOUTH
				flick('dlo.dmi',src)

			if(killer.player)
				src.pdeaths+=1
				if(src:rankedArena)
					src:rankedArena.death(src)
				if(killer != src)
					killer.pkills+=1
					displayKills(killer, 1, 1)

					killer:checkQuestProgress("Kill Player")

					var/rndexp = round(src.level * 1.2) + rand(-200,200)
					if(rndexp < 0) rndexp = rand(20,30)

					if(killer.House == housecupwinner)
						rndexp *= 1.25
						rndexp = round(rndexp)

					killer:addExp(rndexp)
					if(killer:wand)
						var/obj/items/wearable/wands/w = killer:wand
						w.addExp(killer, round(rndexp / 30))

					if(killer.level < lvlcap)
						killer << infomsg("You knocked [src] out and gained [rndexp] exp.")
					else
						if(!killer.findStatusEffect(/StatusEffect/KilledPlayer)) // prevents spam killing people for gold in short time
							rndexp = rndexp * rand(2,5)
							new /StatusEffect/KilledPlayer (killer, 30)
						else
							rndexp = round(rndexp * 0.4)
						killer.gold.add(rndexp)
						killer<<infomsg("You knocked [src] out and gained [rndexp] gold.")

					var/rep = -round(1 + (src:getRep() / 100), 1)

					if(rep >= 0)
						rep = max(rep, 1)
					else
						rep = min(rep, -1)

					killer:addRep(rep)
				else
					src<<"You knocked yourself out!"
			else
				src.edeaths+=1


		else
			if(killer.client)
				if(istype(src, /mob/NPC/Enemies))
					if(!istype(src, /mob/NPC/Enemies/Summoned))
						killer.AddKill(src.name)
					killer:checkQuestProgress("Kill [src.name]")
				if(killer.MonsterMessages)killer<<"<i><small>You knocked [src] out!</small></i>"

				killer.ekills+=1
				displayKills(killer, 1, 2)
				var/gold2give = (rand(7,14)/10)*gold
				var/exp2give  = (rand(9,14)/10)*Expg

				if(killer.level > src.level && !killer.findStatusEffect(/StatusEffect/Lamps/Farming))
					gold2give -= gold2give * ((killer.level-src.level)/150)
					exp2give  -= exp2give  * ((killer.level-src.level)/150)

				if(killer.House == housecupwinner)
					gold2give *= 1.25
					exp2give  *= 1.25

				var/StatusEffect/Lamps/Gold/gold_rate = killer.findStatusEffect(/StatusEffect/Lamps/Gold)
				var/StatusEffect/Lamps/Exp/exp_rate   = killer.findStatusEffect(/StatusEffect/Lamps/Exp)

				if(gold_rate) gold2give *= gold_rate.rate
				if(exp_rate)  exp2give  *= exp_rate.rate

				gold2give = round(gold2give)

				if(killer.MonsterMessages)

					if(exp2give > 0 && killer.level < lvlcap)
						killer<<"<i><small>You gained [exp2give] exp[gold2give > 0 ? " and [gold2give] gold" : ""].</small></i>"
					else if(gold2give > 0)
						killer<<"<i><small>You gained [gold2give] gold.</small></i>"

				if(gold2give > 0)
					killer.gold.add(gold2give)
				if(exp2give > 0)
					killer:addExp(exp2give, !killer.MonsterMessages)

					if(killer:wand)
						var/obj/items/wearable/wands/w = killer:wand
						w.addExp(killer, round(exp2give / 50))

			if(src.type == /mob/Slug)
				del src
				return ..()
			//else Statpoints for monster killz.
			//	if(rand(1,80)==1 && killer.client)
			//		killer.verbs.Add(/mob/Player/verb/Use_Statpoints)
			//		killer.StatPoints++
			if(istype(src, /mob/NPC/Enemies))
				src:Death(killer)
			src.loc=locate(0,0,0)
			Respawn(src)

mob/Player/proc/Auto_Mute(timer=15, reason="spammed")
	if(mute==0)
		mute=1
		Players << "\red <b>[src] has been silenced.</b>"

		if(reason)
			src << "<b>You've been muted because you [reason].</b>"

		if(timer==0)
			Log_admin("[src] has been muted automatically.")
		else
			Log_admin("[src] has been muted automatically for [timer] minutes.")
			timerMute = timer
			if(timer != 0)
				src << "<u>You've been muted for [timer] minute[timer==1 ? "" : "s"].</u>"
			spawn()mute_countdown()

		spawn()sql_add_plyr_log(ckey,"si",reason,timer)

/*
		Auto_Ban()
			world<<"<B><Font face='Comic Sans MS'>HGM Security: <Font color=green><Font face='Comic Sans MS'>[src] has been automatically banned for Spamming on the main chat channel."
			usr.client.FullBan(usr.key,usr.client.address)
*/

	//	damageblock()
	//		src.HP-=(src.HP/8)


mob/proc/resetStatPoints()
	src.StatPoints = src.level - 1
	src.extraMHP = 0
	src.extraMMP = 0
	src.extraDmg = 0
	src.extraDef = 0
	src.Dmg = (src.level - 1) + 5
	src.Def = (src.level - 1) + 5
	resetMaxHP()
	src.verbs.Add(/mob/Player/verb/Use_Statpoints)
mob/proc/resetMaxHP()
	src.MHP = 4 * (src.level - 1) + 200 + 2 * (src.Def + src.extraDef + src.clothDef)
	if(HP > MHP)
		HP = MHP
mob
	proc
		LvlCheck(var/fakelevels=0)
			if(level >= lvlcap)
				Exp = 0
				return
			if(src.Exp>=src.Mexp)
				src.level++
				src.MMP = level * 6
				src.MP=src.MMP+extraMMP
				src.Dmg+=1
				src.Def+=1
				src.resetMaxHP()
				src.HP=src.MHP+extraMHP
				src.updateHPMP()
				//src.Expg=src.Texp
				src.Exp=0
				src.verbs.Remove(/mob/Player/verb/Use_Statpoints)
				src.verbs.Add(/mob/Player/verb/Use_Statpoints)
				src.StatPoints++
				if(src.Mexp<2000)
					src.Mexp*=1.5
				else if(src.Mexp>2000)
					src.Mexp+=500
				Mexp = round(Mexp)
				if(!fakelevels)
					src<<"<b><font color=blue>You are now level [src.level]!</font></b>"
				//	src<<"HP increased by [HPplus]."
				//	src<<"MP increased by [MPplus]."
				//	src<<"Damage increased by [Dmgplus]."
				//	src<<"Defense increased by [Defplus]."
					src<<"You have gained a statpoint."
				var/theiryear = (src.Year == "Hogwarts Graduate" ? 8 : text2num(copytext(src.Year, 1, 2)))
				if(src.level>1 && src.level < 16)
					src.Year="1st Year"
				else if(src.level>15 && theiryear < 2)
					src.Year="2nd Year"
					src<<"<b>Congratulations, you are now on your Second Year at Hogwarts.</b>"
					src.verbs += /mob/Spells/verb/Episky
					src<<"<b><font color=green><font size=3>You learned Episkey."
				else if(src.level>50 && theiryear < 3)
					src.Year="3rd Year"
					src<<"<b>Congratulations on attaining your 3rd Year rank promotion!</b>"
					src<<infomsg("You learned how to cancel transfigurations!")
					src.verbs += /mob/Spells/verb/Self_To_Human
				else if(src.level>100 && theiryear < 4)
					src.Year="4th Year"
					src<<"<b>Congratulations to [src]. You are now a 4th Year."
					src.verbs += /mob/Spells/verb/Self_To_Dragon
					src<<"<b><font color=green><font size=3>You learned how to Transfigure yourself into a fearsome Dragon!"
				else if(src.level>200 && theiryear < 5)
					src.Year="5th Year"
					src<<"<b>Congratulations to [src]. You are now a 5th Year."
				else if(src.level>300 && theiryear < 6)
					src.Year="6th Year"
					src<<"<b>Congratulations to [src]. You are now a 6th Year."
				else if(src.level>400 && theiryear < 7)
					src.Year="7th Year"
					src<<"<b>Congratulations to [src]. You are now a 7th Year."
				else if(src.level>500 && theiryear < 8)
					src.Year="Hogwarts Graduate"
					src<<"Congratulations, [src]! You have graduated from Hogwarts and attained the rank of Hogwarts Graduate."
					src<<infomsg("You can now view your damage & defense stats in the stats tab.")

obj/Banker
	icon = 'NPCs.dmi'
	density=1
	mouse_over_pointer = MOUSE_HAND_POINTER

	var/gold/goldinbank

	New()
		..()
		spawn(1) icon_state = "goblin[rand(1,3)]"
		namefont.QuickName(src, src.name, rgb(255,255,255), "#000", top=1)

	Click()
		..()
		if(src in oview(3))
			Talk()
		else
			usr << errormsg("You need to be closer.")

	proc
		addGold(var/amount, mob/Player/p)
			if(goldinbank != null)
				if(isnum(goldinbank)) goldinbank = new /gold(goldinbank)
				goldinbank.add(amount)
			else
				p.goldinbank.add(amount)
		getGold(mob/Player/p)
			if(goldinbank && isnum(goldinbank)) goldinbank = new /gold(goldinbank)
			return goldinbank != null ? goldinbank.get() : p.goldinbank.get()


	verb
		Examine()
			set src in oview(3)
			usr << "He looks like a trustworthy person to hold my money."
		Talk()
			set src in oview(3)

			var/mob/Player/p = usr
			var/list/choices = list("Deposit","Withdraw","Balance")

			if("On House Arrest" in p.questPointers)
				var/questPointer/pointer = p.questPointers["On House Arrest"]
				if(pointer.stage == 1) choices += "I'd like to withdraw something from Fred's vault"

			switch(input("How may I help you?","Banker") in choices)
				if("I'd like to withdraw something from Fred's vault")
					alert("You hand the banker the key")
					switch(input("And what would you like to withdraw?","Banker")in list("Wand of Interuption","Cancel"))
						if("Wand of Interuption")
							alert("The banker takes the key and unlocks a small compartment under his desk.")
							alert("He pulls out a box, and removes the wand from it")
							alert("The banker hands you the wand")
							new/obj/items/wearable/wands/interruption_wand(usr)

							var/obj/items/freds_key/k = locate() in usr
							if(k)
								k.loc = null

							p.Resort_Stacking_Inv()
							p.checkQuestProgress("Fred's Wand")
				if("Deposit")
					var/heh = input("You have [comma(usr.gold)] gold. How much do you wish to deposit?","Deposit",usr.gold.get()) as null|num
					if(heh==null)return
					if (heh < 0)
						alert("Don't try cheating me!","Bank Keeper")
						return()
					if (heh > usr.gold.get())
						alert("You don't have that much!", "Deposit")
						return()
					if(get_dist(usr,src)>4)return
					usr << "You deposit [comma(heh)] gold."
					usr.gold.add(-heh)
					addGold(heh, usr)
					usr << "You now have [comma(getGold(usr))] gold in the bank."
				if("Withdraw")
					var/heh = input("You have [comma(getGold(usr))] gold in the bank. How much do you wish to withdraw?","Withdraw",getGold(usr)) as null|num
					if(heh==null)return
					if (heh < 0)
						alert("Don't try cheating me!","Bank Keeper")
						return()
					if (heh > getGold(usr))
						alert("You don't have that much in your bank account!", "Bank Keeper")
						return()
					if(get_dist(usr,src)>4)return
					usr << "You withdraw [comma(heh)] gold."
					usr.gold.add(heh)
					addGold(-heh, usr)
					usr << "You now have [comma(getGold(usr))] gold in the bank."
				if("Balance")
					usr << "You have [comma(getGold(usr))] gold in the bank."


obj
	Bank
		Vault
			icon = 'vault.dmi'
			density=1
			accioable=0
			dontsave = 1
			verb
				Examine()
					set src in oview(3)
					usr << "I wonder how everything I have fits into this vault..."
				Bank()
					set src in oview(3)

					if(!usr.bank)
						usr.bank = new/BankClass
					switch(alert("Would you like to deposit or withdraw an item?","Banking", "Deposit", "Withdraw"))

						if("Deposit")
							var/list/obj/inventory = list()
							for(var/obj/O in usr.contents)
								if(!istype(O,/obj/stackobj))
									inventory += O
							var/obj/O = input("Which item would you like to deposit?") as null|obj in inventory
							if(O)
								if(get_dist(usr,src)>4)return
								if(!(O in usr))return
								usr.bank.DepositItem(O)
								usr << "You have deposited [O.name]!"
								usr:Resort_Stacking_Inv()
						else if("Withdraw")
							var/obj/O = input("Which item would you like to withdraw?") as null|obj in usr.bank.GetItems()
							if(O)
								if(get_dist(usr,src)>4)return
								usr.bank.WithdrawItem(O)
								usr << "You have withdrawn [O.name]!"
								usr:Resort_Stacking_Inv()

BankClass
	var
		balance = 0
		list/items = list()
	proc
		GetBalance()
			return src.balance

		DepositMoney(var/num)
			src.balance += num
			return num

		WithdrawMoney(var/num)
			balance -= num
			return num

		DepositItem(var/obj/O)
			src.items.Add(O)
			usr.contents.Remove(O)

		WithdrawItem(var/obj/O)
			src.items.Remove(O)
			usr.contents.Add(O)

		GetItems()
			return src.items


mob
	var
		BankClass/bank = null

//VARS
//appearance
mob/var/Detention=0
mob/var/Rank=""
mob/var/Immortal=0
mob/var/Disperse
mob/var/Aero
obj/var/accioable=0
obj/var/clothes
mob/var/DeathEater

mob/var/MuteOOC=0

mob/var/Year=""
mob/var/Teleblock=0
mob/var/House
mob/var/Auror
mob/var/DE
mob/var/Tag=null
mob/var/GMTag=null
mob/var/HA
mob/var/HDE

obj/var/dontsave=0
//others
mob/var/base_num_characters_allowed=0
mob/var/level=1
mob/var/Dmg=5
mob/var/Def=5
mob/var/HP=200
mob/var/MHP=200
mob/var/MP=10
mob/var/MMP=10

mob/var/Mexp=5
mob/var/Exp=0
mob/var/Expg=1
mob/var/draganddrop=0
mob/var/picon=null
mob/var/Texp=0
mob/var/NPC=1
mob/var/mute=0
mob/var/listenooc=1
mob/var/listenhousechat=1
mob/var/player=0
mob/var/gold/gold
mob/var/goldg=1
mob/var/gold/goldinbank

mob/var/monster=0
mob/var/follow=0
mob/var/attack=0
mob/var/wander=0
mob/var/tmp/away=0
mob/var/followplayer=0
mob/var/rank=0
mob/var/description="No extra information provided."
//mob/var/summonable=0
mob/var/skills=0
mob/var/item=0
mob/var/location
mob/var/turf
mob/var/tmp/status=""
mob/var/here=""
mob/var/potion=0
mob/var/ether=0
mob/var/notmonster=1
mob/var/edeaths=0
mob/var/ekills=0
mob/var/pdeaths=0
mob/var/pkills=0
mob/var/carry=0
mob/var/Gm=0

mob/var/StatPoints=0



var/mob/HA=0
obj/var/picon=null
obj/var/value=0
obj/var/lastx
obj/var/lasty
obj/var/lastz

obj/var/damage=0
obj/var/tmp/mob/owner

var/autoheal=0
//playerhouses

var
	Flash = 0
	System = 0

mob/var/tmp
	spam=0
//layers
var/const
	clothes=MOB_LAYER+1
	Mail=MOB_LAYER+2
	head=MOB_LAYER+3
	ears=MOB_LAYER+4
	cape=MOB_LAYER+5
	weapon=MOB_LAYER+6

proc
	textcheck(t as text)
	// Returns the text string with all potential html tags (anything \
		between < and >) removed.
		t="[html_encode(t)]"
		var/open = findtext(t,"\<")
		while(open)
			var/close = findtext(t,"&gt;",open)
			if(close)
				if(close < lentext(t))
					t = copytext(t,1,open)+copytext(t,close+4)//+copytext(t,close+1)
				else
					t = copytext(t,1,open)
				open = findtext(t,"\<")
			else
				open = 0
		return t
	Respawn(mob/NPC/Enemies/E)
		if(!E)return
		if(E.removeoMob)
			var/tmpmob = E.removeoMob
			E.removeoMob = null
			spawn()tmpmob:Permoveo()
		if(!istype(E,/mob/NPC/Enemies))
			E.loc = null
		else
			E.ChangeState(E.INACTIVE)
			if(E.origloc)
				spawn(E.respawnTime)// + rand(-50,100))////1200
					if(E)
						E.loc = E.origloc
						E.HP = E.MHP
						E.ShouldIBeActive()
			else
				E.loc = null

proc/ServerAD()
	Players<<"<b><Font color=silver>Server:</b> <font size=1><font color=silver>Thanks for playing The Wizards' Chronicles. Forums: http://www.wizardschronicles.com"
	sleep(3000)
	ServerAD()

proc/SugAD()
	Players<<"<b><Font color=silver>Server:</b> <font size=1><font color=green>TWC is currently looking for loads more content to add! Got a suggestion? Post it on the suggestions board at http://www.wizardschronicles.com <br>The only bad suggestion is the one not shared!"
	sleep(9000)
	SugAD()


proc/ServerRW()
	Players<<"<b><Font color=silver>Server:</b> <font size=1><font color=red> The server is currently in Developer Mode. This means that the game is currently being coded and updated - Reboots may be frequent."
	sleep(3000)
	ServerRW()

turf/proc/autojoin(var_name, var_value = 1)
	var/n = 0
	var/turf/t
	t = locate(x, y + 1, z)
	if(t && t.vars[var_name] == var_value) n |= 1
	t = locate(x + 1, y, z)
	if(t && t.vars[var_name] == var_value) n |= 2
	t = locate(x, y - 1, z)
	if(t && t.vars[var_name] == var_value) n |= 4
	t = locate(x - 1, y, z)
	if(t && t.vars[var_name] == var_value) n |= 8

	return n