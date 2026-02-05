do
  local function is_valentine_time()
    if force_valentine_debug then return true end
    local month = tonumber(os.date("%m"))
    local day = tonumber(os.date("%d"))
    return month == 2 and day >= 10 and day <= 20
  end

  if is_valentine_time() then
    local WAIT, COLLECT, EVENT_MAP = 0, 1, 2
    
    local valentine = {
        state = WAIT,
        materials = {
           {name = "mat_rose", val = 50, ec = 14, image = "img@19bd39f4739", rarity = 1, weight = 30},
           {name = "mat_ribbon", val = 150, ec = 15, image = "img@19bd39f3249", rarity = 2, weight = 20},
           {name = "mat_chocolate", val = 300, ec = 16, image = "img@19bd39f5ba6", rarity = 2, weight = 15},
           {name = "mat_envelope", val = 500, ec = 17, image = "img@19bd39efef5", rarity = 3, weight = 10}
        },
        targetGoal = 1000,
        npcPos = { x = 680, y = 249 },
        sessionData = {},
        map = '<C><P MEDATA=";;;;-0;0:::1-"/><Z><S><S T="12" X="115" Y="285" L="230" H="40" P="0,0,0.3,0.2,0,0,0,0"/><S T="12" X="685" Y="285" L="230" H="40" P="0,0,0.3,0.2,0,0,0,0"/><S T="12" X="400" Y="315" L="270" H="40" P="0,0,0.3,0.2,0,0,0,0"/><S T="12" X="400" Y="305" L="35" H="35" P="0,0,0.3,0.2,45,0,0,0"/><S T="12" X="-5" Y="200" L="10" H="800" P="0,0,0,0.2,0,0,0,0"/><S T="12" X="805" Y="200" L="10" H="800" P="0,0,0,0.2,0,0,0,0"/><S T="12" X="275" Y="280" L="11" H="39" P="0,0,0.3,0.2,0,0,0,0"/><S T="12" X="525" Y="280" L="11" H="39" P="0,0,0.3,0.2,0,0,0,0"/></S><D><P X="380" Y="527" T="19" C="329cd2" P="0,0"/><DS X="100" Y="249"/></D><O/><L/></Z></C>',
        bgImage = "img@19bc98e97af"
    }
    
    activeEvents.valentine = valentine
    local ui_val = ValentineInterface(valentine)
    
    -- Helper to get or initialize session data
    function valentine.getPlayerData(name)
       if not valentine.sessionData[name] then
          local file = players_file[name]
          local energy = 0
          local crafted = file and file:getItemAmount(18, 0) or 0

          valentine.sessionData[name] = { 
             energy = energy,
             totalCrafted = crafted,
             stagedMats = {0,0,0,0}, 
             stagedEnergy = 0,
             roundEnergy = 0,
             roundMats = {0,0,0,0}, 
             
             uiOpen = false,
             tradeOpen = false,
             trade = { target = nil, item = 1, page = 1 },

             inEvent = false,
             auraImg = nil,
             seenMapWelcome = false,
             seenWelcome = false
          }
       end
       return valentine.sessionData[name]
    end

    function valentine.spawnCupid(lookLeft)
        tfm.exec.addNPC("Cupid", {
            title = 432, look = "298;0,58_ffffff+ff7979+ff7979+ff7979+ffffff+ffffff+ffffff+ffffff+ffffff,50_ffffff+ffc1c1+ffffff+ffffff,0,53_ffffff+ffffff+ffffff+ffffff+ffffff+ffffff+ffffff+ffffff,111_ffffff+fdfdfd+ffffff+ffffff+ffffff+ffffff+ffd3d3+ffd3d3,0,84,37,0,0,0",
            x = valentine.npcPos.x, y = valentine.npcPos.y,
            female = false, lookLeft = lookLeft, interactive = true
        })
    end

    function valentine.isValentineAllowed()
      local roomName = room.lowerName
      local isValentine = string.find(roomName, "valentine", 1, true)
      local isRecords = string.find(roomName, "records", 1, true)
      local isVillage = string.find(roomName, "village", 1, true)
      return isValentine and not isRecords and not isVillage
    end

    if valentine.isValentineAllowed() then
        -- Override Parkour's map loader for this specific room
        newMap = function()
            lastOpenedMap = valentine.map
            tfm.exec.newGame(valentine.map)
            ui.setMapName("♥ " .. translatedMessage("val_event_name", nil) .. " ♥")
        end
    end
    
    local weightsTable = {}
    local function precalculateWeights(difficulty)
        if weightsTable[difficulty] then return weightsTable[difficulty] end
        
        local totalWeight = 0
        local weights = {}
        for i=1, #valentine.materials do
            local mat = valentine.materials[i]
            local weight = mat.weight
            if mat.rarity == 2 then
                weight = weight * (1 + (difficulty - 1) * 0.8)
            elseif mat.rarity == 3 then
                weight = weight * (1 + (difficulty - 1) * 1.5)
            end
            totalWeight = totalWeight + weight
            weights[i] = weight
        end
        
        weightsTable[difficulty] = { total = totalWeight, list = weights }
        return weightsTable[difficulty]
    end

    local function selectMaterial(difficulty)
        local data = precalculateWeights(difficulty)
        local totalWeight = data.total
        local weights = data.list

        local random = math.random() * totalWeight
        local current = 0
        for i=1, #weights do
            current = current + weights[i]
            if random <= current then
                return i
            end
        end
        return 1
    end

    function valentine.giveReward(pName)
        local difficulty = current_difficulty or 1
        local numRewards = difficulty -- 1, 2, or 3 items based on difficulty
        local file = players_file[pName]
        if not file then return end
        
        local rewardNames = {}
        for i = 1, numRewards do
            local matIndex = selectMaterial(difficulty)
            local mat = valentine.materials[matIndex]
            
            -- Check material limit (100)
            local currentAmount = file:getItemAmount(mat.ec, 0)
            if currentAmount < 100 then
                file:updateItem(mat.ec, 0, 1)
                table.insert(rewardNames, translatedMessage(mat.name, pName))
            end
        end
        
        -- No savePlayerData here, core handles it on win
        
        if #rewardNames > 0 then
            translatedChatMessage("val_reward_solo", pName, table.concat(rewardNames, ", "))
            translatedChatMessage("val_collect_hint", pName)
            
            local info = tfm.get.room.playerList[pName]
            if info then
                tfm.exec.displayParticle(13, info.x, info.y)
                for i = 1, 3 do
                    tfm.exec.displayParticle(5, info.x + math.random(-15, 15), info.y + math.random(-15, 15), 0, 0, 0, 0)
                end
            end
        end
    end

    function valentine.reset()
        for name, p in pairs(valentine.sessionData) do
            p.tradeOpen = false
            p.uiOpen = false
            p.inEvent = false
            if p.auraImg then 
                tfm.exec.removeImage(p.auraImg)
                p.auraImg = nil
            end
            ui_val.gifting.hide(name)
            ui_val.fountain.hide(name)
        end
        valentine.collect = { items = {}, collected = {}, images = {} }
    end

    function valentine.debug(player, cmd, argc, args)
        if args[2] == "map" then
            lastOpenedMap = valentine.map
            tfm.exec.newGame(valentine.map)
        else
            tfm.exec.chatMessage("<J>!event valentine [map]", player)
        end
    end

    onEvent("NewGame", function()
        valentine.reset()
        
        local isEventMap = (lastOpenedMap and lastOpenedMap == valentine.map) or valentine.isValentineAllowed()
        
        if isEventMap then
             valentine.state = EVENT_MAP
             tfm.exec.addImage(valentine.bgImage, "?1", 0, 0)
             ui.setMapName("♥ " .. translatedMessage("val_event_name", nil) .. " ♥")
             tfm.exec.setGameTime(9999)
             tfm.exec.disableAutoNewGame(true)
             valentine.spawnCupid(true)
             
             for name in next, in_room do 
                 ui_val.fountain.show(name)
                 local p = valentine.getPlayerData(name)
                 if not p.seenMapWelcome then
                     translatedChatMessage("val_welcome_craft", name)
                     p.seenMapWelcome = true
                 end
             end
        else
            valentine.state = COLLECT
            valentine.collect = { items = {}, collected = {}, images = {} }
            
            
                for name in next, in_room do
                  local pData = valentine.getPlayerData(name)
                  if not pData.seenWelcome then
                      translatedChatMessage("val_welcome", name)
                      pData.seenWelcome = true
                  end
             end
        end
    end)

    onEvent("EmotePlayed", function(name, emotion)
        if valentine.state == WAIT then return end
        
        -- SOLO ACTIVATION: Kiss emote (3) - Only allowed during normal parkour play (COLLECT)
        if emotion == 3 and valentine.state == COLLECT then
            if not checkCooldown(name, "val_kiss", 1000) then return end -- Spam protection (1s cooldown)
            
            local p = valentine.getPlayerData(name)
            if not p.inEvent and not valentine.collect.collected[name] then
                -- IMMEDIATE STATE UPDATE: Set inEvent to true before any visual/network processing
                p.inEvent = true
                
                translatedChatMessage("val_mission_start", name)
                
                -- Add Heart Aura image (User ID: 17ddb091cba.png)
                p.auraImg = tfm.exec.addImage("17ddb091cba.png", "$" .. name, -18, -52, nil, 1, 1)

                -- Subtle Heart Burst Effect on activation (ID 5 particles)
                local info = tfm.get.room.playerList[name]
                if info then
                    for i = 1, 4 do
                        tfm.exec.displayParticle(5, info.x + math.random(-5, 5), info.y + math.random(-15, 0), math.random(-5, 5) / 10, math.random(-5, 5) / 10, 0, 0)
                    end
                end
            end
        end
    end)

    onEvent("PlayerRespawn", function(name)
        if valentine.state == WAIT then return end
        local p = valentine.getPlayerData(name)
        if p.inEvent then
            if p.auraImg then tfm.exec.removeImage(p.auraImg) end
            p.auraImg = tfm.exec.addImage("17ddb091cba.png", "$" .. name, -18, -52, nil, 1, 1)
        end
    end)

    onEvent("PlayerWon", function(name)
        if valentine.state == WAIT then return end
        local p = valentine.getPlayerData(name)
        
        if p.inEvent then
            p.inEvent = false
            valentine.collect.collected[name] = true
            if p.auraImg then
                tfm.exec.removeImage(p.auraImg)
                p.auraImg = nil
            end
            valentine.giveReward(name)
        end
    end)

    onEvent("TalkToNPC", function(name, npc)
        if valentine.state == EVENT_MAP and npc == "Cupid" then ui_val.gifting.show(name) end
    end)
    
    onEvent("TextAreaCallback", function(id, name, cb)
        if valentine.state ~= EVENT_MAP or cb:sub(1,4) ~= "val_" then return end
        local p = valentine.getPlayerData(name)
        
        if cb == "val_close" then ui_val.gifting.hide(name)
        elseif cb:find("val_item_") then p.trade.item = tonumber(cb:sub(10)) ui_val.gifting.updateItems(name) ui_val.gifting.updateAction(name)
        elseif cb:find("val_plr_") then p.trade.target = cb:sub(9) ui_val.gifting.updatePlayers(name) ui_val.gifting.updateAction(name)
        elseif cb == "val_next" then p.trade.page = p.trade.page + 1 ui_val.gifting.updatePlayers(name)
        elseif cb == "val_prev" then p.trade.page = p.trade.page - 1 ui_val.gifting.updatePlayers(name)
        elseif cb == "val_add_all" then
            local file = players_file[name]
            if not file or (p.energy + p.stagedEnergy) >= valentine.targetGoal then return end -- Logic: Add All prepares exactly 1000 or multiples if we expand, but for now focus on getting to target

            -- Calculate total potential energy from inventory
            local totalAvailableEnergy = 0
            for i, m in next, valentine.materials do
                totalAvailableEnergy = totalAvailableEnergy + (file:getItemAmount(m.ec, 0) * m.val)
            end

            -- How many rings can we complete?
            local rings = math.floor((totalAvailableEnergy + p.energy + p.stagedEnergy) / 1000)
            if rings < 1 then 
                translatedChatMessage("val_insufficient_materials", name, name)
                return 
            end

            -- Calculate exact energy to add to reach rings * 1000
            local targetNeeded = (rings * 1000) - (p.energy + p.stagedEnergy)
            
            -- Reset staged materials for this new "add all" operation
            p.stagedMats = {0,0,0,0}
            p.stagedEnergy = 0

            -- Greedily pick materials (Highest Value First)
            for i = #valentine.materials, 1, -1 do
                local mat = valentine.materials[i]
                local invCount = file:getItemAmount(mat.ec, 0)
                local canTake = math.floor(targetNeeded / mat.val)
                local toTake = math.min(invCount, canTake)
                
                if toTake > 0 then
                    p.stagedMats[i] = toTake
                    p.stagedEnergy = p.stagedEnergy + (toTake * mat.val)
                    targetNeeded = targetNeeded - (toTake * mat.val)
                end
            end
            
            -- Session update for UI
            p.roundEnergy = p.stagedEnergy
            p.roundMats = p.stagedMats
            
            ui_val.fountain.show(name)
            translatedChatMessage("val_all_selected", name, name)

        elseif cb == "val_reset" then
            -- Simply clear session staging
            p.stagedMats = {0,0,0,0}
            p.stagedEnergy = 0
            p.roundEnergy = 0
            p.roundMats = {0,0,0,0}
            
            ui_val.fountain.show(name)
            translatedChatMessage("val_fountain_reset", name)
        elseif cb == "val_gift_ask" then 
            ui_val.gifting.showConfirm(name)
        elseif cb == "val_yes" then
            local mat = valentine.materials[p.trade.item]
            local target = p.trade.target
            local file = players_file[name]
            if target and mat and file and file:getItemAmount(mat.ec, 0) > 0 then
                file:updateItem(mat.ec, 0, -1)
                savePlayerData(name)
                local tFile = players_file[target]
                if tFile then
                    -- Limit check for receiver
                    if tFile:getItemAmount(mat.ec, 0) >= 100 then
                        tfm.exec.chatMessage("<ROSE>♥ " .. target .. " " .. translatedMessage("val_material_limit", name) .. " ♥", name)
                        ui_val.gifting.hideConfirm(name)
                        return
                    end

                    tFile:updateItem(mat.ec, 0, 1)
                    savePlayerData(target)
                    local tData = valentine.getPlayerData(target)
                    if tData then
                        if tData.tradeOpen then ui_val.gifting.updateItems(target) end
                        if tData.uiOpen then ui_val.fountain.show(target) end
                    end
                end
                
                translatedChatMessage("val_gift_send", name, target, translatedMessage(mat.name, name))
                translatedChatMessage("val_gift_receive", target, name, translatedMessage(mat.name, target))
                
                -- Sync with staging: if we gave away something that was in the fountain, reset staging to be safe
                if p.stagedMats[p.trade.item] > 0 then
                    p.stagedMats = {0,0,0,0}
                    p.stagedEnergy = 0
                    p.roundEnergy = 0
                    p.roundMats = {0,0,0,0}
                    translatedChatMessage("val_fountain_reset", name)
                end

                ui_val.gifting.hideConfirm(name)
                ui_val.gifting.updateItems(name)
                ui_val.gifting.updatePlayers(name)
                ui_val.gifting.updateAction(name)
                if p.uiOpen then ui_val.fountain.show(name) end
            end
        elseif cb == "val_no" then
            ui_val.gifting.hideConfirm(name)
        elseif cb == "val_craft" then
            if (p.energy + p.stagedEnergy) >= valentine.targetGoal then
                local file = players_file[name]
                if not file then return end

                -- VERIFICATION: Double check that the player still has the materials in their actual inventory
                for i, count in next, p.stagedMats do
                    if count > 0 and file:getItemAmount(valentine.materials[i].ec, 0) < count then
                        -- Inventory drifted (gifted/traded while UI open)
                        p.stagedMats = {0,0,0,0}
                        p.stagedEnergy = 0
                        p.roundEnergy = 0
                        p.roundMats = {0,0,0,0}
                        translatedChatMessage("val_insufficient_materials", name, name)
                        ui_val.fountain.show(name)
                        return
                    end
                end

                -- Batch deduct staged materials
                for i, count in next, p.stagedMats do
                    if count > 0 then
                        file:updateItem(valentine.materials[i].ec, 0, -count)
                    end
                end

                p.energy = p.energy + p.stagedEnergy
                local ringsCreated = math.floor(p.energy / 1000)
                
                -- Check shop limit (Ring EC 18 has limit 200)
                local currentRings = file:getItemAmount(18, 0)
                local maxAllowed = 200
                
                if currentRings >= maxAllowed then
                    -- Refund materials if already at limit
                    for i, count in next, p.stagedMats do
                        if count > 0 then
                            file:updateItem(valentine.materials[i].ec, 0, count)
                        end
                    end
                    p.energy = p.energy - p.stagedEnergy
                    savePlayerData(name)
                    translatedChatMessage("val_ring_limit_reached", name, name)
                    ui_val.fountain.show(name)
                    return
                end
                
                -- Limit rings created to not exceed maxAllowed
                if currentRings + ringsCreated > maxAllowed then
                    ringsCreated = maxAllowed - currentRings
                    p.energy = (currentRings + ringsCreated >= maxAllowed) and 0 or (p.energy % 1000)
                end
                
                -- Reward rings
                file:updateItem(18, 0, ringsCreated)
                
                -- Residual energy management
                p.energy = p.energy % 1000
                
                -- Cleanup session
                p.stagedMats = {0,0,0,0}
                p.stagedEnergy = 0
                p.roundEnergy = 0
                p.roundMats = {0,0,0,0}
                
                p.totalCrafted = file:getItemAmount(18, 0)
                
                savePlayerData(name)
                ui_val.fountain.show(name)
                translatedChatMessage("val_crafted", name, name, ringsCreated)
                translatedChatMessage("val_village_hint", name)
            end
            ui_val.fountain.show(name)
        end
    end)

    onEvent("NewPlayer", function(name)
        local pData = valentine.getPlayerData(name)
        local file = players_file[name]

        if valentine.state == EVENT_MAP then
            tfm.exec.addImage(valentine.bgImage, "_0", 0, 0, name)
            valentine.spawnCupid(true)
            ui_val.fountain.show(name)
            
            if not pData.seenMapWelcome then
                translatedChatMessage("val_welcome_craft", name)
                pData.seenMapWelcome = true
            end
        elseif valentine.state == COLLECT then
            if not pData.seenWelcome then
                 translatedChatMessage("val_welcome", name)
                 pData.seenWelcome = true
            end
        end
    end)
    
    onEvent("PlayerLeft", function(name)
        valentine.sessionData[name] = nil
    end)

    onEvent("PlayerDied", function(name)
    end)

    onEvent("PlayerDataParsed", function(name)
        local file = players_file[name]
        local p = valentine.getPlayerData(name)
        
        if file and p then
             -- SYNC: Update session data (Energy is no longer persistent, derived from Ring count for display)
             p.energy = 0 
             p.totalCrafted = file:getItemAmount(18, 0)
             
             if valentine.state == EVENT_MAP then
                 ui_val.fountain.show(name)
             end
        end
    end)

    newCmd({ name = "valentine", rank = "admin", fn = function(player, args)
        if args[1] == "map" then 
            lastOpenedMap = valentine.map
            tfm.exec.newGame(valentine.map) 
        elseif args[1] == "give" then
            local mid = tonumber(args[2])
            local amount = tonumber(args[3])
            local target = args[4] or player
            
            if mid and amount and valentine.materials[mid] then
                local mat = valentine.materials[mid]
                local file = players_file[target]
                if file then
                     file:updateItem(mat.ec, 0, amount)
                     savePlayerData(target)
                     tfm.exec.chatMessage("<J>Gave " .. amount .. " " .. mat.name .. " to " .. target, player)
                     
                     if valentine.sessionData[target] and valentine.sessionData[target].tradeOpen then
                         ui_val.gifting.updateItems(target)
                     end
                else
                     tfm.exec.chatMessage("<R>Player not found or file not loaded.", player)
                end
            else
                tfm.exec.chatMessage("<R>Usage: !valentine give <id 1-4> <amount> [player]", player)
            end
        end
    end })
  end
end
