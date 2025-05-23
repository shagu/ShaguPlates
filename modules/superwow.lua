-- Compatibility layer to use castbars provided by SuperWoW:
-- https://github.com/balakethelock/SuperWoW

ShaguPlates:RegisterModule("superwow", "vanilla", function ()
  if SetAutoloot and SpellInfo and not SUPERWOW_VERSION then
    -- Turn every enchanting link that we create in the enchanting frame,
    -- from "spell:" back into "enchant:". The enchant-version is what is
    -- used by all unmodified game clients. This is required to generate
    -- usable links for everyone from the enchant frame while having SuperWoW.
    local HookGetCraftItemLink = GetCraftItemLink
    _G.GetCraftItemLink = function(index)
      local link = HookGetCraftItemLink(index)
      return string.gsub(link, "spell:", "enchant:")
    end

    -- Convert every enchanting link that we receive into a
    -- spell link, as for some reason SuperWoW can't handle
    -- enchanting links at all and requires it to be a spell.
    local HookSetItemRef = SetItemRef
    _G.SetItemRef = function(link, text, button)
      link = string.gsub(link, "enchant:", "spell:")
      HookSetItemRef(link, text, button)
    end

    local HookGameTooltipSetHyperlink = GameTooltip.SetHyperlink
    _G.GameTooltip.SetHyperlink = function(self, link)
      link = string.gsub(link, "enchant:", "spell:")
      HookGameTooltipSetHyperlink(self, link)
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cffffffaaAn old version of SuperWoW was detected. Please consider updating:")
    DEFAULT_CHAT_FRAME:AddMessage("-> https://github.com/balakethelock/SuperWoW/releases/")
  end

  if SUPERWOW_VERSION == "1.5" then
    QueueFunction(function()
      local pfCombatText_AddMessage = _G.CombatText_AddMessage
      _G.CombatText_AddMessage = function(message, a, b, c, d, e, f)
        local match, _, hex = string.find(message, ".+ %[(0x.+)%]")
        if hex and UnitName(hex) then
          message = string.gsub(message, hex, UnitName(hex))
        end

        pfCombatText_AddMessage(message, a, b, c, d, e, f)
      end
    end)
  end

  -- Add support for guid based focus frame
  if SUPERWOW_VERSION and ShaguPlates.uf and ShaguPlates.uf.focus then
    local focus = function(unitstr)
      -- try to read target's unit guid
      local _, guid = UnitExists(unitstr)

      if guid and ShaguPlates.uf.focus then
        -- update focus frame
        ShaguPlates.uf.focus.unitname = nil
        ShaguPlates.uf.focus.label = guid
        ShaguPlates.uf.focus.id = ""

        -- update focustarget frame
        ShaguPlates.uf.focustarget.unitname = nil
        ShaguPlates.uf.focustarget.label = guid .. "target"
        ShaguPlates.uf.focustarget.id = ""
      end

      return guid
    end

    -- extend the builtin /focus slash command
    local legacyfocus = SlashCmdList.PFFOCUS
    function SlashCmdList.PFFOCUS(msg)
      -- try to perform guid based focus
      local guid = focus("target")

      -- run old focus emulation
      if not guid then legacyfocus(msg) end
    end

    -- extend the builtin /swapfocus slash command
    local legacyswapfocus = SlashCmdList.PFSWAPFOCUS
    function SlashCmdList.PFSWAPFOCUS(msg)
      -- save previous focus values
      local oldlabel = ShaguPlates.uf.focus.label or ""
      local oldid = ShaguPlates.uf.focus.id or ""

      -- try to perform guid based focus
      local guid = focus("target")

      -- target old focus
      if guid and oldlabel and oldid then
        TargetUnit(oldlabel..oldid)
      end

      -- run old focus emulation
      if not guid then legacyswapfocus(msg) end
    end
  end

  local unitcast = CreateFrame("Frame")
  unitcast:RegisterEvent("UNIT_CASTEVENT")
  unitcast:SetScript("OnEvent", function()
    if arg3 == "START" or arg3 == "CAST" or arg3 == "CHANNEL" then
      -- human readable argument list
      local guid = arg1
      local target = arg2
      local event_type = arg3
      local spell_id = arg4
      local timer = arg5
      local start = GetTime()

      -- get spell info from spell id
      local spell, icon, _
      if SpellInfo and SpellInfo(spell_id) then
        spell, _, icon = SpellInfo(spell_id)
      end

      -- set fallback values
      spell = spell or UNKNOWN
      icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"

      -- skip on buff procs during cast
      if event_type == "CAST" then
        if not libcast.db[guid] or libcast.db[guid].cast ~= spell then
          -- ignore casts without 'START' event, while there is already another cast.
          -- those events can be for example a frost shield proc while casting frostbolt.
          -- we want to keep the cast itself, so we simply skip those.
          return
        end
      end

      -- add cast action to the database
      if not libcast.db[guid] then libcast.db[guid] = {} end
      libcast.db[guid].cast = spell
      libcast.db[guid].rank = nil
      libcast.db[guid].start = GetTime()
      libcast.db[guid].casttime = timer
      libcast.db[guid].icon = icon
      libcast.db[guid].channel = event_type == "CHANNEL" or false

      -- write state variable
      superwow_active = true
    elseif arg3 == "FAIL" then
      local guid = arg1

      -- delete all cast entries of guid
      if libcast.db[guid] then
        libcast.db[guid].cast = nil
        libcast.db[guid].rank = nil
        libcast.db[guid].start = nil
        libcast.db[guid].casttime = nil
        libcast.db[guid].icon = nil
        libcast.db[guid].channel = nil
      end
    end
  end)
end)
