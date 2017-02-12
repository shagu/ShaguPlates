-- create frame
pfNameplates = CreateFrame("Frame", nil, UIParent)
pfNameplates:RegisterEvent("PLAYER_TARGET_CHANGED")
pfNameplates:RegisterEvent("UNIT_AURA")

-- temporary data per session
pfNameplates.mobs = {}
pfNameplates.targets = {}
pfNameplates.players = {}

function round(input, places)
  if not places then places = 0 end
  if type(input) == "number" and type(places) == "number" then
    local pow = 1
    for i = 1, places do pow = pow * 10 end
    return floor(input * pow + 0.5) / pow
  end
end

pfNameplates:SetScript("OnEvent", function()
    -- current debuffs
    pfNameplates.debuffs = {}
    local i = 1
    local debuff = UnitDebuff("target", i)
    while debuff do
      pfNameplates.debuffs[i] = debuff
      i = i + 1
      debuff = UnitDebuff("target", i)
    end

    -- scan player (target)
    if UnitName("target") ~= nil and pfNameplates.players[UnitName("target")] == nil and pfNameplates.targets[UnitName("target")] == nil then
      if UnitIsPlayer("target") then
        local _, class = UnitClass("target")
        pfNameplates.players[UnitName("target")] = {}
        pfNameplates.players[UnitName("target")]["class"] = class
      elseif UnitClassification("target") ~= "normal" then
        local elite = UnitClassification("target")
        pfNameplates.mobs[UnitName("target")] = elite
      end
      pfNameplates.targets[UnitName("target")] = "OK"
    end
end)

-- combat tracker
pfNameplates.combat = CreateFrame("Frame")
pfNameplates.combat:RegisterEvent("PLAYER_ENTER_COMBAT")
pfNameplates.combat:RegisterEvent("PLAYER_LEAVE_COMBAT")
pfNameplates.combat:SetScript("OnEvent", function()
  if event == "PLAYER_ENTER_COMBAT" then
    this.inCombat = 1
  elseif event == "PLAYER_LEAVE_COMBAT" then
    this.inCombat = nil
  end
end)

-- emulate a rightclick detection even if the mouselooking has been started
pfNameplates.emulateRightClick = CreateFrame("Frame", nil, UIParent)
pfNameplates.emulateRightClick.time = nil
pfNameplates.emulateRightClick.frame = nil
pfNameplates.emulateRightClick:SetScript("OnUpdate", function()
  -- break here if nothing to do
  if not pfNameplates.emulateRightClick.time or not pfNameplates.emulateRightClick.frame then
    this:Hide()
    return
  end

  -- if threshold is reached (0.3 second) no click action will follow
  if not IsMouselooking() and pfNameplates.emulateRightClick.time + 0.3 < GetTime() then
    pfNameplates.emulateRightClick:Hide()
    return
  end

  -- run a usual nameplate rightclick action
  if not IsMouselooking() then
    pfNameplates.emulateRightClick.frame:Click("LeftButton")
    if UnitCanAttack("player", "target") and not pfNameplates.combat.inCombat then AttackTarget() end
    pfNameplates.emulateRightClick:Hide()
    return
  end
end)

pfNameplates:SetScript("OnUpdate", function()
  local frames = { WorldFrame:GetChildren() }
  for _, nameplate in ipairs(frames) do
    local regions = nameplate:GetRegions()
    if regions and regions:GetObjectType() == "Texture" and regions:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" then
      local healthbar = nameplate:GetChildren()
      local border, glow, name, level, levelicon , raidicon = nameplate:GetRegions()

      -- hide default plates
      border:Hide()

      -- try to avoid flickering as much as possible
      glow:Hide()
      glow:SetAlpha(0)
      glow.Show = function() return end

      if pfNameplates_config.onlyplayers == 1 then
        if not pfNameplates.players[name:GetText()] or not pfNameplates.players[name:GetText()]["class"] then
          nameplate:Hide()
        end
      end

      -- scan player (idle targeting)
      if pfNameplates.targets[name:GetText()] == nil and UnitName("target") == nil then
        TargetByName(name:GetText(), true)
        if UnitIsPlayer("target") then
          local _, class = UnitClass("target")
          pfNameplates.players[name:GetText()] = {}
          pfNameplates.players[name:GetText()]["class"] = class
        elseif UnitClassification("target") ~= "normal" then
          local elite = UnitClassification("target")
          pfNameplates.mobs[name:GetText()] = elite
        end
        pfNameplates.targets[name:GetText()] = "OK"
        ClearTarget()
      end

      -- scan player (mouseover)
      if pfNameplates.players[name:GetText()] == nil and UnitName("mouseover") == name:GetText() and pfNameplates.targets[name:GetText()] == nil then
        if UnitIsPlayer("mouseover") then
          local _, class = UnitClass("mouseover")
          pfNameplates.players[name:GetText()] = {}
          pfNameplates.players[name:GetText()]["class"] = class
        elseif UnitClassification("mouseover") ~= "normal" then
          local elite = UnitClassification("mouseover")
          pfNameplates.mobs[name:GetText()] = elite
        end
        pfNameplates.targets[name:GetText()] = "OK"
      end

      -- enable clickthrough
      if pfNameplates_config.clickthrough == 1 then
        nameplate:EnableMouse(false)
      else
        nameplate:EnableMouse(true)
        if pfNameplates_config.mouselook == 1 then
          nameplate:SetScript("OnMouseDown", function()
            if arg1 and arg1 == "RightButton" then
              MouselookStart()

              -- start detection of the rightclick emulation
              pfNameplates.emulateRightClick.time = GetTime()
              pfNameplates.emulateRightClick.frame = this
              pfNameplates.emulateRightClick:Show()
            end
          end)
        end
      end

      -- healthbar
      healthbar:SetStatusBarTexture("Interface\\AddOns\\ShaguPlates\\img\\bar")
      healthbar:ClearAllPoints()
      healthbar:SetPoint("TOP", nameplate, "TOP", 0, pfNameplates_config.vertical_pos)
      healthbar:SetWidth(110)
      healthbar:SetHeight(7)

      if healthbar.bg == nil then
        healthbar.bg = healthbar:CreateTexture(nil, "BORDER")
        healthbar.bg:SetTexture(0,0,0,0.90)
        healthbar.bg:ClearAllPoints()
        healthbar.bg:SetPoint("CENTER", healthbar, "CENTER", 0, 0)
        healthbar.bg:SetWidth(healthbar:GetWidth() + 3)
        healthbar.bg:SetHeight(healthbar:GetHeight() + 3)
      end

      if pfNameplates_config.showhp == 1 then
        if healthbar.hptext == nil then
          healthbar.hptext = healthbar:CreateFontString("Status", "DIALOG", "GameFontNormal")
          healthbar.hptext:SetPoint("RIGHT", healthbar, "RIGHT")
          healthbar.hptext:SetNonSpaceWrap(false)
          healthbar.hptext:SetFontObject(GameFontWhite)
          healthbar.hptext:SetTextColor(1,1,1,1)
          healthbar.hptext:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\arial.ttf", 10)
        end

        local min, max = healthbar:GetMinMaxValues()
        local cur = healthbar:GetValue()
        healthbar.hptext:SetText(cur .. " / " .. max)
      end

      -- raidtarget
      raidicon:ClearAllPoints()
      raidicon:SetWidth(pfNameplates_config.raidiconsize)
      raidicon:SetHeight(pfNameplates_config.raidiconsize)
      raidicon:SetPoint("CENTER", healthbar, "CENTER", 0, -5)

      -- debuffs
      if nameplate.debuffs == nil then nameplate.debuffs = {} end
      for j=1, 16, 1 do
        if nameplate.debuffs[j] == nil then
          nameplate.debuffs[j] = nameplate:CreateTexture(nil, "BORDER")
          nameplate.debuffs[j]:SetTexture(0,0,0,0)
          nameplate.debuffs[j]:ClearAllPoints()
          nameplate.debuffs[j]:SetWidth(12)
          nameplate.debuffs[j]:SetHeight(12)
          if j == 1 then
            nameplate.debuffs[j]:SetPoint("TOPLEFT", healthbar, "BOTTOMLEFT", 0, -3)
          elseif j <= 8 then
            nameplate.debuffs[j]:SetPoint("LEFT", nameplate.debuffs[j-1], "RIGHT", 1, 0)
          elseif j > 8 then
            nameplate.debuffs[j]:SetPoint("TOPLEFT", nameplate.debuffs[1], "BOTTOMLEFT", (j-9) * 13, -1)
          end
        end
      end

      if pfNameplates_config.showdebuffs == 1 and UnitExists("target") and healthbar:GetAlpha() == 1 then
        local j = 1
        local k = 1
        for j, e in ipairs(pfNameplates.debuffs) do
          nameplate.debuffs[j]:SetTexture(pfNameplates.debuffs[j])
          nameplate.debuffs[j]:SetTexCoord(.078, .92, .079, .937)
          nameplate.debuffs[j]:SetAlpha(0.9)
          k = k + 1
        end
        for j = k, 16, 1 do
          nameplate.debuffs[j]:SetTexture(nil)
        end
      else
        for j = 1, 16, 1 do
          nameplate.debuffs[j]:SetTexture(nil)
        end
      end

      -- adjust font
      name:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\arial.ttf",12,"OUTLINE")
      name:SetPoint("BOTTOM", healthbar, "CENTER", 0, 7)
      level:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\arial.ttf",12, "OUTLINE")
      level:ClearAllPoints()
      level:SetPoint("RIGHT", healthbar, "LEFT", -1, 0)
      levelicon:ClearAllPoints()
      levelicon:SetPoint("RIGHT", healthbar, "LEFT", -1, 0)

      -- tweak the colors to match the rest
      local red, green, blue, _ = name:GetTextColor()
      if red > 0.99 and green == 0 and blue == 0 then
        name:SetTextColor(1,0.4,0.2,0.85)
      elseif red > 0.99 and green > 0.81 and green < 0.82 and blue == 0 then
        name:SetTextColor(1,1,1,0.85)
      end

      local red, green, blue, _ = level:GetTextColor()
      if red > 0.99 and green == 0 and blue == 0 then
        level:SetTextColor(1,0.4,0.2,0.85)
      elseif red > 0.99 and green > 0.81 and green < 0.82 and blue == 0 then
        level:SetTextColor(1,1,1,0.85)
      end

      -- adjust healthbar color
      local red, green, blue, _ = healthbar:GetStatusBarColor()

      if pfNameplates_config.blueshaman == 1 then
        RAID_CLASS_COLORS["SHAMAN"] = { r = 0.14, g = 0.35, b = 1.0, colorStr = "ff0070de" }
      end

      if red > 0.9 and green < 0.2 and blue < 0.2 then
        if pfNameplates_config.classcolor_enemy == 1 and pfNameplates.players[name:GetText()] and pfNameplates.players[name:GetText()]["class"] and RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]] then
          healthbar:SetStatusBarColor(
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].r,
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].g,
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].b,
            0.9)
        else
          healthbar:SetStatusBarColor(.9,.2,.3,0.8)
        end
      elseif red > 0.9 and green > 0.9 and blue < 0.2 then
        healthbar:SetStatusBarColor(1,1,.3,0.8)
      elseif blue > 0.9 and red == 0 and green == 0 then
        if pfNameplates_config.classcolor_friend == 1 and pfNameplates.players[name:GetText()] and pfNameplates.players[name:GetText()]["class"] and RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]] then
          healthbar:SetStatusBarColor(
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].r,
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].g,
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].b,
            0.9)
        else
          healthbar:SetStatusBarColor(0.2,0.6,1,0.8)
        end
      elseif red == 0 and green > 0.99 and blue == 0 then
        healthbar:SetStatusBarColor(0.6,1,0,0.8)
      end

      -- show indicator for elite/rare mobs
      if level:GetText() ~= nil then
        if pfNameplates.mobs[name:GetText()] and pfNameplates.mobs[name:GetText()] == "elite" and not string.find(level:GetText(), "+") then
          level:SetText(level:GetText() .. "+")
        elseif pfNameplates.mobs[name:GetText()] and pfNameplates.mobs[name:GetText()] == "rareelite" and not string.find(level:GetText(), "R+") then
          level:SetText(level:GetText() .. "R+")
        elseif pfNameplates.mobs[name:GetText()] and pfNameplates.mobs[name:GetText()] == "rare" and not string.find(level:GetText(), "R") then
          level:SetText(level:GetText() .. "R")
        end
      end

      -- show castbar
      if pfNameplates_config.showcastbar == 1 and pfCastbar.casterDB[name:GetText()] ~= nil and pfCastbar.casterDB[name:GetText()]["cast"] ~= nil then

        -- create frames
        if healthbar.castbar == nil then
          healthbar.castbar = CreateFrame("StatusBar", nil, healthbar)
          healthbar.castbar:SetWidth(110)
          healthbar.castbar:SetHeight(7)
          healthbar.castbar:SetPoint("TOPLEFT", healthbar, "BOTTOMLEFT", 0, -5)
          healthbar.castbar:SetBackdrop({  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
                                  insets = {left = -1, right = -1, top = -1, bottom = -1} })
          healthbar.castbar:SetBackdropColor(0,0,0,1)
          healthbar.castbar:SetStatusBarTexture("Interface\\AddOns\\ShaguPlates\\img\\bar")
          healthbar.castbar:SetStatusBarColor(.9,.8,0,1)

          if healthbar.castbar.bg == nil then
            healthbar.castbar.bg = healthbar.castbar:CreateTexture(nil, "BACKGROUND")
            healthbar.castbar.bg:SetTexture(0,0,0,0.90)
            healthbar.castbar.bg:ClearAllPoints()
            healthbar.castbar.bg:SetPoint("CENTER", healthbar.castbar, "CENTER", 0, 0)
            healthbar.castbar.bg:SetWidth(healthbar.castbar:GetWidth() + 3)
            healthbar.castbar.bg:SetHeight(healthbar.castbar:GetHeight() + 3)
          end

          if healthbar.castbar.text == nil then
            healthbar.castbar.text = healthbar.castbar:CreateFontString("Status", "DIALOG", "GameFontNormal")
            healthbar.castbar.text:SetPoint("RIGHT", healthbar.castbar, "LEFT")
            healthbar.castbar.text:SetNonSpaceWrap(false)
            healthbar.castbar.text:SetFontObject(GameFontWhite)
            healthbar.castbar.text:SetTextColor(1,1,1,.5)
            healthbar.castbar.text:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\arial.ttf", 10, "OUTLINE")
          end

          if healthbar.castbar.spell == nil then
            healthbar.castbar.spell = healthbar.castbar:CreateFontString("Status", "DIALOG", "GameFontNormal")
            healthbar.castbar.spell:SetPoint("CENTER", healthbar.castbar, "CENTER")
            healthbar.castbar.spell:SetNonSpaceWrap(false)
            healthbar.castbar.spell:SetFontObject(GameFontWhite)
            healthbar.castbar.spell:SetTextColor(1,1,1,1)
            healthbar.castbar.spell:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\arial.ttf", 10, "OUTLINE")
          end

          if healthbar.castbar.icon == nil then
            healthbar.castbar.icon = healthbar.castbar:CreateTexture(nil, "BORDER")
            healthbar.castbar.icon:ClearAllPoints()
            healthbar.castbar.icon:SetPoint("BOTTOMLEFT", healthbar.castbar, "BOTTOMRIGHT", 5, 0)
            healthbar.castbar.icon:SetWidth(18)
            healthbar.castbar.icon:SetHeight(18)
          end

          if healthbar.castbar.icon.bg == nil then
            healthbar.castbar.icon.bg = healthbar.castbar:CreateTexture(nil, "BACKGROUND")
            healthbar.castbar.icon.bg:SetTexture(0,0,0,0.90)
            healthbar.castbar.icon.bg:ClearAllPoints()
            healthbar.castbar.icon.bg:SetPoint("CENTER", healthbar.castbar.icon, "CENTER", 0, 0)
            healthbar.castbar.icon.bg:SetWidth(healthbar.castbar.icon:GetWidth() + 3)
            healthbar.castbar.icon.bg:SetHeight(healthbar.castbar.icon:GetHeight() + 3)
          end
        end

        if pfCastbar.casterDB[name:GetText()]["starttime"] + pfCastbar.casterDB[name:GetText()]["casttime"] <= GetTime() then
          pfCastbar.casterDB[name:GetText()] = nil
          healthbar.castbar:Hide()
        else
          healthbar.castbar:SetMinMaxValues(0,  pfCastbar.casterDB[name:GetText()]["casttime"])
          healthbar.castbar:SetValue(GetTime() -  pfCastbar.casterDB[name:GetText()]["starttime"])
          healthbar.castbar.text:SetText(round( pfCastbar.casterDB[name:GetText()]["starttime"] +  pfCastbar.casterDB[name:GetText()]["casttime"] - GetTime(),1))
          if healthbar.castbar.spell then
            if pfNameplates_config.showcasttext == 1 then
              healthbar.castbar.spell:SetText(pfCastbar.casterDB[name:GetText()]["cast"])
            else
              healthbar.castbar.spell:SetText("")
            end
          end
          healthbar.castbar:Show()
          nameplate.debuffs[1]:SetPoint("TOPLEFT", healthbar.castbar, "BOTTOMLEFT", 0, -3)

          if pfCastbar.casterDB[name:GetText()]["icon"] then
            healthbar.castbar.icon:SetTexture("Interface\\Icons\\" ..  pfCastbar.casterDB[name:GetText()]["icon"])
            healthbar.castbar.icon:SetTexCoord(.1,.9,.1,.9)
          end
        end
      elseif healthbar.castbar then
        healthbar.castbar:Hide()
        nameplate.debuffs[1]:SetPoint("TOPLEFT", healthbar, "BOTTOMLEFT", 0, -3)
      end
    end
  end
end)
