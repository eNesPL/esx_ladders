ESX = exports["es_extended"]:getSharedObject()

local Ladders = {}
local usingLadder = false

ESX.RegisterUsableItem('ladder', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	if usingLadder == false then
		xPlayer.removeInventoryItem('ladder', 1)
		TriggerClientEvent('Ladders:Client:Local:Add', -1, source)
		usingLadder = true
	else
		TriggerClientEvent('okokNotify:Alert', source, 'Błąd', Strings[Lang]['already_carrying'], 3000, 'error', true)
	end
end)

RegisterServerEvent('Ladders:Server:GiveItem')
AddEventHandler('Ladders:Server:GiveItem', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addInventoryItem('ladder', 1)
	TriggerClientEvent('okokNotify:Alert', source, 'Sukces', Strings[Lang]['put_inv_ladder'], 4000, 'success', true)
end)

RegisterServerEvent('Ladders:Server:Ladders')
AddEventHandler('Ladders:Server:Ladders', function(Action, LadderNetID, Key, Value)
    if Action == 'store' and not Ladders[LadderNetID] then
        Ladders[LadderNetID] = {}
        Ladders[LadderNetID].ID = LadderNetID
    elseif Ladders[LadderNetID] then
        if Action == 'update' then
            Ladders[LadderNetID][Key] = Value
        elseif Action == 'pickup' then
            if not Ladders[LadderNetID].BeingCarried and not Ladders[LadderNetID].BeingClimbed then
                TriggerClientEvent('Ladders:Client:Pickup', source, LadderNetID)
            end
        elseif Action == 'climb' then
            if Ladders[LadderNetID].Placed and not Ladders[LadderNetID].BeingClimbed then
                TriggerClientEvent('Ladders:Client:Climb', source, LadderNetID, Key)
            end
        elseif Action == 'delete' then
            Ladders[LadderNetID] = nil
        end
    end
    TriggerClientEvent('Ladders:Bounce:ServerValues', -1, Ladders)
end)

RegisterServerEvent('Ladders:Server:Ladders:Local')
AddEventHandler('Ladders:Server:Ladders:Local', function(Action)
    if Action == "add" then
        TriggerClientEvent('Ladders:Client:Local:Add', -1, source)
		usingLadder = true
    else
        TriggerClientEvent('Ladders:Client:Local:Remove', -1, source)
		usingLadder = false
    end
end)

RegisterServerEvent('Ladders:Server:PersonalRequest')
AddEventHandler('Ladders:Server:PersonalRequest', function()
    TriggerClientEvent('Ladders:Bounce:ServerValues', -1, Ladders)
end)
