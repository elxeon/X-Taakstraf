ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterCommand("endserv", function(source, args, rawCommand)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getJob().name == "unemployed" then 
		if args[1] then
			local target = tonumber(args[1])
			if GetPlayerName(target) ~= nil then
				releaseFromCommunityService(target)
			end
		end
	else
		TriggerClientEvent('esx:showNotification', source, 'No permission')
	end
end, false)

RegisterCommand("comserv", function(source, args, rawCommand)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getJob().name == "unemployed" then 
		if args[1] and GetPlayerName(args[1]) ~= nil and tonumber(args[2]) then
			local reason = table.concat(args, " ", 3)
			TriggerEvent('esx_communityservice:sendToCommunityService', tonumber(args[1]), tonumber(args[2]), reason, GetPlayerName(source))
		end
	else
		TriggerClientEvent('esx:showNotification', source, 'No permission')
	end
end, false)

RegisterServerEvent('esx_communityservice:endCommunityServiceCommand')
AddEventHandler('esx_communityservice:endCommunityServiceCommand', function(target)
	if target ~= nil then
		releaseFromCommunityService(target)
	end
end)

RegisterServerEvent('esx_communityservice:finishCommunityService')
AddEventHandler('esx_communityservice:finishCommunityService', function()
	releaseFromCommunityService(source)
end)

RegisterServerEvent('esx_communityservice:completeService')
AddEventHandler('esx_communityservice:completeService', function()
	local _source = source
	local identifier = GetPlayerIdentifiers(_source)[1]

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = actions_remaining - 1 WHERE identifier = @identifier', {
				['@identifier'] = identifier
			})
		else
			print("ESX_CommunityService :: Problem matching player identifier in database to reduce actions.")
		end
	end)
end)

RegisterServerEvent('esx_communityservice:extendService')
AddEventHandler('esx_communityservice:extendService', function()
	local _source = source
	local identifier = GetPlayerIdentifiers(_source)[1]

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = actions_remaining + @extension_value WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@extension_value'] = Config.ServiceExtensionOnEscape
			})
		else
			print("ESX_CommunityService :: Problem matching player identifier in database to extend actions.")
		end
	end)
end)

RegisterNetEvent('esx_communityservice:checkIfSentenced')
AddEventHandler('esx_communityservice:checkIfSentenced', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result[1] then
            local actions_remaining = result[1].actions_remaining
            local start_time = result[1].start_time
            local assigned_by = result[1].assigned_by
            local reason = result[1].reason

            TriggerClientEvent('esx_communityservice:inCommunityService', _source, actions_remaining, start_time, assigned_by, reason)
        end
    end)
end)

RegisterServerEvent('esx_communityservice:sendToCommunityService')
AddEventHandler('esx_communityservice:sendToCommunityService', function(target, actions_count, reason, assigned_by)
	local identifier = GetPlayerIdentifiers(target)[1]
	local current_date = os.date('%Y-%m-%d %H:%M:%S')

	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('UPDATE communityservice SET actions_remaining = @actions_remaining, start_time = @start_time, assigned_by = @assigned_by, reason = @reason WHERE identifier = @identifier', {
				['@identifier'] = identifier,
				['@actions_remaining'] = actions_count,
				['@start_time'] = current_date,
				['@assigned_by'] = assigned_by,
				['@reason'] = reason
			})
		else
			MySQL.Async.execute('INSERT INTO communityservice (identifier, actions_remaining, start_time, assigned_by, reason) VALUES (@identifier, @actions_remaining, @start_time, @assigned_by, @reason)', {
				['@identifier'] = identifier,
				['@actions_remaining'] = actions_count,
				['@start_time'] = current_date,
				['@assigned_by'] = assigned_by,
				['@reason'] = reason
			})
		end

		TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_msg', GetPlayerName(target), actions_count) }, color = { 147, 196, 109 } })
		TriggerClientEvent('esx_policejob:unrestrain', target)
		TriggerClientEvent('esx_communityservice:inCommunityService', target, actions_count, current_date, assigned_by, reason)
	end)
end)

function releaseFromCommunityService(target)
	local identifier = GetPlayerIdentifiers(target)[1]
	MySQL.Async.fetchAll('SELECT * FROM communityservice WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(result)
		if result[1] then
			MySQL.Async.execute('DELETE from communityservice WHERE identifier = @identifier', {
				['@identifier'] = identifier
			})

			TriggerClientEvent('chat:addMessage', -1, { args = { _U('judge'), _U('comserv_finished', GetPlayerName(target)) }, color = { 147, 196, 109 } })
		end
	end)

	TriggerClientEvent('esx_communityservice:finishCommunityService', target)
end
