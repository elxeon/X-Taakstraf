# X-Taakstraf README

## Overzicht

Dit project biedt een HTML addon voor de `esx_communityservice` script in een FiveM ESX-server. Het voegt extra informatie toe aan de community service ervaring door middel van een gebruiksvriendelijke interface.

## Installatie

Volg de onderstaande stappen om de HTML addon aan je `esx_communityservice` script toe te voegen.

### Client Side

1. Open het `client.lua` bestand van `esx_communityservice`.
2. Voeg de volgende code toe aan de top van het bestand om de `serviceInfo` variabele te initialiseren:

    ```lua
    local serviceInfo = {
      startTime = "",
      assignedBy = "",
      reason = ""
    }
    ```

3. Zoek de `RegisterNetEvent` en `AddEventHandler` voor `esx_communityservice:inCommunityService` en update het als volgt:

    ```lua
    RegisterNetEvent('esx_communityservice:inCommunityService')
    AddEventHandler('esx_communityservice:inCommunityService', function(actions_remaining, start_time, assigned_by, reason)
        actionsRemaining = actions_remaining
        serviceInfo.startTime = start_time
        serviceInfo.assignedBy = assigned_by
        serviceInfo.reason = reason

        SendNUIMessage({
            actionsRemaining = actionsRemaining,
            startTime = serviceInfo.startTime,
            assignedBy = serviceInfo.assignedBy,
            reason = serviceInfo.reason
        })
    end)
    ```

4. Voeg de `SendNUIMessage` functie toe in de `Citizen` thread wanneer de persoon wordt weggestuurd:

    ```lua
    SendNUIMessage({
        actionsRemaining = actionsRemaining,
        startTime = serviceInfo.startTime,
        assignedBy = serviceInfo.assignedBy,
        reason = serviceInfo.reason
    })
    ```

### Server Side

1. Open het `server.lua` bestand van `esx_communityservice`.
2. Zoek de `RegisterNetEvent` en `AddEventHandler` voor `esx_communityservice:checkIfSentenced` en update het als volgt:

    ```lua
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
    ```

3. Zoek de `RegisterServerEvent` en `AddEventHandler` voor `esx_communityservice:sendToCommunityService` en update het als volgt:

    ```lua
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
    ```

### HTML

1. Maak een nieuw HTML-bestand genaamd `service.html` in je NUI map (bijvoorbeeld `esx_communityservice/html/`).
2. Voeg de volgende HTML code toe:

    ```html
    <!DOCTYPE html>
    <html>
    <head>
        <title>Taakstraf</title>
        <style>
            #service-menu {
                position: fixed;
                bottom: 20px;
                left: 20px;
                background: rgba(0, 0, 0, 0.7);
                color: white;
                padding: 10px;
                border-radius: 5px;
                font-family: Arial, sans-serif;
                font-size: 14px;
            }
        </style>
    </head>
    <body>
        <div id="service-menu">
            <p id="actions-remaining">Taken:</p>
            <p id="start-time">Begin Tijd:</p>
            <p id="assigned-by">Gegeven door:</p>
            <p id="reason">Reden:</p>
        </div>
        <script>
            window.addEventListener('message', function(event) {
                var data = event.data;
                document.getElementById('actions-remaining').textContent = "Actions Remaining: " + data.actionsRemaining;
                document.getElementById('start-time').textContent = "Start Time: " + data.startTime;
                document.getElementById('assigned-by').textContent = "Assigned By: " + data.assignedBy;
                document.getElementById('reason').textContent = "Reason: " + data.reason;
            });
        </script>
    </body>
    </html>
    ```

## Gebruik

Wanneer een speler wordt gestraft met taakstraf, zal de bovenstaande HTML automatisch verschijnen met de relevante informatie over de taakstraf. Deze informatie omvat het aantal resterende taken, de starttijd van de taakstraf, wie de taakstraf heeft gegeven en de reden voor de taakstraf.

## Ondersteuning

Voor vragen of problemen, open een issue in deze repository of neem contact op met de ontwikkelaar via de beschikbare kanalen.

---

Met deze instructies zou je de HTML addon voor `esx_communityservice` succesvol moeten kunnen integreren. Veel succes!
