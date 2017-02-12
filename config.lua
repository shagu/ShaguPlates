-- config
pfConfigCreate = CreateFrame("Frame", nil, UIParent)
pfConfigCreate:RegisterEvent("VARIABLES_LOADED")
pfConfigCreate:SetScript("OnEvent", function()
  if not pfNameplates_config then pfNameplates_config = { } end
  pfNameplates_config.clickthrough = pfNameplates_config.clickthrough or 0
  pfNameplates_config.raidiconsize = pfNameplates_config.raidiconsize or 16
  pfNameplates_config.showdebuffs = pfNameplates_config.showdebuffs or 1
  pfNameplates_config.showcastbar = pfNameplates_config.showcastbar or 1
  pfNameplates_config.showcasttext = pfNameplates_config.showcasttext or 0
  pfNameplates_config.blueshaman = pfNameplates_config.blueshaman or 1
  pfNameplates_config.onlyplayers = pfNameplates_config.onlyplayers or 0
  pfNameplates_config.showhp = pfNameplates_config.showhp or 0
  pfNameplates_config.vertical_pos = pfNameplates_config.vertical_pos or -10
  pfNameplates_config.mouselook = pfNameplates_config.mouselook or 1
  pfNameplates_config.classcolor_enemy = pfNameplates_config.classcolor_enemy or 1
  pfNameplates_config.classcolor_friend = pfNameplates_config.classcolor_friend or 1
end)

SLASH_SHAGUPLATES1 = '/shaguplates'
function SlashCmdList.SHAGUPLATES(msg)

  local commandlist = { }

  for command in string.gfind(msg, "[^ ]+") do
    table.insert(commandlist, string.lower(command))
  end

  -- help page
  if not commandlist[1] then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccShagu|cffffffffPlates Settings:")
    if pfNameplates_config.clickthrough == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("clickthrough: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("clickthrough: |cffff5555disabled")
    end

    if pfNameplates_config.showdebuffs == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("showdebuffs: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("showdebuffs: |cffff5555disabled")
    end

    if pfNameplates_config.showcastbar == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("showcastbar: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("showcastbar: |cffff5555disabled")
    end

    if pfNameplates_config.showcasttext == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("showcasttext: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("showcasttext: |cffff5555disabled")
    end

    if pfNameplates_config.blueshaman == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("blueshaman: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("blueshaman: |cffff5555disabled")
    end

    if pfNameplates_config.onlyplayers == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("onlyplayers: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("onlyplayers: |cffff5555disabled")
    end

    if pfNameplates_config.showhp == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("showhp: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("showhp: |cffff5555disabled")
    end

    if pfNameplates_config.mouselook == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("mouselook: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("mouselook: |cffff5555disabled")
    end

    if pfNameplates_config.classcolor_enemy == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("classcolor_enemy: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("classcolor_enemy: |cffff5555disabled")
    end

    if pfNameplates_config.classcolor_friend == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("classcolor_friend: |cff55ff55enabled")
    else
      DEFAULT_CHAT_FRAME:AddMessage("classcolor_friend: |cffff5555disabled")
    end

    DEFAULT_CHAT_FRAME:AddMessage("raidiconsize: |cffffcc00" .. pfNameplates_config.raidiconsize)
    DEFAULT_CHAT_FRAME:AddMessage("vertical_pos: |cffffcc00" .. pfNameplates_config.vertical_pos)
    DEFAULT_CHAT_FRAME:AddMessage("|cffcccccc0 = disable. 1 = enable")
    DEFAULT_CHAT_FRAME:AddMessage("|cffcccccce.g: /shaguplates clickthrough 0")
  end

  if commandlist[1] == "clickthrough" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: clickthrough has been |cff55ff55enabled")
      pfNameplates_config.clickthrough = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: clickthrough has been |cffff5555disabled")
      pfNameplates_config.clickthrough = 0
    end
  end

  if commandlist[1] == "raidiconsize" and commandlist[2] then
    DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: raidiconsize has been set to |cffffcc00" .. commandlist[2])
    pfNameplates_config.raidiconsize = tonumber(commandlist[2])
  end

  if commandlist[1] == "vertical_pos" and commandlist[2] then
    DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: vertical_pos has been set to |cffffcc00" .. commandlist[2])
    pfNameplates_config.vertical_pos = tonumber(commandlist[2])
  end

  if commandlist[1] == "showdebuffs" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: showdebuffs has been |cff55ff55enabled")
      pfNameplates_config.showdebuffs = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: showdebuffs has been |cffff5555disabled")
      pfNameplates_config.showdebuffs = 0
    end
  end

  if commandlist[1] == "showcastbar" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: showcastbar has been |cff55ff55enabled")
      pfNameplates_config.showcastbar = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: showcastbar has been |cffff5555disabled")
      pfNameplates_config.showcastbar = 0
    end
  end

  if commandlist[1] == "showcasttext" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: showcasttext has been |cff55ff55enabled")
      pfNameplates_config.showcasttext = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: showcasttext has been |cffff5555disabled")
      pfNameplates_config.showcasttext = 0
    end
  end

  if commandlist[1] == "blueshaman" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: blueshaman has been |cff55ff55enabled")
      pfNameplates_config.blueshaman = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: blueshaman has been |cffff5555disabled")
      pfNameplates_config.blueshaman = 0
    end
  end

  if commandlist[1] == "onlyplayers" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: onlyplayers has been |cff55ff55enabled")
      pfNameplates_config.onlyplayers = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: onlyplayers has been |cffff5555disabled")
      pfNameplates_config.onlyplayers = 0
    end
  end

  if commandlist[1] == "showhp" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: showhp has been |cff55ff55enabled")
      pfNameplates_config.showhp = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: showhp has been |cffff5555disabled")
      pfNameplates_config.showhp = 0
    end
  end

  if commandlist[1] == "mouselook" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: mouselook has been |cff55ff55enabled")
      pfNameplates_config.mouselook = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: mouselook has been |cffff5555disabled")
      pfNameplates_config.mouselook = 0
    end
  end

  if commandlist[1] == "classcolor_enemy" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: classcolor_enemy has been |cff55ff55enabled")
      pfNameplates_config.classcolor_enemy = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: classcolor_enemy has been |cffff5555disabled")
      pfNameplates_config.classcolor_enemy = 0
    end
  end

  if commandlist[1] == "classcolor_friend" and commandlist[2] then
    if tonumber(commandlist[2]) == 1 then
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: classcolor_friend has been |cff55ff55enabled")
      pfNameplates_config.classcolor_friend = 1
    else
      DEFAULT_CHAT_FRAME:AddMessage("ShaguPlates: classcolor_friend has been |cffff5555disabled")
      pfNameplates_config.classcolor_friend = 0
    end
  end
end
