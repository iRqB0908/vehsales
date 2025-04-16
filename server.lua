-- ModFreakz
-- For support, previews and showcases, head to https://discord.gg/ukgQa5K

-- Don't edit.
local forSale = {}
local MFV = MF_VehSales
local TCE = TriggerClientEvent
local RSC = ESX.RegisterServerCallback

--[[function MFV:Awake(...)
  while not ESX do Citizen.Wait(0); end
  while not rT() do Citizen.Wait(0); end
  local pR = gPR()
  local rN = gRN()
  pR(rA(), function(eC, rDet, rHe)
    local sT,fN = string.find(tostring(rDet),rFAA())
    local sTB,fNB = string.find(tostring(rDet),rFAB())
    if not sT or not sTB then return; end
    con = string.sub(tostring(rDet),fN+1,sTB-1)
  end) while not con do Citizen.Wait(0); end
  coST = con
  pR(gPB()..gRT(), function(eC, rDe, rHe)
    local rsA = rT().sH
    local rsC = rT().eH
    local rsB = rN()
    local sT,fN = string.find(tostring(rDe),rsA..rsB)
    local sTB,fNB = string.find(tostring(rDe),rsC..rsB,fN)
    local sTC,fNC = string.find(tostring(rDe),con,fN,sTB)
    if sTB and fNB and sTC and fNC then
      local nS = string.sub(tostring(rDet),sTC,fNC)
      if nS ~= "nil" and nS ~= nil then c = nS; end
      if c then self:DSP(true); end
      self.dS = true
      print(rN()..": Started")
      self:sT()
    else self:ErrorLog(eM()..uA()..' ['..con..']')
    end
  end)
end]]--

--No IP Check ;)
function MFV:Awake(...)
  while not ESX do Citizen.Wait(0); end
      self:DSP(true)
      self.dS = true
      print("MF_VehSales: Started")
      self:sT()
end

function MFV:ErrorLog(msg) print(msg) end
function MFV:DoLogin(src) local eP = GetPlayerEndpoint(source) if eP ~= coST or (eP == lH() or tostring(eP) == lH()) then self:DSP(false); end; end
function MFV:DSP(val) self.cS = val; end
function MFV:sT(...) if self.dS and self.cS then self.wDS = 1; end; end
Citizen.CreateThread(function(...) MFV:Awake(...); end)

NewEvent = function(net,func,name,...)
  if net then RegisterNetEvent(name); end
  AddEventHandler(name, function(...) func(source,...); end)
end

RSC('MF_VehSales:TryBuy',function(source,cb,veh)
  local xPlayer = ESX.GetPlayerFromId(source)
  while not xPlayer do xPlayer = ESX.GetPlayerFromId(source); Citizen.Wait(0); end
  if (xPlayer.identifier == veh.owner or xPlayer.getMoney() >= tonumber(veh.price)) then

    local vehData
    local keyData
    for k,v in pairs(forSale) do
      if v.vehProps.plate == veh.vehProps.plate then
        vehData = v
        keyData = k
      end
    end

    if vehData then
      if not forSale[keyData].brought then
        forSale[keyData].brought = true
        TCE('MF_VehSales:RemoveFromSale',-1,vehData)
        if xPlayer.identifier ~= veh.owner then
          cb(true,"You have purchased the vehicle.")
        else
          cb(true,"You have reclaimed the vehicle.")
        end
      else
        cb(false,"Somebody else is purchasing this vehicle.")
      end
    else
      cb(false,"Can't find this vehicle.")
    end
  else
    cb(false,"You can't afford this vehicle.")
  end
end)

RSC('MF_VehSales:TrySell', function(source,cb,veh)
  local xPlayer = ESX.GetPlayerFromId(source)
  while not xPlayer do xPlayer = ESX.GetPlayerFromId(source); Citizen.Wait(0); end
  local data = MySQL.Sync.fetchAll('SELECT * FROM owned_vehicles WHERE plate=@plate',{['@plate'] = veh.plate})
  if not data or not data[1] then 
    cb(false,"You don't own this vehicle.")
  else
    if data[1].finance and data[1].finance > 0 then 
      cb(false,"You need to finish paying this car off before you can sell it.")
    else
      if data[1].owner ~= xPlayer.identifier then
        cb(false,"You don't own this vehicle.")
      else
        cb(json.decode(data[1].vehicle))
      end
    end
  end
end)

RSC('MF_VehSales:GetStartData', function(s,c) local m = MFV; while not m.dS or not m.cS or not m.wDS do Citizen.Wait(0); end; c(m.cS,forSale); end)

function AddSale(source,veh,loc,price,props)
  local id = GetPlayerIdentifier(source)
  TCE('MF_VehSales:AddToSale',-1,veh,loc,price,props,id)
  forSale[#forSale+1] = {veh = veh, loc = loc, price = price, vehProps = props, owner = id}
end

function DoBuy(source,veh)
  local vData = false
  for k,v in pairs(forSale) do
    if v.vehProps.plate == veh.vehProps.plate then
      vData = v
      kData = k
    end
  end
  if vData then
    local truePrice = tonumber(vData.price)
    local identifier = GetPlayerIdentifier(source)

    if vData.owner ~= identifier then
      local xPlayer = ESX.GetPlayerFromIdentifier(vData.owner)
      local tick = 0
      while not xPlayer and tick < 1000 do
        tick = tick + 1
        xPlayer = ESX.GetPlayerFromIdentifier(vData.owner)
        Citizen.Wait(0)
      end

      if xPlayer then 
        xPlayer.addMoney(vData.price)
        xPlayer = nil
        local xPlayer = ESX.GetPlayerFromId(source)
        while not xPlayer do xPlayer = ESX.GetPlayerFromId(source); Citizen.Wait(0); end
        xPlayer.removeMoney(vData.price)
        MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate=@plate',{['@plate'] = vData.vehProps.plate},function(data)
          if data then
            MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner,@plate,@vehicle)',{['@owner'] = identifier,['@plate'] = vData.vehProps.plate,['@vehicle'] = json.encode(vData.vehProps)})
          end
        end)
        forSale[kData] = nil
      else
        print("Couldnt find car seller.")
      end
    end
  end
end

NewEvent(true,AddSale,'MF_VehSales:AddSale')
NewEvent(true,DoBuy,'MF_VehSales:BuyVeh')
