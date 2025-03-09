local PlayerData = {}

ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer   
end)

-- Zsynchronizowana tabela drabin pomiędzy klientem a serwerem
local Ladders = {}
-- Lokalnie tworzone drabiny (przenoszone przez graczy)
local LocalLadders = {}

local Climbing = false
local Carrying = false
local ClimbingLadder = false
local Preview = false
local PreviewToggle = true
local Clipset = false

-- Wektorowe animacje wspinania
local ClimbingVectors = {
    up = {
        {vector3(0.0, -0.45, -1.5), 'laddersbase', 'get_on_bottom_front_stand_high'},
        {vector3(0.0, -0.3, -1.1), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.3, -0.7), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.3, -0.3), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.3, 0.1), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.3, 0.5), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.3, 0.9), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.3, 1.3), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.3, 1.7), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.3, 2.1), 'laddersbase', 'climb_up'},
        {vector3(0.0, -0.4, 2.5), 'laddersbase', 'get_off_top_back_stand_left_hand'}
    },

    down = {
        {vector3(0.0, -0.4, 2.5), 'laddersbase', 'get_on_top_front'},
        {vector3(0.0, -0.3, 2.1), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.3, 1.7), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.3, 1.3), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.3, 0.9), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.3, 0.5), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.3, 0.1), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.3, -0.3), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.3, -0.7), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.3, -1.1), 'laddersbase', 'climb_down'},
        {vector3(0.0, -0.45, -1.5), 'laddersbase', 'get_off_bottom_front_stand'}
    }
}

-- Tworzenie drabin po stronie klienta
RegisterNetEvent('Ladders:Client:Local:Add')
AddEventHandler('Ladders:Client:Local:Add', function(SourceId)
    local SourcePlayer = GetPlayerFromServerId(SourceId)
    local SourcePed = GetPlayerPed(SourcePlayer)

    if (SourcePed ~= -1 and not LocalLadders[SourcePed]) then
        local LadderCoords = GetOffsetFromEntityInWorldCoords(SourcePed, 0.0, 1.2, 1.32)
        local Ladder = CreateObjectNoOffset(GetHashKey('prop_byard_ladder01'), LadderCoords, false, false, false)

        SetEntityAsMissionEntity(Ladder)
        SetEntityCollision(Ladder, false, true)
        LocalLadders[SourcePed] = Ladder

        if GetPlayerServerId(PlayerId()) == SourceId then 
            Carrying = Ladder 
        end
    end
end)

-- Usuwanie lokalnej drabiny
RegisterNetEvent('Ladders:Client:Local:Remove')
AddEventHandler('Ladders:Client:Local:Remove', function(SourceId)
    local SourcePlayer = GetPlayerFromServerId(SourceId)
    local SourcePed = GetPlayerPed(SourcePlayer)

    if (SourcePed ~= -1 and LocalLadders[SourcePed]) then
        DeleteObject(LocalLadders[SourcePed])
        SetEntityAsNoLongerNeeded(LocalLadders[SourcePed])
        ClearPedTasksImmediately(PlayerPed)
        LocalLadders[SourcePed] = nil

        if GetPlayerServerId(PlayerId()) == SourceId then 
            Carrying = nil 
        end
    end
end)

-- Odbiór zsynchronizowanych wartości drabin z serwera
RegisterNetEvent('Ladders:Bounce:ServerValues')
AddEventHandler('Ladders:Bounce:ServerValues', function(NewLadders) 
    Ladders = NewLadders 
end)

RegisterNetEvent('Ladders:Client:DropLadder')
AddEventHandler('Ladders:Client:DropLadder', function()
    if Carrying then
        local PlayerPed = PlayerPedId()
        local Ladder = CreateObjectNoOffset(GetHashKey('prop_byard_ladder01'), GetOffsetFromEntityInWorldCoords(PlayerPed, 0.0, 0.0, -500.0), true, false, false)
        local LadderNetID = ObjToNet(Ladder)

        SetEntityAsMissionEntity(LadderNetID)
        ClearPedTasksImmediately(PlayerPed)
        SetEntityRotation(Ladder, 0.0, 90.0, 90.0)
        SetEntityCoords(Ladder, GetOffsetFromEntityInWorldCoords(PlayerPed, 0.5, 0.0, 0.0))
        ApplyForceToEntity(Ladder, 4, 0.001, 0.001, 0.001, 0.0, 0.0, 0.0, 0, false, true, true, false, true)

        TriggerServerEvent('Ladders:Server:Ladders:Local', 'remove')
        TriggerServerEvent('Ladders:Server:Ladders', 'store', LadderNetID)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'BeingCarried', true)

        Citizen.Wait(1000)

        local LadderCoords = GetEntityCoords(Ladder)

        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'BeingCarried', false)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'BeingClimbed', false)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'Dropped', true)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'Placed', false)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'x', LadderCoords.x)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'y', LadderCoords.y)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'z', LadderCoords.z)
    end
end)

RegisterNetEvent('Ladders:Client:Pickup')
AddEventHandler('Ladders:Client:Pickup', function(LadderNetID)
    if not Carrying and NetworkDoesNetworkIdExist(LadderNetID) then
        NetworkRequestControlOfNetworkId(LadderNetID)
        while not NetworkHasControlOfNetworkId(LadderNetID) do 
            Citizen.Wait(0) 
        end

        local Ladder = NetToObj(LadderNetID)

        DeleteObject(Ladder)
        SetEntityAsNoLongerNeeded(Ladder)

        TriggerServerEvent('Ladders:Server:Ladders:Local', 'add')
        TriggerServerEvent('Ladders:Server:Ladders', 'delete', LadderNetID)

        ClearPedTasksImmediately(PlayerPedId())
    end
end)

RegisterNetEvent('Ladders:Client:PlaceLadder')
AddEventHandler('Ladders:Client:PlaceLadder', function()
    if Carrying then
        local PlayerPed = PlayerPedId()
        local PlayerRot = GetEntityRotation(PlayerPed)
        local Ladder = CreateObjectNoOffset(GetHashKey('prop_byard_ladder01'), GetOffsetFromEntityInWorldCoords(PlayerPed, 0.0, 1.0, 0.0), true, false, false)
        local LadderNetID = ObjToNet(Ladder)
        local LadderCoords = GetOffsetFromEntityInWorldCoords(PlayerPed, 0.0, 1.2, 1.32)

        SetEntityAsMissionEntity(LadderNetID)

        TriggerServerEvent('Ladders:Server:Ladders:Local', 'remove')
        TriggerServerEvent('Ladders:Server:Ladders', 'store', LadderNetID)

        SetEntityCoords(Ladder, LadderCoords)
        SetEntityRotation(Ladder, vector3(PlayerRot.x - 20.0, PlayerRot.y, PlayerRot.z))
        FreezeEntityPosition(Ladder, true)

        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'BeingCarried', false)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'BeingClimbed', false)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'Dropped', false)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'Placed', true)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'x', LadderCoords.x)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'y', LadderCoords.y)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'z', LadderCoords.z)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'Topz', LadderCoords.z + 5.0)
        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'Bottomz', LadderCoords.z - 5.0)
    end
end)

RegisterNetEvent('Ladders:Client:Climb')
AddEventHandler('Ladders:Client:Climb', function(LadderNetID, Direction)
    if not Carrying then
        local PlayerPed = PlayerPedId()
        local Ladder = NetToObj(LadderNetID)

        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'BeingClimbed', true)

        Climbing = true
        ClimbingLadder = GetEntityRotation(Ladder)

        if not HasAnimDictLoaded('laddersbase') then
            RequestAnimDict('laddersbase')
            while not HasAnimDictLoaded('laddersbase') do 
                Citizen.Wait(0) 
            end
        end

        ClearPedTasksImmediately(PlayerPed)
        FreezeEntityPosition(PlayerPed, true)
        SetEntityCollision(Ladder, false, true)

        Climbing = 'rot'

        for dirKey, Pack in pairs(ClimbingVectors) do
            if Direction == dirKey then
                for _, Element in pairs(Pack) do
                    SetEntityCoordsNoOffset(PlayerPed, GetOffsetFromEntityInWorldCoords(Ladder, Element[1]), false, false, false)
                    TaskPlayAnim(PlayerPed, Element[2], Element[3], 2.0, 0.0, -1, 15, 0, false, false, false)
                    Citizen.Wait(850)
                end
            end
        end

        if Direction == 'up' then
            SetEntityCoordsNoOffset(PlayerPed, GetOffsetFromEntityInWorldCoords(Ladder, 0.0, 0.5, 4.0), false, false, false)
        elseif Direction == 'down' then
            SetEntityCoordsNoOffset(PlayerPed, GetOffsetFromEntityInWorldCoords(Ladder, 0.0, -0.9, -1.4), false, false, false)
        end

        ClearPedTasksImmediately(PlayerPed)
        FreezeEntityPosition(PlayerPed, false)
        SetEntityCollision(Ladder, true, true)

        Climbing = false

        TriggerServerEvent('Ladders:Server:Ladders', 'update', LadderNetID, 'BeingClimbed', false)
    end
end)

-- Funkcja zwracająca dystans między graczem a podanymi współrzędnymi
function GetDistanceBetween(Coords)
    return Vdist(GetEntityCoords(PlayerPedId(), false), Coords.x, Coords.y, Coords.z) + 0.01
end

-- Rejestracja interakcji dla obiektów o modelu prop_byard_ladder01 przy użyciu ox_target
Citizen.CreateThread(function()
    exports.ox_target:addModel({`prop_byard_ladder01`}, {
        options = {
            {
                name = 'ladder_climb',
                icon = 'fas fa-user',
                label = 'Wspiąć się na drabinę',
                canInteract = function(entity)
                    local netId = ObjToNet(entity)
                    for _, ladder in pairs(Ladders) do
                        if ladder.ID == netId then
                            return ladder.Placed and not ladder.BeingCarried and not Climbing
                        end
                    end
                    return false
                end,
                onSelect = function(entity)
                    local netId = ObjToNet(entity)
                    for _, ladder in pairs(Ladders) do
                        if ladder.ID == netId then
                            local coords = GetEntityCoords(entity)
                            local topCoords = vector3(ladder.x, ladder.y, ladder.Topz)
                            local bottomCoords = vector3(ladder.x, ladder.y, ladder.Bottomz)
                            local topDist = Vdist(coords.x, coords.y, coords.z, topCoords.x, topCoords.y, topCoords.z)
                            local bottomDist = Vdist(coords.x, coords.y, coords.z, bottomCoords.x, bottomCoords.y, bottomCoords.z)
                            if topDist > bottomDist then
                                TriggerServerEvent('Ladders:Server:Ladders', 'climb', ladder.ID, 'up')
                            else
                                TriggerServerEvent('Ladders:Server:Ladders', 'climb', ladder.ID, 'down')
                            end
                            break
                        end
                    end
                end,
            },
            {
                name = 'ladder_pickup',
                icon = 'fas fa-hand-paper',
                label = 'Podnieś drabinę',
                canInteract = function(entity)
                    local netId = ObjToNet(entity)
                    for _, ladder in pairs(Ladders) do
                        if ladder.ID == netId then
                            return ladder.Dropped or ladder.Placed
                        end
                    end
                    return false
                end,
                onSelect = function(entity)
                    local netId = ObjToNet(entity)
                    TriggerServerEvent('Ladders:Server:Ladders', 'pickup', netId)
                end,
            },
        },
        distance = 2.5,
    })
end)

-- Pętla główna zasobu – obsługa trybu przenoszenia drabiny oraz podglądu
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local PlayerPed = PlayerPedId()

        if Carrying then
            if IsPedRunning(PlayerPed) or IsPedSprinting(PlayerPed) then
                if not Clipset then
                    Clipset = true
                    if not HasAnimSetLoaded('MOVE_M@BAIL_BOND_TAZERED') then
                        RequestAnimSet('MOVE_M@BAIL_BOND_TAZERED')
                        while not HasAnimSetLoaded('MOVE_M@BAIL_BOND_TAZERED') do
                            Citizen.Wait(0)
                        end
                    end
                    SetPedMovementClipset(PlayerPed, 'MOVE_M@BAIL_BOND_TAZERED', 1.0)
                end
            elseif Clipset then
                Clipset = false
                ResetPedMovementClipset(PlayerPed, 1.0)
            end

            -- Obsługa przycisków podczas przenoszenia drabiny
            if IsControlJustPressed(0, 38) then
                TriggerEvent('Ladders:Client:PlaceLadder')
            elseif IsControlJustPressed(0, 23) then
                TriggerEvent('Ladders:Client:DropLadder')
            elseif IsControlJustPressed(0, 246) then
                if PreviewToggle then
                    PreviewToggle = false
                    PlaySoundFrontend(-1, 'NO', 'HUD_FRONTEND_DEFAULT_SOUNDSET', 1)
                else
                    PreviewToggle = true
                    PlaySoundFrontend(-1, 'YES', 'HUD_FRONTEND_DEFAULT_SOUNDSET', 1)
                end
            elseif IsControlJustPressed(0, 47) then
                TriggerServerEvent('Ladders:Server:Ladders:Local', 'remove')
                TriggerServerEvent('Ladders:Server:Ladders', 'update', ObjToNet(Carrying), 'BeingCarried', false)
                TriggerServerEvent('Ladders:Server:Ladders', 'update', ObjToNet(Carrying), 'BeingClimbed', false)
                TriggerServerEvent('Ladders:Server:Ladders', 'update', ObjToNet(Carrying), 'Dropped', false)
                TriggerServerEvent('Ladders:Server:Ladders', 'update', ObjToNet(Carrying), 'Placed', false)
                TriggerServerEvent('Ladders:Server:GiveItem')
            end

            -- Podgląd (preview) drabiny podczas przenoszenia
            if not Preview and PreviewToggle then
                local LadderCoords = GetOffsetFromEntityInWorldCoords(PlayerPed, 0.0, 1.2, 1.32)
                Preview = CreateObjectNoOffset(GetHashKey('prop_byard_ladder01'), LadderCoords, false, false, false)
                SetEntityCollision(Preview, false, false)
                SetEntityAlpha(Preview, 100)
            end

            if Preview and PreviewToggle then
                local LadderCoords = GetOffsetFromEntityInWorldCoords(PlayerPed, 0.0, 1.2, 1.32)
                local LadderRot = GetEntityRotation(PlayerPed)
                SetEntityCoords(Preview, LadderCoords, 1, 0, 0, 1)
                SetEntityRotation(Preview, vector3(LadderRot.x - 20.0, LadderRot.y, LadderRot.z), 2, true)
            end

            if Preview and not PreviewToggle then
                ResetEntityAlpha(Preview)
                DeleteObject(Preview)
                SetEntityAsNoLongerNeeded(Preview)
                Preview = false
            end

        else
            -- Jeśli gracz nie przenosi drabiny, usuwamy podgląd
            if Preview then
                ResetEntityAlpha(Preview)
                DeleteObject(Preview)
                SetEntityAsNoLongerNeeded(Preview)
                Preview = false
            end
        end

        -- Obsługa synchronizowanych drabin przenoszonych przez innych graczy
        for SourcePed, Ladder in pairs(LocalLadders) do
            if (SourcePed ~= -1) then
                local Bone1 = GetEntityBoneIndexByName(SourcePed, 'BONETAG_NECK')
                local Bone2 = GetEntityBoneIndexByName(SourcePed, 'BONETAG_R_HAND')
                local LadderRot = GetWorldRotationOfEntityBone(SourcePed, Bone1)
                AttachEntityToEntity(Ladder, SourcePed, Bone2, 0.0, 0.0, 0.0, LadderRot.x + 20.0, LadderRot.y + 180.0, LadderRot.z + 90.0, false, false, false, true, 0, false)
            end
        end

        if Climbing then
            if Climbing == 'rot' and ClimbingLadder then 
                SetEntityRotation(PlayerPed, vector3(ClimbingLadder.x, ClimbingLadder.y, ClimbingLadder.z), 2, true)
            end

            DisableControlAction(0, 21, true) -- Sprint
            DisableControlAction(0, 22, true) -- Skok
            DisableControlAction(0, 23, true) -- Wsiadanie do pojazdu
            DisableControlAction(0, 24, true) -- Atak (LPM)
            DisableControlAction(0, 25, true) -- Celowanie
            DisableControlAction(0, 30, true) -- Ruch w prawo
            DisableControlAction(0, 31, true) -- Ruch do tyłu
            DisableControlAction(0, 32, true) -- Ruch do przodu
            DisableControlAction(0, 33, true) -- Ruch do tyłu
            DisableControlAction(0, 34, true) -- Ruch w lewo
            DisableControlAction(0, 35, true) -- Ruch w prawo
            DisableControlAction(0, 44, true) -- Przykrycie
            DisableControlAction(0, 140, true) -- Atak (R)
            DisableControlAction(0, 141, true) -- Atak (Q)
            DisableControlAction(0, 142, true) -- Atak (LPM)
            DisableControlAction(0, 257, true) -- Atak (LPM)
            DisableControlAction(0, 263, true) -- Atak (R)
            DisableControlAction(0, 264, true) -- Atak (Q)
            DisableControlAction(0, 266, true) -- Ruch w lewo
            DisableControlAction(0, 267, true) -- Ruch w prawo
            DisableControlAction(0, 268, true) -- Ruch w górę
            DisableControlAction(0, 269, true) -- Ruch w dół
        end

    end
end)

AddEventHandler('onClientMapStart', function()
    TriggerServerEvent('Ladders:Server:PersonalRequest')
end)
