  -- [[ compat
  local L = pfUI_locale[GetLocale()] or pfUI_locale["enUS"]
  local function round(input, places)
    if not places then places = 0 end
    if type(input) == "number" and type(places) == "number" then
      local pow = 1
      for i = 1, places do pow = pow * 10 end
      return floor(input * pow + 0.5) / pow
    end
  end
  -- ]]

  local font = "Interface\\AddOns\\ShaguPlates\\fonts\\arial.ttf"

  pfNameplates = CreateFrame("Frame", nil, UIParent)
  pfNameplates.players = {}
  pfNameplates.mobs = {}
  pfNameplates.targets = {}
  pfNameplates.scanqueue = {}

  -- catch all nameplates
  pfNameplates.scanner = CreateFrame("Frame", "pfNameplateScanner", UIParent)
  pfNameplates.scanner.parentCount = 0
  pfNameplates.scanner:SetScript("OnUpdate", function()
    local parentCount = WorldFrame:GetNumChildren()

    -- [[ scan nameplate frames ]]
    if pfNameplates.scanner.parentCount < parentCount then
      pfNameplates.scanner.parentCount = parentCount

      for _, nameplate in ipairs({WorldFrame:GetChildren()}) do
        if not nameplate.done and nameplate:GetObjectType() == "Button" then
          local regions = nameplate:GetRegions()
          if regions and regions:GetObjectType() == "Texture" and regions:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" then

            local visible = nameplate:IsVisible()
            nameplate:Hide()
            nameplate:SetScript("OnShow", pfNameplates.OnShow)
            nameplate:SetScript("OnUpdate", pfNameplates.OnUpdate)
            nameplate:SetAlpha(1)
            if visible then nameplate:Show() end
            nameplate.done = true
          end
        end
      end
    end

    -- [[ scan missing names ]]
    for index, name in pairs(pfNameplates.scanqueue) do
      -- remove entry if already scanned
      if pfNameplates.targets[name] == "OK" then
        table.remove(pfNameplates.scanqueue, index)
      else
        if UnitName("mouseover") == name then
          if UnitIsPlayer("mouseover") then
            local _, class = UnitClass("mouseover")
            pfNameplates.players[name] = {}
            pfNameplates.players[name]["class"] = class
          elseif UnitClassification("mouseover") then
            local elite = UnitClassification("mouseover")
            pfNameplates.mobs[name] = elite
          end
          pfNameplates.targets[name] = "OK"

        elseif not UnitName("target") then
          TargetByName(name, true)

          if UnitIsPlayer("target") then
            local _, class = UnitClass("target")
            pfNameplates.players[name] = {}
            pfNameplates.players[name]["class"] = class
          elseif UnitClassification("target") then
            local elite = UnitClassification("target")
            pfNameplates.mobs[name] = elite
          end
          pfNameplates.targets[name] = "OK"

          ClearTarget()
        end
      end
    end
  end)

  -- Create Nameplate
  function pfNameplates:OnShow()
    -- initialize nameplate frames
    if not this.nameplate then
      this.nameplate = CreateFrame("Button", nil, this)
      this.nameplate.parent = this
      this.healthbar = this:GetChildren()
      this.border, this.glow, this.name, this.level, this.levelicon , this.raidicon = this:GetRegions()

      this.healthbar:SetParent(this.nameplate)
      this.border:SetParent(this.nameplate)
      this.glow:SetParent(this.nameplate)
      this.name:SetParent(this.nameplate)
      this.level:SetParent(this.nameplate)
      this.levelicon:SetParent(this.nameplate)
      this.raidicon:SetParent(this.healthbar)
    end

    -- init
    this:SetFrameLevel(0)
    this:EnableMouse(false)

    -- enable plate overlap
    if pfNameplates_config.overlap == "1" then
      this:SetWidth(1)
      this:SetHeight(1)
    else
      this:SetWidth(pfNameplates_config.width + 50 * UIParent:GetScale())
      this:SetHeight(pfNameplates_config.heighthealth + pfNameplates_config.fontsize + 5 * UIParent:GetScale())
    end

    -- set dimensions
    this.nameplate:SetScale(UIParent:GetScale())
    this.nameplate:SetWidth(pfNameplates_config.width + 50)
    this.nameplate:SetHeight(pfNameplates_config.heighthealth + pfNameplates_config.fontsize + 5)
    this.nameplate:SetPoint("TOP", this, "TOP", 0, -tonumber(pfNameplates_config.vpos))

    -- add click handlers
    if pfNameplates_config["clickthrough"] == "0" then
      this.nameplate:SetScript("OnClick", function() this.parent:Click() end)
      if pfNameplates_config["rightclick"] == "1" then
        this.nameplate:SetScript("OnMouseDown", function()
          if arg1 and arg1 == "RightButton" then
            MouselookStart()

            -- start detection of the rightclick emulation
            pfNameplates.emulateRightClick.time = GetTime()
            pfNameplates.emulateRightClick.frame = this
            pfNameplates.emulateRightClick:Show()
          end
        end)
      end
    else
      this.nameplate:EnableMouse(false)
    end

    -- hide default plates
    this.border:Hide()

    -- remove glowing
    this.glow:Hide()
    this.glow:SetAlpha(0)
    this.glow.Show = function() return end

    -- name
    this.name:SetFont(font, pfNameplates_config.fontsize, "OUTLINE")
    this.name:ClearAllPoints()
    this.name:SetPoint("TOP", this.nameplate, "TOP", 0, 0)

    -- healthbar
    this.healthbar:SetStatusBarTexture("Interface\\AddOns\\ShaguPlates\\img\\bar")
    this.healthbar:ClearAllPoints()
    this.healthbar:SetPoint("TOP", this.name, "BOTTOM", 0, -3)
    this.healthbar:SetWidth(pfNameplates_config.width)
    this.healthbar:SetHeight(pfNameplates_config.heighthealth)

    if not this.healthbar.bg then
      this.healthbar.bg = this.healthbar:CreateTexture(nil, "BORDER")
      this.healthbar.bg:SetTexture(0,0,0,0.90)
      this.healthbar.bg:ClearAllPoints()
      this.healthbar.bg:SetPoint("CENTER", this.healthbar, "CENTER", 0, 0)
      this.healthbar.bg:SetWidth(this.healthbar:GetWidth() + 3)
      this.healthbar.bg:SetHeight(this.healthbar:GetHeight() + 3)
    end

    this.healthbar.reaction = nil

    -- level
    this.level:SetFont(font, pfNameplates_config.fontsize, "OUTLINE")
    this.level:ClearAllPoints()
    this.level:SetPoint("RIGHT", this.healthbar, "LEFT", 0, 0)
    this.level.needUpdate = true
    this.healthbar.needReactionUpdate = true

    -- adjust font
    this.levelicon:ClearAllPoints()
    this.levelicon:SetPoint("RIGHT", this.healthbar, "LEFT", -1, 0)

    -- raidtarget
    this.raidicon:ClearAllPoints()
    this.raidicon:SetWidth(pfNameplates_config.raidiconsize)
    this.raidicon:SetHeight(pfNameplates_config.raidiconsize)
    this.raidicon:SetPoint("CENTER", this.healthbar, "CENTER", 0, -5)
    this.raidicon:SetDrawLayer("OVERLAY")

    -- add debuff frames
    if pfNameplates_config["showdebuffs"] == "1" then
      if not this.debuffs then this.debuffs = {} end
      for j=1, 16, 1 do
        if this.debuffs[j] == nil then
          this.debuffs[j] = CreateFrame("Frame", nil, this.nameplate)
          this.debuffs[j]:ClearAllPoints()
          this.debuffs[j]:SetWidth(18)
          this.debuffs[j]:SetHeight(18)
          if j == 1 then
            this.debuffs[j]:SetPoint("TOPLEFT", this.healthbar, "BOTTOMLEFT", 0, -3)
          elseif j <= 8 then
            this.debuffs[j]:SetPoint("LEFT", this.debuffs[j-1], "RIGHT", 1, 0)
          elseif j > 8 then
            this.debuffs[j]:SetPoint("TOPLEFT", this.debuffs[j-8], "BOTTOMLEFT", 0, -1)
          end

          this.debuffs[j].icon = this.debuffs[j]:CreateTexture(nil, "BORDER")
          this.debuffs[j].icon:SetTexture(0,0,0,0)
          this.debuffs[j].icon:SetAllPoints(this.debuffs[j])
        end
      end
    end

    -- add castbar
    if pfCastbar and pfNameplates_config["showcastbar"] == "1" then
      local plate = this

      if not this.healthbar.castbar then
        this.healthbar.castbar = CreateFrame("StatusBar", nil, this.healthbar)
        this.healthbar.castbar:Hide()
        this.healthbar.castbar:SetWidth(this.healthbar:GetWidth())
        this.healthbar.castbar:SetHeight(pfNameplates_config.heightcast)
        this.healthbar.castbar:SetPoint("TOPLEFT", this.healthbar, "BOTTOMLEFT", 0, -5)
        this.healthbar.castbar:SetBackdrop({  bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
                                               insets = {left = -1, right = -1, top = -1, bottom = -1} })
        this.healthbar.castbar:SetBackdropColor(0,0,0,1)
        this.healthbar.castbar:SetStatusBarTexture("Interface\\AddOns\\ShaguPlates\\img\\bar")
        this.healthbar.castbar:SetStatusBarColor(.9,.8,0,1)

        plate.healthbar.castbar:SetScript("OnShow", function()
          plate:SetHeight(pfNameplates_config.heighthealth + pfNameplates_config.fontsize + 5 + pfNameplates_config.heightcast + 5 * UIParent:GetScale())
          plate.nameplate:SetHeight(pfNameplates_config.heighthealth + pfNameplates_config.fontsize + 5 + pfNameplates_config.heightcast + 5)

          if plate.debuffs then
            plate.debuffs[1]:SetPoint("TOPLEFT", plate.healthbar.castbar, "BOTTOMLEFT", 0, -3)
          end
        end)

        this.healthbar.castbar:SetScript("OnHide", function()
          plate:SetHeight(pfNameplates_config.heighthealth + pfNameplates_config.fontsize + 5 * UIParent:GetScale())
          plate.nameplate:SetHeight(pfNameplates_config.heighthealth + pfNameplates_config.fontsize + 5)

          if plate.debuffs then
            plate.debuffs[1]:SetPoint("TOPLEFT", plate.healthbar, "BOTTOMLEFT", 0, -3)
          end
        end)

        this.healthbar.castbar.bg = this.healthbar.castbar:CreateTexture(nil, "BACKGROUND")
        this.healthbar.castbar.bg:SetTexture(0,0,0,0.90)
        this.healthbar.castbar.bg:ClearAllPoints()
        this.healthbar.castbar.bg:SetPoint("CENTER", this.healthbar.castbar, "CENTER", 0, 0)
        this.healthbar.castbar.bg:SetWidth(this.healthbar.castbar:GetWidth() + 3)
        this.healthbar.castbar.bg:SetHeight(this.healthbar.castbar:GetHeight() + 3)

        this.healthbar.castbar.text = this.healthbar.castbar:CreateFontString("Status", "DIALOG", "GameFontNormal")
        this.healthbar.castbar.text:SetPoint("RIGHT", this.healthbar.castbar, "LEFT")
        this.healthbar.castbar.text:SetNonSpaceWrap(false)
        this.healthbar.castbar.text:SetFontObject(GameFontWhite)
        this.healthbar.castbar.text:SetTextColor(1,1,1,.5)
        this.healthbar.castbar.text:SetFont(font, pfNameplates_config.fontsize, "OUTLINE")

        this.healthbar.castbar.spell = this.healthbar.castbar:CreateFontString("Status", "DIALOG", "GameFontNormal")
        this.healthbar.castbar.spell:SetPoint("CENTER", this.healthbar.castbar, "CENTER")
        this.healthbar.castbar.spell:SetNonSpaceWrap(false)
        this.healthbar.castbar.spell:SetFontObject(GameFontWhite)
        this.healthbar.castbar.spell:SetTextColor(1,1,1,1)
        this.healthbar.castbar.spell:SetFont(font, pfNameplates_config.fontsize, "OUTLINE")

        this.healthbar.castbar.icon = this.healthbar.castbar:CreateTexture(nil, "BORDER")
        this.healthbar.castbar.icon:ClearAllPoints()
        this.healthbar.castbar.icon:SetPoint("BOTTOMLEFT", this.healthbar.castbar, "BOTTOMRIGHT", 5, 0)
        this.healthbar.castbar.icon:SetWidth(pfNameplates_config.heightcast + 5 + pfNameplates_config.heighthealth)
        this.healthbar.castbar.icon:SetHeight(pfNameplates_config.heightcast + 5 + pfNameplates_config.heighthealth)

        this.healthbar.castbar.icon.bg = this.healthbar.castbar:CreateTexture(nil, "BACKGROUND")
        this.healthbar.castbar.icon.bg:SetTexture(0,0,0,0.90)
        this.healthbar.castbar.icon.bg:ClearAllPoints()
        this.healthbar.castbar.icon.bg:SetPoint("CENTER", this.healthbar.castbar.icon, "CENTER", 0, 0)
        this.healthbar.castbar.icon.bg:SetWidth(this.healthbar.castbar.icon:GetWidth() + 3)
        this.healthbar.castbar.icon.bg:SetHeight(this.healthbar.castbar.icon:GetHeight() + 3)
      end
    end

    if pfNameplates_config.showhp == "1" and not this.healthbar.hptext then
      this.healthbar.hptext = this.healthbar:CreateFontString("Status", "DIALOG", "GameFontNormal")
      this.healthbar.hptext:SetPoint("RIGHT", this.healthbar, "RIGHT")
      this.healthbar.hptext:SetNonSpaceWrap(false)
      this.healthbar.hptext:SetFontObject(GameFontWhite)
      this.healthbar.hptext:SetTextColor(1,1,1,1)
      this.healthbar.hptext:SetFont(font, pfNameplates_config.fontsize)
    end

    if pfNameplates_config.players == "1" then
      if pfNameplates.targets[this.name:GetText()] == "OK" then
        if not pfNameplates.players[this.name:GetText()] then this:Hide() end
      end
    end

    this.needNameUpdate = true
    this.needClassColorUpdate = true
    this.needLevelColorUpdate = true
    this.needEliteUpdate = true

    this.setup = true
  end

  -- Nameplate OnUpdate
  function pfNameplates:OnUpdate()
    if not this.setup then pfNameplates:OnShow() return end

    local healthbar = this.healthbar
    local border, glow, name, level, levelicon , raidicon = this.border, this.glow, this.name, this.level, this.levelicon , this.raidicon

    -- add scan entry if not existing
    if this.needNameUpdate and name:GetText() ~= UNKNOWN then
      if not pfNameplates.targets[this.name:GetText()] then
        table.insert(pfNameplates.scanqueue, this.name:GetText())
      end
      this.needNameUpdate = nil
    end

    -- hide non-player frames
    if pfNameplates_config.players == "1" and not this.needNameUpdate then
      if pfNameplates.targets[name:GetText()] == "OK" then
        if not pfNameplates.players[name:GetText()] then this:Hide() end
      end
    end

    -- hide critters
    if pfNameplates_config.critters == "1" and not this.needNameUpdate then
      local red, green, blue, _ = healthbar:GetStatusBarColor()
      local name_val = name:GetText()
      for i, critter_val in pairs(L["critters"]) do
        if red > 0.9 and green > 0.9 and blue < 0.2 and name_val == critter_val then
          this:Hide()
        end
      end
    end

    -- level elite indicator
    if this.needEliteUpdate and pfNameplates.mobs[name:GetText()] then
      if level:GetText() ~= nil then
        if pfNameplates.mobs[name:GetText()] == "elite" then
          level:SetText(level:GetText() .. "+")
        elseif pfNameplates.mobs[name:GetText()] == "rareelite" then
          level:SetText(level:GetText() .. "R+")
        elseif pfNameplates.mobs[name:GetText()] == "rare" then
          level:SetText(level:GetText() .. "R")
        end
      end
      this.needEliteUpdate = nil
    end

    -- level colors
    if this.needLevelColorUpdate then
      local red, green, blue, _ = level:GetTextColor()
      if red > 0.99 and green == 0 and blue == 0 then
        level:SetTextColor(1,0.4,0.2,0.85)
      elseif red > 0.99 and green > 0.81 and green < 0.82 and blue == 0 then
        level:SetTextColor(1,1,1,0.85)
      end
      this.needLevelColorUpdate = nil
    end

    -- healtbar: update colors
    local red, green, blue, _ = healthbar:GetStatusBarColor()
    if red ~= healthbar.wantR or green ~= healthbar.wantG or blue ~= healthbar.wantB then
      -- set reaction color
      -- reaction: 0 enemy ; 1 neutral ; 2 player ; 3 npc
      if red > 0.9 and green < 0.2 and blue < 0.2 then
        healthbar.reaction = 0
        healthbar:SetStatusBarColor(.9,.2,.3,0.8)
      elseif red > 0.9 and green > 0.9 and blue < 0.2 then
        healthbar.reaction = 1
        healthbar:SetStatusBarColor(1,1,.3,0.8)
      elseif ( blue > 0.9 and red == 0 and green == 0 ) then
        healthbar.reaction = 2
        healthbar:SetStatusBarColor(0.2,0.6,1,0.8)
      elseif red == 0 and green > 0.99 and blue == 0 then
        healthbar.reaction = 3
        healthbar:SetStatusBarColor(0.6,1,0,0.8)
      end

      healthbar.wantR, healthbar.wantG, healthbar.wantB  = healthbar:GetStatusBarColor()
      this.needClassColorUpdate = true
    end

    -- add class colors
    if this.needClassColorUpdate and pfNameplates.targets[name:GetText()] == "OK" then
      -- show class names?
      if healthbar.reaction == 0 then
        if pfNameplates_config["enemyclassc"] == "1"
        and pfNameplates.players[name:GetText()]
        and pfNameplates.players[name:GetText()]["class"]
        and RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]]
        then
          healthbar:SetStatusBarColor(
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].r,
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].g,
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].b,
            0.9)
        end
      elseif healthbar.reaction == 2 then
        if pfNameplates_config["friendclassc"] == "1"
        and pfNameplates.players[name:GetText()]
        and pfNameplates.players[name:GetText()]["class"]
        and RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]]
        then
          healthbar:SetStatusBarColor(
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].r,
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].g,
            RAID_CLASS_COLORS[pfNameplates.players[name:GetText()]["class"]].b,
            0.9)
        end
      end

      healthbar.wantR, healthbar.wantG, healthbar.wantB  = healthbar:GetStatusBarColor()
      this.needClassColorUpdate = nil
    end

    -- name color
    local red, green, blue, _ = name:GetTextColor()
    if red > 0.99 and green == 0 and blue == 0 then
      name:SetTextColor(1,0.4,0.2,0.85)
    elseif red > 0.99 and green > 0.81 and green < 0.82 and blue == 0 then
      name:SetTextColor(1,1,1,0.85)
    end

    -- show castbar
    if healthbar.castbar and pfCastbar and pfNameplates_config["showcastbar"] == "1" and pfCastbar.casterDB[name:GetText()] ~= nil and pfCastbar.casterDB[name:GetText()]["cast"] ~= nil then
      if pfCastbar.casterDB[name:GetText()]["starttime"] + pfCastbar.casterDB[name:GetText()]["casttime"] <= GetTime() then
        pfCastbar.casterDB[name:GetText()] = nil
        healthbar.castbar:Hide()
      else
        healthbar.castbar:SetMinMaxValues(0,  pfCastbar.casterDB[name:GetText()]["casttime"])
        healthbar.castbar:SetValue(GetTime() -  pfCastbar.casterDB[name:GetText()]["starttime"])
        healthbar.castbar.text:SetText(round( pfCastbar.casterDB[name:GetText()]["starttime"] +  pfCastbar.casterDB[name:GetText()]["casttime"] - GetTime(),1))
        if pfNameplates_config.spellname == "1" and healthbar.castbar.spell then
          healthbar.castbar.spell:SetText(pfCastbar.casterDB[name:GetText()]["cast"])
        else
          healthbar.castbar.spell:SetText("")
        end
        healthbar.castbar:Show()
        if this.debuffs then
          this.debuffs[1]:SetPoint("TOPLEFT", healthbar.castbar, "BOTTOMLEFT", 0, -3)
        end

        if pfCastbar.casterDB[name:GetText()]["icon"] then
          healthbar.castbar.icon:SetTexture("Interface\\Icons\\" ..  pfCastbar.casterDB[name:GetText()]["icon"])
          healthbar.castbar.icon:SetTexCoord(.1,.9,.1,.9)
        end
      end
    else
      if healthbar.castbar then
        healthbar.castbar:Hide()
      end

      if this.debuffs then
        this.debuffs[1]:SetPoint("TOPLEFT", healthbar, "BOTTOMLEFT", 0, -3)
      end
    end

    -- update debuffs
    if this.debuffs and pfNameplates.debuffs and pfNameplates_config["showdebuffs"] == "1" then
      if UnitExists("target") and healthbar:GetAlpha() == 1 then
        local j = 1
        local k = 1
        for j, e in ipairs(pfNameplates.debuffs) do
          local icon, name = unpack(pfNameplates.debuffs[j])
          this.debuffs[j]:Show()
          this.debuffs[j].icon:SetTexture(icon)
          this.debuffs[j].icon:SetTexCoord(.078, .92, .079, .937)

          k = k + 1
        end
        for j = k, 16, 1 do
          this.debuffs[j]:Hide()
        end
      elseif this.debuffs then
        for j = 1, 16, 1 do
          this.debuffs[j]:Hide()
        end
      end
    end

    -- show hp text
    if pfNameplates_config.showhp == "1" and healthbar.hptext then
      local min, max = healthbar:GetMinMaxValues()
      local cur = healthbar:GetValue()
      healthbar.hptext:SetText(cur .. " / " .. max)
    end
  end

  -- debuff detection
  local pfNameplateDebuffNameScan = CreateFrame('GameTooltip', "pfNameplateDebuffNameScan", UIParent, "GameTooltipTemplate")
  local function GetDebuffName(unit, index)
    pfNameplateDebuffNameScan:SetOwner(UIParent, "ANCHOR_NONE")
    pfNameplateDebuffNameScan:SetUnitDebuff(unit, index)
    local text = getglobal("pfNameplateDebuffNameScanTextLeft1")
    return ( text ) and text:GetText() or ""
  end

  pfNameplates:RegisterEvent("PLAYER_TARGET_CHANGED")
  pfNameplates:RegisterEvent("UNIT_AURA")
  pfNameplates:SetScript("OnEvent", function()
    if not arg1 or arg1 == "target" then
      pfNameplates.debuffs = {}
      for i = 1, 16 do
        if not UnitDebuff("target", i) then return end
        local debuff = UnitDebuff("target", i)
        pfNameplates.debuffs[i] = { debuff, "" }
      end
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

  -- emulate fake rightclick
  pfNameplates.emulateRightClick = CreateFrame("Frame", nil, UIParent)
  pfNameplates.emulateRightClick.time = nil
  pfNameplates.emulateRightClick.frame = nil
  pfNameplates.emulateRightClick:SetScript("OnUpdate", function()
    -- break here if nothing to do
    if not pfNameplates.emulateRightClick.time or not pfNameplates.emulateRightClick.frame then
      this:Hide()
      return
    end

    -- if threshold is reached (0.5 second) no click action will follow
    if not IsMouselooking() and pfNameplates.emulateRightClick.time + tonumber(pfNameplates_config["clickthreshold"]) < GetTime() then
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
