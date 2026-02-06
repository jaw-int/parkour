
function ValentineInterface(valentine)
    local gifting = {}
    local fountain = {}
    
    -- Gifting UI Elements
    local GIFT_BG = allocateId("textarea", 40000)
    local GIFT_TITLE = allocateId("textarea", 40000)
    local GIFT_CLOSE = allocateId("textarea", 40000)
    local GIFT_ITEMS = allocateId("textarea", 40000)
    local GIFT_PLAYERS = allocateId("textarea", 40000)
    local GIFT_PAGE = allocateId("textarea", 40000)
    local GIFT_ACTION = allocateId("textarea", 40000)
    
    -- Confirm UI
    local CONFIRM_BG = allocateId("textarea", 41000)
    local CONFIRM_TEXT = allocateId("textarea", 41000)
    local CONFIRM_YES = allocateId("textarea", 41000)
    local CONFIRM_NO = allocateId("textarea", 41000)
    
    -- Fountain UI Elements
    local FOUNTAIN_BG = allocateId("textarea", 42000)
    local FOUNTAIN_TEXT = allocateId("textarea", 42000)
    local FOUNTAIN_STATS_BG = allocateId("textarea", 42000)
    local FOUNTAIN_STATS_TXT = allocateId("textarea", 42000)
    
    local isOpenGifting = {}
    local isOpenFountain = {}
    
    -- Helper to get player valentine data
    local function getValData(player)
        return valentine.getPlayerData(player)
    end
    
    function gifting.show(name)
        local p = getValData(name)
        if not p then return end
        isOpenGifting[name] = true
        p.tradeOpen = true
        
        -- Hide fountain to avoid overlap
        fountain.hide(name)
        
        -- Centered Glass Box
        ui.addTextArea(GIFT_BG, "", name, 190, 120, 420, 240, 0x070707, 0xFF3366, 0.9, false) 
        ui.addTextArea(GIFT_TITLE, "<p align='center'><font size='16' color='#FF3366'><b>" .. translatedMessage("val_ui_gifting_title", name) .. "</b></font></p>", name, 190, 130, 420, 25, 0, 0, 0, false)
        ui.addTextArea(GIFT_CLOSE, "<p align='right'><a href='event:val_close'><font color='#FF4D4D' size='13'><b>X</b></font></a></p>", name, 570, 125, 30, 30, 0, 0, 0, false)
        
        gifting.updateItems(name)
        gifting.updatePlayers(name)
        gifting.updateAction(name)
    end
    
    function gifting.updateItems(name)
        if not isOpenGifting[name] then return end
        local p = getValData(name)
        local t = p.trade
        local file = players_file[name]
        if not file then return end
        
        local items = "<p align='center'><font color='#FFB3D1' size='11'><b>" .. translatedMessage("val_ui_item_selection", name) .. "</b></font></p>\n"
        for i, m in ipairs(valentine.materials) do
            local count = file:getItemAmount(m.ec, 0)
            local isSelected = (t.item == i)
            local color = isSelected and "#00FF88" or "#FFFFFF"
            items = items .. "<a href='event:val_item_" .. i .. "'><font color='" .. color .. "' size='12'>" .. (isSelected and "• " or "") .. translatedMessage(m.name, name) .. " (x" .. count .. ")</font></a>\n"
        end
        ui.addTextArea(GIFT_ITEMS, items, name, 205, 170, 185, 120, 0x0A0A0A, 0xFF3366, 0.45, false)
    end
    
    function gifting.updatePlayers(name)
        if not isOpenGifting[name] then return end
        local p = getValData(name)
        local t = p.trade
        
        local allPlrs = {}
        for pName, data in pairs(tfm.get.room.playerList) do 
            if pName ~= name and data.score ~= -1 and in_room[pName] then table.insert(allPlrs, pName) end 
        end
        table.sort(allPlrs)
        
        local perPage = 4
        local targetExists = false
        for _, pl in ipairs(allPlrs) do
            if pl == t.target then targetExists = true break end
        end
        if t.target and not targetExists then t.target = nil end
        
        local maxPage = math.max(1, math.ceil(#allPlrs / perPage))
        if t.page > maxPage then t.page = maxPage end
        
        local plrs = "<p align='center'><font color='#FFB3D1' size='11'><b>" .. translatedMessage("val_ui_target_selection", name) .. "</b></font></p>\n"
        local startIdx = (t.page - 1) * perPage + 1
        for i = startIdx, startIdx + (perPage - 1) do
            local n = allPlrs[i]
            if n then
                local color = (t.target == n) and "#00FF88" or "#FFFFFF"
                plrs = plrs .. "<a href='event:val_plr_" .. n .. "'><font color='" .. color .. "' size='11'>" .. n .. "</font></a>\n"
            end
        end
        ui.removeTextArea(GIFT_PLAYERS, name)
        ui.addTextArea(GIFT_PLAYERS, plrs, name, 415, 170, 185, 120, 0x0A0A0A, 0xFF3366, 0.45, false)
        
        -- Page indicator at the very bottom
        local pageTxt = "<p align='center'><font size='13'>"
        pageTxt = pageTxt .. (t.page > 1 and "<a href='event:val_prev'><font color='#00FF88'>«</font></a>  " or "<font color='#333333'>«</font>  ")
        pageTxt = pageTxt .. "<font color='#FFDEE9'>" .. t.page .. " / " .. maxPage .. "</font>"
        pageTxt = pageTxt .. (t.page < maxPage and "  <a href='event:val_next'><font color='#00FF88'>»</font></a>" or "  <font color='#333333'>»</font>")
        pageTxt = pageTxt .. "</font></p>"
        ui.removeTextArea(GIFT_PAGE, name)
        ui.addTextArea(GIFT_PAGE, pageTxt, name, 190, 335, 420, 25, 0, 0, 0, false)
    end
    
    function gifting.updateAction(name)
        if not isOpenGifting[name] then return end
        local p = getValData(name)
        local t = p.trade
        local file = players_file[name]
        if not file then return end
        local hasItem = file:getItemAmount(valentine.materials[t.item].ec, 0) > 0
        
        local bx, by = 325, 305 -- Original coordinates for GIFT_ACTION
        if t.target and hasItem then
            ui.addTextArea(GIFT_ACTION, "<p align='center'><a href='event:val_gift_ask'><b><font size='13' color='#FFFFFF'>" .. translatedMessage("val_ui_gift_button", name) .. "</font></b></a></p>", name, bx, by, 150, 25, 0x00FF88, 0x006633, 0.8, false)
        else
            ui.addTextArea(GIFT_ACTION, "<p align='center'><font size='11' color='#555555'>" .. translatedMessage("val_ui_selection_needed", name) .. "</font></p>", name, bx, by, 150, 25, 0x151515, 0x333333, 0.6, false)
        end
    end

    function gifting.showConfirm(name)
        if not isOpenGifting[name] then return end
        local p = getValData(name)
        local item = valentine.materials[p.trade.item]
        local matName = translatedMessage(item.name, name)
        
        -- High prominence confirmation
        ui.addTextArea(CONFIRM_BG, "", name, 210, 150, 380, 180, 0x020202, 0xFF3366, 0.95, false)
        ui.addTextArea(CONFIRM_TEXT, string.format("<p align='center'><font color='#FFDEE9' size='14'><b>" .. translatedMessage("val_ui_warning", name) .. "</b></font><br><br><font color='#FFFFFF' size='13'><b>" .. translatedMessage("val_ui_confirm_text", name, p.trade.target, matName) .. "</b></font></p>"), name, 220, 165, 360, 100, 0, 0, 0, false)
        ui.addTextArea(CONFIRM_YES, "<p align='center'><a href='event:val_yes'><font color='#00FF88' size='14'><b>" .. translatedMessage("val_ui_yes", name) .. "</b></font></a></p>", name, 260, 280, 120, 26, 0x0A0A0A, 0x00FF88, 1, false)
        ui.addTextArea(CONFIRM_NO, "<p align='center'><a href='event:val_no'><font color='#FF4D4D' size='14'><b>" .. translatedMessage("val_ui_no", name) .. "</b></font></a></p>", name, 420, 280, 120, 26, 0x0A0A0A, 0xFF4D4D, 1, false)
    end
    
    function gifting.hideConfirm(name)
        ui.removeTextArea(CONFIRM_BG, name)
        ui.removeTextArea(CONFIRM_TEXT, name)
        ui.removeTextArea(CONFIRM_YES, name)
        ui.removeTextArea(CONFIRM_NO, name)
    end
    
    function gifting.hide(name)
        local p = getValData(name)
        if p then p.tradeOpen = false end
        isOpenGifting[name] = nil
        ui.removeTextArea(GIFT_BG, name)
        ui.removeTextArea(GIFT_TITLE, name)
        ui.removeTextArea(GIFT_CLOSE, name)
        ui.removeTextArea(GIFT_ITEMS, name)
        ui.removeTextArea(GIFT_PLAYERS, name)
        ui.removeTextArea(GIFT_PAGE, name)
        ui.removeTextArea(GIFT_ACTION, name)
        gifting.hideConfirm(name)
        
        -- Restore fountain if in event map
        if valentine.state == 2 then
            fountain.show(name)
        end
    end
    
    function fountain.show(name)
        local p = getValData(name)
        if not p or p.shopOpen then return end -- Don't show if shop is open
        isOpenFountain[name] = true
        p.uiOpen = true
        
        local file = players_file[name]
        if not file then return end
        
        -- Material Columns
        local coords = {
            {x = 10, y = 30},   -- Gül
            {x = 10, y = 70},   -- Kurdele
            {x = 640, y = 30},  -- Çikolata
            {x = 640, y = 70}   -- Mektup
        }
        
        if not p.uiImgIds then p.uiImgIds = {} end
        
        for i, m in ipairs(valentine.materials) do
            local count = file:getItemAmount(m.ec, 0)
            local staged = (p.stagedMats and p.stagedMats[i]) or 0
            local pos = coords[i]
            
            -- Removing the background TextArea (tid) as per user suggestion
            -- ui.addTextArea(tid, "", name, pos.x, pos.y, 150, 25, 0x070707, 0xFF4D88, 1.0, false)
            
            if p.uiImgIds[i] then tfm.exec.removeImage(p.uiImgIds[i]) end
            -- Icons on layer ~10 (screen attached), jitter-free
            p.uiImgIds[i] = tfm.exec.addImage(m.image, "~10", pos.x + 3, pos.y + 1, name, 0.6, 0.6)
            
            -- Materials are now visual only
            local displayCount = count
            ui.addTextArea(FOUNTAIN_TEXT + 20 + i, "<p align='left'><font color='#FFFFFF' size='12'><b>  " .. translatedMessage(m.name, name) .. "</b> <font color='#FFD700'>(x" .. displayCount .. ")</font></font></p>", name, pos.x + 25, pos.y + 2, 150, 20, 0, 0, 0, false)
        end
        
        -- Action Area
        local bx, by = 640, 310
        local lx, ly = 10, 310 -- Left side for Add All
        
        -- Add All Button (New)
        local canAddAll = (p.stagedEnergy or 0) < 1000 -- Just a simple check for now
        ui.addTextArea(FOUNTAIN_TEXT + 5, "", name, lx, ly, 150, 25, 0x070707, 0xFFDEE9, 0.5, false)
        ui.addTextArea(FOUNTAIN_TEXT + 50, "<p align='center'><a href='event:val_add_all'><font color='#FFDEE9' size='11'><b>" .. translatedMessage("val_ui_add_all", name) .. "</b></font></a></p>", name, lx, ly + 2, 150, 25, 0, 0, 0, false)

        -- Reset Button (150x25) - Moved to Finish's old spot (Right Bottom)
        local resetReady = (p.stagedEnergy or 0) > 0
        ui.addTextArea(FOUNTAIN_TEXT + 3, "", name, bx, by + 40, 150, 25, 0x070707, resetReady and 0xFF4D4D or 0x333333, 0.5, false)
        local resetLink = resetReady and "<a href='event:val_reset'>" or ""
        local resetLinkEnd = resetReady and "</a>" or ""
        ui.addTextArea(FOUNTAIN_TEXT + 30, "<p align='center'>"..resetLink.."<font color='"..(resetReady and "#FF4D4D" or "#555555").."' size='11'>" .. translatedMessage("val_ui_remove_all", name) .. "</font>"..resetLinkEnd.."</p>", name, bx, by + 42, 150, 25, 0, 0, 0, false)
        
        -- Finish Button (150x25) - Moved to Left Bottom (Under Add All)
        local craftReady = (p.energy + (p.stagedEnergy or 0)) >= valentine.targetGoal
        local bgColor = craftReady and 0x00331A or 0x070707
        local borderColor = craftReady and 0x00FF88 or 0x333333
        local textColor = craftReady and "#00FF88" or "#555555"
        local craftLink = craftReady and "<a href='event:val_craft'>" or ""
        local craftLinkEnd = craftReady and "</a>" or ""

        ui.addTextArea(FOUNTAIN_TEXT + 4, "", name, lx, ly + 40, 150, 25, bgColor, borderColor, craftReady and 0.8 or 0.5, false)
        ui.addTextArea(FOUNTAIN_TEXT + 40, "<p align='center'>" .. craftLink .. "<font color='" .. textColor .. "' size='12'><b>" .. (translatedMessage("val_ui_finish", name) or "Bitir") .. "</b></font>" .. craftLinkEnd .. "</p>", name, lx, ly + 42, 150, 25, 0, 0, 0, false)
    end
    
    function fountain.hide(name)
        local p = getValData(name)
        if p then 
            p.uiOpen = false 
            if p.uiImgIds then
                for i, id in pairs(p.uiImgIds) do
                    tfm.exec.removeImage(id)
                end
                p.uiImgIds = {}
            end
        end
        isOpenFountain[name] = nil
        ui.removeTextArea(FOUNTAIN_BG, name)
        ui.removeTextArea(FOUNTAIN_BG - 1, name)
        ui.removeTextArea(FOUNTAIN_BG - 2, name)
        for i = 0, 80 do
            ui.removeTextArea(FOUNTAIN_TEXT + i, name)
        end
        ui.removeTextArea(FOUNTAIN_STATS_BG, name)
        ui.removeTextArea(FOUNTAIN_STATS_TXT, name)
    end
    
    return {
        gifting = gifting,
        fountain = fountain
    }
end
