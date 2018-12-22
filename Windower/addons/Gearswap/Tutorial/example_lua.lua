-- Framework File using Bard as an example. 
-- Not all inclusive, so use the below link for more information regarding gearswap
-- Gearswap Documentation Link: https://docs.windower.net/addons/gearswap/

function get_sets()  --just let this rock

	mote_include_version = 2 --necessary for including the Mote-Files
	
	include('Mote-Include.lua') -- Motenten's custom library in /Windower4/addons/Gearswap/libs/ 
								-- enables many funcionalities:
									-- does all the handling for pre/mid/aftercast swaps
									-- kneeling and casting from kneeling (so you don't have to )
									-- custom "modes" (offenseMode, castingMode, idleMode, etc.) seen in "user_setup"
								-- things you may want to comment out/change
									-- shadow cancelling (Mote-Utility.lua line 43)
									-- refineWaltz (Mote-Utility.lua line 145~259)
									

end

function job_setup() -- add job specific things like when specific buffs are active, you can also load personalized libraries here (like Kay-Include.lua)

	state.Buff['Pianissimo'] = buffactive['Pianissimo'] or false
	state.Buff['Nightingale'] = buffactive['Nightingale'] or false
	state.Buff['Troubadour'] = buffactive['Troubadour'] or false

end

function user_setup() -- user/character specific things like the "modes" noted above, arrays for specific sets of spells/weapons

	-- states can be swapped between by pressing f9~f12, ctrl+f9~f12, alt+f9~12
	-- Mote-Files have their own default mapping for these swaps 
		-- one can overwrite them by following the syntax of the last line of this function
		
	state.IdleMode:options('Normal','Combat') -- when idle
	state.OffenseMode:options('Normal','DW') -- when engaged
	state.WeaponskillMode:options('Normal','HNM') -- when performing weaponskills
	state.PhysicalDefenseMode:options('PDT') -- panic physical damage taken
	state.MagicalDefenseMode:options('MDT') -- panic magical damage taken
	state.CastingMode:options('Normal','Acc','Combat') -- when casting a spell
	
	sleeps            = S{'Sleep', 'Sleep II', 'Sleepga', 'Sleepga II', 'Bind'} -- debuffs where the only thing that matters is accuracy
	elemental_debuffs = S{'Burn','Choke','Shock','Rasp','Drown','Frost'} -- debuffs with a maximum potency
	
	spikes            = S{'Blaze Spikes','Shock Spikes','Ice Spikes'} -- buffs with weird stat scaling requirements
	
	bard_debuffs      = S{'Lullaby','Elegy','Requiem','Threnody'} -- songs where we want to equip sha'ir hands
	
	casting_mode = ''
	
	send_command('bind !f9 gs c cycle IdleMode') -- use ^ and ! for ctrl and alt respectively
	
end

function init_gear_sets() -- where the actual sets are defined. make sure to follow the syntax exactly

	sets.idle = {main="" 	-- set equipped when idle (standing around doing nothing). 
	            ,sub=""		-- names of all equipment slots listed in this set, so use it as a reference for others
				,range=""   -- this formatting doesn't need to be followed exactly, just do something that works for you
				,ammo=""
				,head=""
				,neck="Chocobo Whistle" -- example for inserting a piece of equipment. ***always put the full name listed in the item description***
				,ear1=""				-- word of warning regarding earrings and rings
				,ear2=""					-- if your set includes two items with the same name (ie. Merman's earring), gearswap can get turned around and fail to equip one
				,body=""					-- the easiest way to resolve this issue is to have the two items in separate bags (inventory and wardrobe2 for example)
				,hands=""
				,ring1=""
				,ring2=""
				,back=""
				,waist=""
				,legs=""
				,feet=""} 
	sets.idle.Town = set_combine(sets.idle, {back="Nexus cape"}) -- set combine prevents redundant work.
																 -- in this example, it is essentially sets.idle but with "Nexus Cape" in the "back" equipment slot
	sets.resting = {} -- equipped when resting, of course
	
	-- magic casting sets
	-- precast (sets that should be equipped before casting a spell and after the spell starts casting)
	sets.precast.FC = {} -- FC = fast cast
	sets.precast.FC['BardSong'] = set_combine(sets.precast.FC, {}) -- for specific spell families or specific spell names
	
	--midcast (sets that should be equipped during the cast time of a spell and unequipped after the cast has finished casting)
	sets.midcast.FastRecast = {} -- fill with equipment that will reduce the cooldown time of spells (fast cast, haste, etc.)
	
	sets.midcast['BardSong'] = {}
	
	sets.midcast['Utsusemi: Ni'] = {} -- sometimes specific spells require specific sets
	
	sets.midcast['Healing Magic'] = {}
	sets.midcast['Divine Magic'] = {}
	
	
	sets.midcast['Enfeebling Magic'] = {}														-- example: 
	sets.midcast['Enfeebling Magic'].Acc = set_combine(sets.midcast['Enfeebling Magic'], {}) 	-- these sets get equipped based on which "castingMode"
	sets.midcast['Enfeebling Magic'].Combat = set_combine(sets.midcast['Enfeebling Magic'], {}) -- the player has chosen
	
	sets.midcast['Elemental Magic'] = {}
	sets.midcast['Dark Magic'] = {}
	sets.midcast['Enhancing Magic'] = {}
	
	sets.midcast.Cure = {} -- all cures fall under Healing Magic, but not all Healing magic benefits from Cure Potency Equipment (paralyna, poisona, etc.)
	
	sets.midcast['Cursna'] = {} -- sometimes specific spells require specific sets
	
	-- AFTER THE CASTS ARE DONE, GEARSWAP WILL SWAP BACK TO YOUR ENGAGED (COVERED BELOW) OR IDLE SET DEPENDING ON WHETHER OR NOT YOU ARE ENGAGED OR IDLE
	-- engaged sets
	
	sets.engaged = {} -- equip this set when engaging an enemy in combat
	sets.engaged.DW = set_combine(sets.engaged, {ear1="Suppanomimi"}) -- uses this set if the CombatMode is set to DW
	
	-- weaponskill sets (sets that should be equipped before the weaponskill occurs)
	sets.precast.WS = {}
	sets.precast.WS.HNM = set_combine(sets.precast.WS, {}) -- weaponskill while WeaponskillMode is HNM
	
	sets.precast.WS['Mordant Rime'] = {} -- example: specific set for specific weaponskill, this takes priority over the sets.precast.WS
	sets.precast.WS['Mordant Rime'].HNM = set_combine(sets.precast.WS, {}) -- specific set for specific weaponskill while WeaponskillMode is HNM
	
	-- defense sets (sets that get equipped when the player toggles DefenseMode); THESE ARE NOT AUTOMATIC
	sets.defense.PDT = {} -- mitigate physical damage taken 
	sets.defense.MDT = {} -- mitigate magical damage taken
	
end

-- below are advanced functions that are NOT NECESSARY FOR USING GEARSWAP but expand the functionality greatly if one wishes
function job_precast(spell,action,spellMap,eventArgs) -- called before a spell has been cast, refer to the documentation for more information

	-- the example below automatically uses pianissimo when targeting another player with a song
	if spell.type == 'BardSong' then
		if ((spell.target.type == 'PLAYER' and not spell.target.charmed) or (spell.target.type == 'NPC' and spell.target.in_party)) and not state.Buff['Pianissimo'] then
			local spell_recasts = windower.ffxi.get_spell_recasts()
			if spell_recasts[spell.recast_id] < 2 then
				send_command('@input /ja "Pianissimo" <me>; wait 1.5; input /ma "'..spell.name..'" '..spell.target.name)
				eventArgs.cancel = true
				return
			end
		end
    end

end

function job_midcast(spell,action,spellMap,eventArgs) -- called after a spell has been cast, refer to the documentation for more information
	
	if spell.skill == 'Enfeebling Magic' then
		equip(sets.midcast[spell.skill][spell.type])
	else
		equip(sets.midcast[spell.skill])
	end

end

function job_get_spell_map(spell,spellMap,default_spell_map) -- called when gearswap tries to determine what the "spell_map" is
															 -- we can provide custom spell maps! these link to the arrays established above

	if spell.skill == 'Enfeebling Magic' and sleeps:contains(spell.english) then
		return 'Sleep'
	elseif spell.skill == 'Elemental Magic' and elemental_debuffs:contains(spell.english) then
		return 'EleEnfeebs'
	elseif spell.skill == 'Enhancing Magic' and spikes:contains(spell.english) then
		return 'Spikes'
	elseif bard_debuffs:contains(spellMap) or spell.english == 'Magic Finale' then
		return 'BardDebuff'
	end

end

function job_status_change(new,old) -- called when changing between engaged/idle/resting statuses: new = new status; old = old status

end

function job_buff_change(name,gain) -- called when you gain or lose a buff. name: name of the buff/debuff, gain: true/false based on if the buff was gained or not

end