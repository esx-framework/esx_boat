function ParkBoats()
  local affectedRows = MySQL.update.await(
  'UPDATE owned_vehicles SET `stored` = true WHERE `stored` = false AND type = @type', {
    ['@type'] = 'boat'
  })

  if affectedRows == 0 then
    return true
  end

  print(('[^2INFO^7] Stored ^5%s^7 %s !'):format(affectedRows, affectedRows > 1 and 'boats' or 'boat'))
  return true
end

MySQL.ready(function()
  local storedBoats = ParkBoats()
  if not storedBoats then
    print('[^1ERROR^7] Failed to store boats!')
  end
end)

ESX.RegisterServerCallback('esx_boat:buyBoat', function(source, cb, vehicleProps)
  local xPlayer = ESX.GetPlayerFromId(source)
  local price   = GetPriceFromModel(vehicleProps.model)

  -- vehicle model not found
  if price == 0 then
    Config.HandleExploitation(source)
    cb(false)
    return
  end

  if xPlayer.getMoney() < price then
    cb(false)
    return
  end

  local affectedRows = MySQL.update.await(
  'INSERT INTO owned_vehicles (owner, plate, vehicle, type, `stored`) VALUES (@owner, @plate, @vehicle, @type, @stored)',
    {
      ['@owner']   = xPlayer.identifier,
      ['@plate']   = vehicleProps.plate,
      ['@vehicle'] = json.encode(vehicleProps),
      ['@type']    = 'boat',
      ['@stored']  = true
    })

  if affectedRows > 0 then
    xPlayer.removeMoney(price, "Boat Purchase")
    cb(true)
  else
    Config.HandleExploitation(source)
    cb(false)
  end
end)

RegisterNetEvent('esx_boat:takeOutVehicle', function(plate)
  local xPlayer = ESX.GetPlayerFromId(source)

  local affectedRows = MySQL.update.await(
  'UPDATE owned_vehicles SET `stored` = @stored WHERE owner = @owner AND plate = @plate', {
    ['@stored'] = false,
    ['@owner']  = xPlayer.identifier,
    ['@plate']  = plate
  })

  if affectedRows > 0 then
    return
  end
  Config.HandleExploitation(source)
end)

ESX.RegisterServerCallback('esx_boat:storeVehicle', function(source, cb, plate)
  local xPlayer = ESX.GetPlayerFromId(source)

  local affectedRows = MySQL.update(
  'UPDATE owned_vehicles SET `stored` = @stored WHERE owner = @owner AND plate = @plate', {
    ['@stored'] = true,
    ['@owner']  = xPlayer.identifier,
    ['@plate']  = plate
  })

  cb(affectedRows == 1)
end)

ESX.RegisterServerCallback('esx_boat:getGarage', function(source, cb)
  local xPlayer = ESX.GetPlayerFromId(source)

  local result = MySQL.query.await(
  'SELECT vehicle FROM owned_vehicles WHERE owner = @owner AND type = @type AND `stored` = @stored', {
    ['@owner']  = xPlayer.identifier,
    ['@type']   = 'boat',
    ['@stored'] = true
  })

  local vehicles = {}

  for i = 1, #result, 1 do
    table.insert(vehicles, result[i].vehicle)
  end

  cb(vehicles)
end)

ESX.RegisterServerCallback('esx_boat:buyBoatLicense', function(source, cb)
  local xPlayer = ESX.GetPlayerFromId(source)

  if xPlayer.getMoney() >= Config.LicensePrice then
    xPlayer.removeMoney(Config.LicensePrice, "Boat License Purchase")

    TriggerEvent('esx_license:addLicense', source, 'boat', function()
      cb(true)
    end)
  else
    cb(false)
  end
end)

function GetPriceFromModel(model)
  for k, v in ipairs(Config.Vehicles) do
    if joaat(v.model) == model then
      return v.price
    end
  end

  return 0
end
