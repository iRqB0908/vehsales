-- ModFreakz
-- For support, previews and showcases, head to https://discord.gg/ukgQa5K

-- Only edit this.
local sellAnywhere = true
local useBlip = true
local salesYard = vector3(178.38,-1150.32,29.30)
local salesRadius = 20.0
-- Stop editing here... unless you know what you're doing.

NewEvent = function(net,func,name,...)
  if net then RegisterNetEvent(name); end
  AddEventHandler(name, function(...) func(source,...); end)
end

local TSC = ESX.TriggerServerCallback
local TSE = TriggerServerEvent
local isConfirming = false
local forSale = {}

function GetVecDist(v1,v2)
  if not v1 or not v2 or not v1.x or not v2.x then return 0; end
  return math.sqrt(  ( (v1.x or 0) - (v2.x or 0) )*(  (v1.x or 0) - (v2.x or 0) )+( (v1.y or 0) - (v2.y or 0) )*( (v1.y or 0) - (v2.y or 0) )+( (v1.z or 0) - (v2.z or 0) )*( (v1.z or 0) - (v2.z or 0) )  )
end

function DrawText3D(x,y,z, text, scaleB)
  if not scaleB then scaleB = 1; end
  local onScreen,_x,_y = World3dToScreen2d(x,y,z)
  local px,py,pz = table.unpack(GetGameplayCamCoord())
  local dist = GetDistanceBetweenCoords(px,py,pz, x,y,z, 1)
  local scale = (((1/dist)*2)*(1/GetGameplayCamFov())*100)*scaleB

  if onScreen then
    -- Formalize the text
    SetTextColour(220, 220, 220, 255)
    SetTextScale(0.0*scale, 0.40*scale)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextCentre(true)

    -- Diplay the text
    SetTextEntry("STRING")
    AddTextComponentString(text)
    EndTextCommandDisplayText(_x, _y)
  end
end

Citizen.CreateThread(function(...)
  while not ESX do
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj; end)
    Citizen.Wait(0)
  end
  TSC('MF_VehSales:GetStartData', function(retVal,retTab) dS = true; cS = retVal; forSale = retTab; end)
  while not cS or not dS or not forSale do Citizen.Wait(0); end
  while not ESX.IsPlayerLoaded() do Citizen.Wait(0); end
  playerData = ESX.GetPlayerData()
  local lastPlate = 'SUKDIK'
  local drawText = 'YUTU'
  local lastTimer = GetGameTimer()
  if not sellAnywhere and useBlip then
    local blip = AddBlipForCoord(salesYard.x, salesYard.y, salesYard.z)
    SetBlipSprite               (blip, 225)
    SetBlipDisplay              (blip, 3)
    SetBlipScale                (blip, 1.0)
    SetBlipColour               (blip, 71)
    SetBlipAsShortRange         (blip, false)
    SetBlipHighDetail           (blip, true)
    BeginTextCommandSetBlipName ("STRING")
    AddTextComponentString      ("Second Hand Cars")
    EndTextCommandSetBlipName   (blip)
  end
  while true do
    Citizen.Wait(0)
    local closest,closestDist
    local plyPos = GetEntityCoords(GetPlayerPed(-1))
    for k,v in pairs(forSale) do
      local dist = GetVecDist(plyPos,v.loc)
      if not closestDist or dist < closestDist then
        closestDist = dist
        closest = v
      end
    end
    if closestDist and closestDist < 10 then
      if not lastPlate or closest.vehProps.plate ~= lastPlate then
        isConfirming = false
        if closest.owner ~= playerData.identifier then
          drawText = "[~r~"..GetDisplayNameFromVehicleModel(closest.vehProps.model).."~s~] Press [~r~E~s~] to purchase [$~r~"..closest.price.."~s~]"
        else
          drawText = "[~r~"..GetDisplayNameFromVehicleModel(closest.vehProps.model).."~s~] Press [~r~E~s~] to reclaim your vehicle [$~r~"..closest.price.."~s~]"
        end
        local turbs = 'No'
        if closest.vehProps.modTurbo and closest.vehProps.modTurbo > 0 then turbs = 'Yes'; end
        drawTextB = "[Turbo : ~r~"..turbs.."~s~] [Engine : ~r~"..tostring(closest.vehProps.modEngine).."~s~] [Gearbox : ~r~"..tostring(closest.vehProps.modTransmission).."~s~]"
        drawTextC = "[Suspension : ~r~"..tostring(closest.vehProps.modSuspension).."~s~] [Armor : ~r~"..tostring(closest.vehProps.modArmor).."~s~] [Brakes : ~r~"..tostring(closest.vehProps.modBrakes).."~s~]"
        lastPlate = closest.vehProps.plate
      end
      DrawText3D(closest.loc.x,closest.loc.y,closest.loc.z + 1.0, drawText)
      DrawText3D(closest.loc.x,closest.loc.y,closest.loc.z + 0.9, drawTextB)
      DrawText3D(closest.loc.x,closest.loc.y,closest.loc.z + 0.8, drawTextC)
      if IsControlJustPressed(0,38) and closestDist < 5.0 and GetGameTimer() - lastTimer > 150 then
        lastTimer = GetGameTimer()
        if not isConfirming then
          if closest.owner ~= playerData.identifier then
            drawText = "[~r~"..GetDisplayNameFromVehicleModel(closest.vehProps.model).."~s~] Press [~r~E~s~] again to confirm this purchase [$~r~"..closest.price.."~s~]"
          else
            lastPlate = false
            BuyVehicle(closest)
          end
          isConfirming = true
        else
          lastPlate = false
          isConfirming = false
          BuyVehicle(closest)
        end
      end
    else
      lastPlate = false
      isConfirming = false
    end
  end
end)

function AddCar(source,vehId,loc,price,props,id)
  local veh = NetworkGetEntityFromNetworkId(vehId)
  SetEntityAsMissionEntity(veh,true,true)
  SetVehicleDoorsLocked(veh,2)
  SetVehicleDoorsLockedForAllPlayers(veh,true)
  SetEntityInvincible(veh,true)

  table.insert(forSale,{veh = vehId, loc = loc, price = price, vehProps = props, owner = id})
end

function BuyVehicle(closest)
  TSC('MF_VehSales:TryBuy', function(can,msg)
    if can then
      ESX.ShowNotification(msg)
      TSE('MF_VehSales:BuyVeh',closest)
    else
      ESX.ShowNotification(msg)
    end
  end,closest)
end

function SellCar(price)
  if not price or not price[1] then ESX.ShowNotification("You need to enter a price."); return; end
  if type(price) == "table" then price = tonumber(price[1]); end
  if not price or type(price) ~= "number" or price <= 0 then ESX.ShowNotification("Stop fucking around."); return; end
  if not IsPedInAnyVehicle(GetPlayerPed(-1),false) then ESX.ShowNotification("You must be in a vehicle."); return; end
  if not sellAnywhere and GetVecDist(GetEntityCoords(GetPlayerPed(-1)),salesYard) > salesRadius then ESX.ShowNotification("You must be at the sales yard to do that."); return; end
  local veh = GetVehiclePedIsIn(GetPlayerPed(-1),false)
  local vehProps = ESX.Game.GetVehicleProperties(veh)
  TSC('MF_VehSales:TrySell', function(canSell,msg)
    if not canSell then
      ESX.ShowNotification(msg)
    else
      TaskLeaveVehicle(GetPlayerPed(-1),veh,0)
      TaskEveryoneLeaveVehicle(veh)
      local vehId = NetworkGetNetworkIdFromEntity(veh)
      TSE('MF_VehSales:AddSale',vehId,GetEntityCoords(veh),price,vehProps)
    end
  end, vehProps)
end

function RemoveVeh(source,veh)
  local vehi = veh
  print(veh.veh)
  print(vehi.veh)
  local veh = NetworkGetEntityFromNetworkId(veh.veh)
  SetEntityAsMissionEntity(veh,true,true)
  SetVehicleDoorsLocked(veh,0)
  SetVehicleDoorsLockedForAllPlayers(veh,false)
  SetEntityInvincible(veh,false)

  for k,v in pairs(forSale) do
    if v.vehProps.plate == vehi.vehProps.plate then forSale[k] = nil; end
  end
end

RegisterCommand('sellCar', function(source,args) SellCar(args); end)
NewEvent(true,AddCar,'MF_VehSales:AddToSale')
NewEvent(true,RemoveVeh,'MF_VehSales:RemoveFromSale')
