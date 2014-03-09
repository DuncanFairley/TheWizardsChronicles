trading
	var
		mob/Player/parent
		mob/Player/with
		list/items = list()
		gold = 0
		accept = 0
		y = 1

	New(mob/Player/parent, mob/Player/with)
		..()
		src.parent = parent
		src.with   = with
		winset(parent, null, {"Trade.is-visible=true;Trade.Name1.text="[with.name]";Trade.Name2.text="[parent.name]";Trade.GoldInput.text=0"})

	proc
		Deal(end = 0)

			for(var/obj/O in items)
				O.loc = with
			with.gold += gold
			parent.gold -= gold

			if(!end) spawn() with.trade.Deal(1)

			parent.Resort_Stacking_Inv()
			Clean()


		Clean(end = 0)
			for(var/obj/O in items)
				O.loc = parent

			if(!end && with && with.isTrading()) with.trade.Clean(1)

			with = null

			if(parent)
				if(parent.client)
					winset(parent, null, {"Trade.is-visible=false;Trade.grid1.background-color=white;Trade.grid2.background-color=white;Trade.grid1.cells=0x0;Trade.grid2.cells=0x0;Trade.gold1.text=0;Trade.gold2.text=0"})
					parent.Resort_Stacking_Inv()
				parent.trade = null
				parent = null

mob/Player
	var/tmp/trading/trade


	proc
		isTrading()
			return trade && trade.with
	verb
		Trade()
			set src in range(2)
			set category = null
			var/mob/Player/trader = usr
			if(isTrading())
				usr << errormsg("[usr] is already trading!")
				return

			if(trader.isTrading())
				usr << errormsg("You are already trading!")
				return

			trader.trade = new(trader, src)
			trade        = new(src, trader)


		ATrade(action as text)
			set hidden = 1
			if(!trade.with)
				trade.Clean()
				return

			if(action == "Close")
				trade.Clean()

			else if(action == "Done")
				if(trade.accept == 1)
					trade.accept = 0
					winset(src, "Trade.grid1", "background-color=white")
					winset(trade.with, "Trade.grid2", "background-color=white")
				else
					trade.accept = 1
					if(trade.with.trade.accept)
						trade.Deal()
					else
						winset(src, "Trade.grid1", "background-color=green")
						winset(trade.with, "Trade.grid2", "background-color=green")

			else if(action == "Money")
				if((!trade.accept) && (!trade.with.trade.accept))
					var/gcheck = text2num(winget(src, "Trade.GoldInput", "text"))
					if(!isnum(gcheck) || gcheck == null)
						winset(src, "Trade.error", {"text="Please write a number""})
					else
						gcheck = round(gcheck)
						if(gcheck < 0)
							winset(src, "Trade.error", {"text="Number must be larger than 0""})
						else if(gcheck > src.gold)
							winset(src, "Trade.error", {"text="You don't have that much gold""})
						else
							trade.gold = gcheck
							winset(src, null, {"Trade.gold1.text=[gcheck];Trade.error.text="""})
							winset(trade.with, "Trade.gold2", "text = [gcheck]")
				else
					src << errormsg("You can't change terms of the trade while one of you already accepted.")



obj/items

	MouseDrop(over_object,src_location,over_location,src_control,over_control,params)
		var/mob/Player/P = usr
		if(P.isTrading())
			if(over_control == "Trade.grid1" && !(src in P.trade.items))
				if(!P.trade.accept && !P.trade.with.trade.accept)
					if(dropable)
						if(src in usr:Lwearing)
							src:Equip(usr)
						winset(P, null, "Trade.grid1.cells=1x[P.trade.y];Trade.grid1.current-cell=1x[P.trade.y]")
						P << output(src, "Trade.grid1")
						winset(P.trade.with, null, "Trade.grid2=1x[P.trade.y];Trade.grid2.current-cell=1x[P.trade.y]")
						P.trade.with << output(src, "Trade.grid2")
						P.trade.items += src
						P.trade.y++
						P.contents -= src
						P.Resort_Stacking_Inv()
					else
						P << errormsg("This item can't be dropped")
				else
					P << errormsg("You can't change terms of the trade while one of you already accepted.")
		..()

	Click(location,control,params)
		var/mob/Player/P = usr
		if(P.isTrading() && (src in P.trade.items))
			if(!P.trade.accept && !P.trade.with.trade.accept)
				P.trade.y--
				P.trade.items -= src
				P.contents += src
				var/list/p = params2list(params)

				var/cell = text2num(findtext(p["drop-cell"], ",") ? copytext(p["drop-cell"], 3) : p["drop-cell"])

				if(P.trade.y-1 == 0)
					winset(P, "Trade.grid1", "cells=0")
					winset(P.trade.with, "Trade.grid2", "cells=0")
				else
					winset(P, null, "Trade.grid1.current-cell=1x[cell];Trade.grid1.cells=1x[P.trade.y-1]")
					winset(P.trade.with, null, "Trade.grid2.current-cell=1x[cell];Trade.grid2.cells=1x[P.trade.y-1]")

					if(cell <= P.trade.items.len)
						P << output(P.trade.items.len == 0 ? null : P.trade.items[P.trade.items.len], "Trade.grid1")
						P.trade.with << output(P.trade.items.len == 0 ? null : P.trade.items[P.trade.items.len], "Trade.grid2")
				P.Resort_Stacking_Inv()
			else
				P << errormsg("You can't change terms of the trade while one of you already accepted.")
		else
			..()


