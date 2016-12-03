pfCastbar = CreateFrame("Frame")
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

pfLocaleSpells = {}
pfLocaleSpellEvents = {}
pfLocaleSpellInterrupts = {}

pfLocale = GetLocale()
if pfLocale ~= "enUS" and
   pfLocale ~= "frFR" and
   pfLocale ~= "deDE" and
   pfLocale ~= "zhCN" and
   pfLocale ~= "ruRU" then
   pfLocale = "enUS"
end

pfCastbar:SetScript("OnEvent", function()
  if (arg1 ~= nil) then
    for mob, spell in string.gfind(arg1, pfLocaleSpellEvents[pfLocale]['SPELL_CAST']) do
      pfCastbar:Action(mob, spell)
      return
    end
    for mob, spell in string.gfind(arg1, pfLocaleSpellEvents[pfLocale]['SPELL_PERFORM']) do
      pfCastbar:Action(mob, spell)
      return
    end
    for mob, spell in string.gfind(arg1, pfLocaleSpellEvents[pfLocale]['SPELL_GAINS']) do
      pfCastbar:Action(mob, spell, true)
      return
    end
    -- this part will be used for interruption of spells
    --for mob, spell in string.gfind(arg1, pfLocaleSpellEvents[pfLocale]['SPELL_AFFLICTED']) do
    --  pfCastbar:Action(mob, spell, "afflicted")
    --  return
    --end
    --for spell, mob in string.gfind(arg1, pfLocaleSpellEvents[pfLocale]['SPELL_HIT']) do
    --  -- you hit mob with XX
    --  -- pfCastbar:Action(mob, spell, "hit")
    --  return
    --end
    --for spell, mob in string.gfind(arg1, pfLocaleSpellEvents[pfLocale]['OTHER_SPELL_HIT']) do
    --  -- someone hits mob with XX
    --  -- pfCastbar:Action(mob, spell, "hit")
    --  return
    --end
  end
end)

function pfCastbar:Action(mob, spell, gains)
  if pfLocaleSpells[pfLocale][spell] ~= nil then
    if gains and pfCastbar.casterDB[mob] and pfCastbar.casterDB[mob]["cast"] == spell then
      pfCastbar.casterDB[mob] = nil
      return
    end
    local casttime = pfLocaleSpells[pfLocale][spell].t / 1000
    local icon = pfLocaleSpells[pfLocale][spell].icon
    pfCastbar.casterDB[mob] = {cast = spell, starttime = GetTime(), casttime = casttime, icon = icon}
  end
end
