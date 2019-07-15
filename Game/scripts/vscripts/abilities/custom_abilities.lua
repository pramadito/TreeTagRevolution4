--[[ Tree tracking ]]

destroyed_trees = {}
--========================ENT_ABILITIES=========================

function DestroyTree(event)
	local caster = event.caster
	local caster_team = caster:GetTeam()
	local target = event.target

	GridNav:DestroyTreesAroundPoint(target:GetAbsOrigin(), 20, false)
end

function DestroyTreesAoE(event)
	local caster = event.caster
	local caster_team = caster:GetTeam()
	local target_point = event.target_points[1]
	local radius = event.Radius

	GridNav:DestroyTreesAroundPoint(target_point, radius, false)
end

function RegrowTreeAoE_Small(event)
	BuildingHelper:RegrowTreesAOE(event)
	
end

--=======================BUILDING_ABILITIES========================
--RESOURCE STORAGE
function ProduceLumberandGoldCreate(event)
	local caster = event.caster
	Timers:CreateTimer({
    	endTime = 3, -- BuildTime
    	callback = function()
		local hero = caster:GetOwner()
		if not hero then
			return
		end
		local goldamountperfivesecond = GetUnitKV(caster:GetUnitName()).GoldAmount
		local lumberamountperfivesecond = GetUnitKV(caster:GetUnitName()).LumberAmount
		hero.goldperfivesecond = hero.goldperfivesecond + goldamountperfivesecond
		hero.lumberperfivesecond = hero.lumberperfivesecond + lumberamountperfivesecond
    end
  	})
end

function ProduceLumberandGoldDestroy(event)
	local caster = event.caster
	local hero = caster:GetOwner()
	local goldamountperfivesecond = GetUnitKV(caster:GetUnitName()).GoldAmount
	local lumberamountperfivesecond = GetUnitKV(caster:GetUnitName()).LumberAmount
	hero.goldperfivesecond = hero.goldperfivesecond - goldamountperfivesecond
	hero.lumberperfivesecond = hero.lumberperfivesecond - lumberamountperfivesecond
end
--SENTRY TOWER
air_dummies = {}
function RevealAreaSentryTower(event)
	local caster = event.caster
	Timers:CreateTimer({
		endTime = 3,
		callback = function()
		local hero = caster:GetOwner()
		if not hero then
			return
		end
		local point = caster:GetAbsOrigin()
		local team_caster = caster:GetTeam()
		local air_dummy = CreateUnitByName("npc_dota_air_dummy", point, false, nil, nil, team_caster)
		air_dummy:AddNewModifier(air_dummy,nil,"modifier_tree_cut",{})
    	air_dummy:AddNewModifier(air_dummy,nil,"modifier_building",{})
		air_dummy:AddNewModifier(air_dummy,nil,"modifier_truesight",{})
		air_dummies[air_dummy:GetEntityIndex()] = air_dummy
	end
	})

	-- local units = FindUnitsInRadius(caster:GetTeamNumber(), point , nil, visionRadius , DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL , DOTA_UNIT_TARGET_FLAG_NONE, 0 , false)
	-- local timeElapsed = 0
	-- Timers:CreateTimer(0.03,function()
	-- 	for _,unit in pairs(units) do
	-- 		if unit:HasModifier("modifier_invisible") then
	-- 			unit:RemoveModifierByName("modifier_invisible")
	-- 		end
	-- 	end
	-- 	timeElapsed = timeElapsed + 0.03
	-- 	if timeElapsed < visionDuration then
	-- 		return 0.03
	-- 	end
	-- end)
end

function DestroyAreaSentryTower(event)
	local caster = event.caster
    local team = caster:GetTeam()
    local point = caster:GetAbsOrigin()
    local air_dummy
    local x = point.x
    local y = point.y
	--local units = FindUnitsInRadius(team, target_point, nil, 335, DOTA_UNIT_TARGET_TEAM_BOTH ,  DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, 0, false)
	for _, dummy in pairs(air_dummies) do
		local pos = dummy:GetAbsOrigin()
		if pos.x == x and pos.y == y then
			air_dummy = dummy
			break
		end
	end

	if air_dummy then
		air_dummies[air_dummy:GetEntityIndex()] = nil
		UTIL_Remove(air_dummy)
	end

end

--TREE AURA 
function HealthRegenTree(event)
	local caster = event.caster
	local team = caster:GetTeam()
	local radius = event.Radius
end

function ManaRegenTree(event)
	local caster = event.caster
	local team = caster:GetTeam()
	local radius = event.Radius
end


function WispGainLumber()
	--body
end

function SpawnUnit(event)

end

--=========================================idk
function SpawnUnitOnSpellStart(event)
	local caster = event.caster
	local playerID = caster:GetMainControllingPlayer()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local ability = event.ability
	local unit_name = GetAbilityKV(ability:GetAbilityName()).UnitName
	local gold_cost = ability:GetSpecialValueFor("gold_cost")
	local lumber_cost = ability:GetSpecialValueFor("lumber_cost")
	local food = ability:GetSpecialValueFor("food_cost")
	PlayerResource:ModifyGold(hero,-gold_cost)
	PlayerResource:ModifyLumber(hero,-lumber_cost)
	PlayerResource:ModifyFood(hero,food)
    if PlayerResource:GetGold(playerID) < 0 then
        SendErrorMessage(playerID, "#error_not_enough_gold")
        caster:AddNewModifier(nil, nil, "modifier_stunned", {duration=0.03})
        return false
    end
    if PlayerResource:GetLumber(playerID) < 0 then
        SendErrorMessage(playerID, "#error_not_enough_lumber")
        caster:AddNewModifier(nil, nil, "modifier_stunned", {duration=0.03})
        return false
    end
    if hero.food > GameRules.maxFood then
        SendErrorMessage(playerID, "#error_not_enough_food")
        caster:AddNewModifier(nil, nil, "modifier_stunned", {duration=0.03})
        return false
    end
end

function SpawnUnitOnChannelSucceeded(event)
	local caster = event.caster
	local ability = event.ability
	local playerID = caster:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local unit_name = GetAbilityKV(ability:GetAbilityName()).UnitName
	local unit_count = ability:GetSpecialValueFor("unit_count")
	for a = 1,unit_count do
		local unit = CreateUnitByName(unit_name, caster:GetAbsOrigin() , true, nil, nil, hero:GetTeamNumber())
		unit:AddNewModifier(unit,nil,"modifier_phased",{duration = 0.03})
        unit:SetOwner(hero)
        table.insert(hero.units,unit)
        unit:SetControllableByPlayer(playerID, true)
	end
end

function SpawnUnitOnChannelInterrupted(event)
	local caster = event.caster
	local playerID = caster:GetPlayerOwnerID()
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local ability = event.ability
	local unit_name = GetAbilityKV(ability:GetAbilityName()).UnitName
	local gold_cost = ability:GetSpecialValueFor("gold_cost")
	local lumber_cost = ability:GetSpecialValueFor("lumber_cost")
	local food = ability:GetSpecialValueFor("food_cost")
	PlayerResource:ModifyGold(hero,gold_cost)
	PlayerResource:ModifyLumber(hero,lumber_cost)
	PlayerResource:ModifyFood(hero,-food)

end

function RevealArea(event)
	local caster = event.caster
	local point = event.target_points[1]
	local visionRadius = string.match(GetMapName(),"treetag_evolution_reborn_103_made_by_pramadito") and event.Radius*1.25 or event.Radius
	local visionDuration = event.Duration
	AddFOWViewer(caster:GetTeamNumber(), point, visionRadius, visionDuration, false)
	local units = FindUnitsInRadius(caster:GetTeamNumber(), point , nil, visionRadius , DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL , DOTA_UNIT_TARGET_FLAG_NONE, 0 , false)
	local timeElapsed = 0
	Timers:CreateTimer(0.03,function()
		for _,unit in pairs(units) do
			if unit:HasModifier("modifier_invisible") then
				unit:RemoveModifierByName("modifier_invisible")
			end
		end
		timeElapsed = timeElapsed + 0.03
		if timeElapsed < visionDuration then
			return 0.03
		end
	end)
end

function SendErrorMessage( pID, string )
    Notifications:ClearBottom(pID)
    Notifications:Bottom(pID, {text=string, style={color='#E62020'}, duration=2})
    EmitSoundOnClient("General.Cancel", PlayerResource:GetPlayer(pID))
end


function Infernal_Shockwave()
	--body
	--use invoker meteor from infernal's hand(animating??) or magnus shockwave
end

function Infernal_Ward()
	--body
end

function Infernal_PowerWard()
	--body
end

function Infernal_Immolation()
	--body
end

function DestroyTree_WhileWalking(event)
	-- body
end



