local backdrop = {
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", tile = true, tileSize = 32,
  insets = {left = 0, right = 0, top = 0, bottom = 0},
}

local checkbox = {
  ["blueshaman"]    = "Enable Blue Shaman Class Color",
  ["clickthrough"]  = "Disable Mouse",
  ["showdebuffs"]   = "Show Debuffs on Target Nameplate",
  ["showcastbar"]   = "Show Castbar",
  ["spellname"]     = "Show Spellname On Castbar",
  -- ["players"]       = "Only Show Player Nameplates",
  ["showhp"]        = "Display HP",
  ["rightclick"]    = "Enable Mouselook on Right-Click",
  ["enemyclassc"]   = "Enable Enemy Class Colors",
  ["friendclassc"]  = "Enable Friend Class Colors",
}

local text = {
  ["clickthreshold"] = "Right-Click Threshold",
  ["vpos"]           = "Vertical Offset",
  ["raidiconsize"]   = "Raid Icon Size",
}

-- config
pfConfigCreate = CreateFrame("Frame", nil, UIParent)
pfConfigCreate:RegisterEvent("VARIABLES_LOADED")

function pfConfigCreate:ResetConfig()
  pfNameplates_config = { }
  pfNameplates_config["blueshaman"] = "1"
  pfNameplates_config["clickthrough"] = "0"
  pfNameplates_config["raidiconsize"] = "16"
  pfNameplates_config["showdebuffs"] = "0"
  pfNameplates_config["showcastbar"] = "1"
  pfNameplates_config["spellname"] = "1"
  -- pfNameplates_config["players"] = "0"
  pfNameplates_config["showhp"] = "0"
  pfNameplates_config["vpos"] = "0"
  pfNameplates_config["rightclick"] = "1"
  pfNameplates_config["clickthreshold"] = ".5"
  pfNameplates_config["enemyclassc"] = "1"
  pfNameplates_config["friendclassc"] = "1"
end

pfConfigCreate:SetScript("OnEvent", function()
  if not pfNameplates_config then
    pfConfigCreate:ResetConfig()
  end

  ShaguPlatesConfig:Initialize()

  if pfNameplates_config.blueshaman == "1" then
    RAID_CLASS_COLORS["SHAMAN"] = { r = 0.14, g = 0.35, b = 1.0, colorStr = "ff0070de" }
  end
end)

ShaguPlatesConfig = ShaguPlatesConfig or CreateFrame("Frame", "ShaguPlatesConfig", UIParent)
function ShaguPlatesConfig:Initialize()
  ShaguPlatesConfig:Hide()
  ShaguPlatesConfig:SetBackdrop(backdrop)
  ShaguPlatesConfig:SetBackdropColor(0,0,0,1)
  ShaguPlatesConfig:SetWidth(400)
  ShaguPlatesConfig:SetHeight(500)
  ShaguPlatesConfig:SetPoint("CENTER", 0, 0)
  ShaguPlatesConfig:SetMovable(true)
  ShaguPlatesConfig:EnableMouse(true)
  ShaguPlatesConfig:SetScript("OnMouseDown",function()
    ShaguPlatesConfig:StartMoving()
  end)

  ShaguPlatesConfig:SetScript("OnMouseUp",function()
    ShaguPlatesConfig:StopMovingOrSizing()
  end)

  ShaguPlatesConfig.vpos = 60

  ShaguPlatesConfig.title = CreateFrame("Frame", nil, ShaguPlatesConfig)
  ShaguPlatesConfig.title:SetPoint("TOP", 0, -2);
  ShaguPlatesConfig.title:SetWidth(396);
  ShaguPlatesConfig.title:SetHeight(40);
  ShaguPlatesConfig.title.tex = ShaguPlatesConfig.title:CreateTexture("LOW");
  ShaguPlatesConfig.title.tex:SetAllPoints();
  ShaguPlatesConfig.title.tex:SetTexture(0,0,0,.5);

  ShaguPlatesConfig.caption = ShaguPlatesConfig.caption or ShaguPlatesConfig.title:CreateFontString("Status", "LOW", "GameFontWhite")
  ShaguPlatesConfig.caption:SetPoint("TOP", 0, -10)
  ShaguPlatesConfig.caption:SetJustifyH("CENTER")
  ShaguPlatesConfig.caption:SetText("ShaguPlates")
  ShaguPlatesConfig.caption:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\arial.ttf", 24)
  ShaguPlatesConfig.caption:SetTextColor(.2,1,.8,1)

  for config, description in pairs(checkbox) do
    ShaguPlatesConfig:CreateEntry(config, description, "checkbox")
  end

  for config, description in pairs(text) do
    ShaguPlatesConfig:CreateEntry(config, description, "text")
  end

  ShaguPlatesConfig.reload = CreateFrame("Button", nil, ShaguPlatesConfig, "UIPanelButtonTemplate")
  ShaguPlatesConfig.reload:SetWidth(150)
  ShaguPlatesConfig.reload:SetHeight(30)
  ShaguPlatesConfig.reload:SetNormalTexture(nil)
  ShaguPlatesConfig.reload:SetHighlightTexture(nil)
  ShaguPlatesConfig.reload:SetPushedTexture(nil)
  ShaguPlatesConfig.reload:SetDisabledTexture(nil)
  ShaguPlatesConfig.reload:SetBackdrop(backdrop)
  ShaguPlatesConfig.reload:SetBackdropColor(0,0,0,1)
  ShaguPlatesConfig.reload:SetPoint("BOTTOMRIGHT", -20, 20)
  ShaguPlatesConfig.reload:SetText("Save")
  ShaguPlatesConfig.reload:SetScript("OnClick", function()
    ReloadUI()
  end)

  ShaguPlatesConfig.reset = CreateFrame("Button", nil, ShaguPlatesConfig, "UIPanelButtonTemplate")
  ShaguPlatesConfig.reset:SetWidth(150)
  ShaguPlatesConfig.reset:SetHeight(30)
  ShaguPlatesConfig.reset:SetNormalTexture(nil)
  ShaguPlatesConfig.reset:SetHighlightTexture(nil)
  ShaguPlatesConfig.reset:SetPushedTexture(nil)
  ShaguPlatesConfig.reset:SetDisabledTexture(nil)
  ShaguPlatesConfig.reset:SetBackdrop(backdrop)
  ShaguPlatesConfig.reset:SetBackdropColor(0,0,0,1)
  ShaguPlatesConfig.reset:SetPoint("BOTTOMLEFT", 20, 20)
  ShaguPlatesConfig.reset:SetText("Reset")
  ShaguPlatesConfig.reset:SetScript("OnClick", function()
    pfNameplates_config = nil
    ReloadUI()
  end)
end

function ShaguPlatesConfig:CreateEntry(config, description, type)
  -- sanity check
  if not pfNameplates_config[config] then
    pfConfigCreate:ResetConfig()
  end

  -- basic frame
  local frame = getglobal("SPC" .. config) or CreateFrame("Frame", "SPC" .. config, ShaguPlatesConfig)
  frame:SetWidth(400)
  frame:SetHeight(25)
  frame:SetPoint("TOP", 0, -ShaguPlatesConfig.vpos)

  -- caption
  frame.caption = frame.caption or frame:CreateFontString("Status", "LOW", "GameFontWhite")
  frame.caption:SetFont("Interface\\AddOns\\ShaguPlates\\fonts\\arial.ttf", 14)
  frame.caption:SetPoint("LEFT", 20, 0)
  frame.caption:SetJustifyH("LEFT")
  frame.caption:SetText(description)

  -- checkbox
  if type == "checkbox" then
    frame.input = frame.input or CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.input:SetWidth(24)
    frame.input:SetHeight(24)
    frame.input:SetPoint("RIGHT" , -20, 0)

    frame.input.config = config
    if pfNameplates_config[config] == "1" then
      frame.input:SetChecked()
    end

    frame.input:SetScript("OnClick", function ()
      if this:GetChecked() then
        pfNameplates_config[this.config] = "1"
      else
        pfNameplates_config[this.config] = "0"
      end
    end)

  elseif type == "text" then
    -- input field
    frame.input = frame.input or CreateFrame("EditBox", nil, frame)
    frame.input:SetTextColor(.2,1,.8,1)
    frame.input:SetJustifyH("RIGHT")

    frame.input:SetWidth(50)
    frame.input:SetHeight(20)
    frame.input:SetPoint("RIGHT" , -20, 0)
    frame.input:SetFontObject(GameFontNormal)
    frame.input:SetAutoFocus(false)
    frame.input:SetScript("OnEscapePressed", function(self)
      this:ClearFocus()
    end)

    frame.input.config = config
    frame.input:SetText(pfNameplates_config[config])

    frame.input:SetScript("OnTextChanged", function(self)
      pfNameplates_config[this.config] = this:GetText()
    end)
  end

  ShaguPlatesConfig.vpos = ShaguPlatesConfig.vpos + 30
end

SLASH_SHAGUPLATES1 = '/shaguplates'
SLASH_SHAGUPLATES2 = '/sp'

function SlashCmdList.SHAGUPLATES(msg)
  if ShaguPlatesConfig:IsShown() then
    ShaguPlatesConfig:Hide()
  else
    ShaguPlatesConfig:Show()
  end
end
