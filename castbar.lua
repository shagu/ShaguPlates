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

  pfCastbar = CreateFrame("Frame", "pfTargetCastbar", UIParent)

  pfCastbar.SPELL_CAST = string.gsub(string.gsub(SPELLCASTOTHERSTART,"%d%$",""), "%%s", "(.+)")
  pfCastbar.SPELL_PERFORM = string.gsub(string.gsub(SPELLPERFORMOTHERSTART,"%d%$",""), "%%s", "(.+)")
  pfCastbar.SPELL_GAINS = string.gsub(string.gsub(AURAADDEDOTHERHELPFUL,"%d%$",""), "%%s", "(.+)")
  pfCastbar.SPELL_AFFLICTED = string.gsub(string.gsub(AURAADDEDOTHERHARMFUL,"%d%$",""), "%%s", "(.+)")
  pfCastbar.SPELL_HIT = string.gsub(string.gsub(string.gsub(SPELLLOGSELFOTHER,"%d%$",""),"%%d","%%d+"),"%%s","(.+)")
  pfCastbar.SPELL_CRIT = string.gsub(string.gsub(string.gsub(SPELLLOGCRITSELFOTHER,"%d%$",""),"%%d","%%d+"),"%%s","(.+)")
  pfCastbar.OTHER_SPELL_HIT = string.gsub(string.gsub(string.gsub(SPELLLOGOTHEROTHER,"%d%$",""), "%%s", "(.+)"), "%%d", "%%d+")
  pfCastbar.OTHER_SPELL_CRIT = string.gsub(string.gsub(string.gsub(SPELLLOGOTHEROTHER,"%d%$",""), "%%s", "(.+)"), "%%d", "%%d+")
  pfCastbar.SPELL_INTERRUPT = string.gsub(string.gsub(SPELLINTERRUPTSELFOTHER, "%d%$",""),"%%s","(.+)")
  pfCastbar.OTHER_SPELL_INTERRUPT = string.gsub(string.gsub(SPELLINTERRUPTOTHEROTHER,"%d%$",""),"%%s", "(.+)")

  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PARTY_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PARTY_BUFF")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
  pfCastbar:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
  pfCastbar:RegisterEvent("PLAYER_TARGET_CHANGED")

  pfCastbar.casterDB = {}

  pfCastbar:SetScript("OnEvent", function()
    if event == "PLAYER_TARGET_CHANGED" then
      if UnitExists("target") and pfCastbar.casterDB[UnitName("target")] then
        local starttime = pfCastbar.casterDB[UnitName("target")].starttime or 0
        local casttime = pfCastbar.casterDB[UnitName("target")].casttime or 0
        if starttime + casttime < GetTime() then
          pfCastbar.casterDB[UnitName("target")] = nil
        end
      end
    elseif arg1 then
      -- (.+) begins to cast (.+).
      for mob, spell in string.gfind(arg1, pfCastbar.SPELL_CAST) do
        pfCastbar:Action(mob, spell)
        return
      end
      -- (.+) begins to perform (.+).
      for mob, spell in string.gfind(arg1, pfCastbar.SPELL_PERFORM) do
        pfCastbar:Action(mob, spell)
        return
      end

      -- (.+) gains (.+).
      for mob, spell in string.gfind(arg1, pfCastbar.SPELL_GAINS) do
        pfCastbar:StopAction(mob, spell)
        return
      end

      -- (.+) is afflicted by (.+).
      for mob, spell in string.gfind(arg1, pfCastbar.SPELL_AFFLICTED) do
        pfCastbar:StopAction(mob, spell)
        return
      end

      -- Your (.+) hits (.+) for %d+.
      for spell, mob in string.gfind(arg1, pfCastbar.SPELL_HIT) do
        pfCastbar:StopAction(mob, spell)
        return
      end

      -- Your (.+) crits (.+) for %d+.
      for spell, mob in string.gfind(arg1, pfCastbar.SPELL_CRIT) do
        pfCastbar:StopAction(mob, spell)
        return
      end

      -- (.+)'s (.+) %a hits (.+) for %d+.
      for _, spell, mob in string.gfind(arg1, pfCastbar.OTHER_SPELL_HIT) do
        pfCastbar:StopAction(mob, spell)
        return
      end

      -- (.+)'s (.+) %a crits (.+) for %d+.
      for _, spell, mob in string.gfind(arg1, pfCastbar.OTHER_SPELL_CRIT) do
        pfCastbar:StopAction(mob, spell)
        return
      end

      -- You interrupt (.+)'s (.+).";
      for mob, spell in string.gfind(arg1, pfCastbar.SPELL_INTERRUPT) do
        pfCastbar:StopAction(mob, "INTERRUPT")
        return
      end

      -- (.+) interrupts (.+)'s (.+).
      for _, mob, spell in string.gfind(arg1, pfCastbar.OTHER_SPELL_INTERRUPT) do
        pfCastbar:StopAction(mob, "INTERRUPT")
        return
      end
    end
  end)

  function pfCastbar:Action(mob, spell)
    if L["spells"][spell] ~= nil then
      local casttime = L["spells"][spell].t / 1000
      local icon = L["spells"][spell].icon
      pfCastbar.casterDB[mob] = {cast = spell, starttime = GetTime(), casttime = casttime, icon = icon}
    end
  end

  function pfCastbar:StopAction(mob, spell)
    if pfCastbar.casterDB[mob] and ( L["interrupts"][spell] ~= nil or spell == "INTERRUPT" ) then
      pfCastbar.casterDB[mob] = nil
    end
  end
