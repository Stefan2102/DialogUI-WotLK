---@diagnostic disable: undefined-global
-- DialogUI options panel: ESC > Interface > AddOns > DialogUI.
-- Builds the checkboxes/sliders that drive DialogUI_Config.

local panel = CreateFrame("Frame", "DialogUIOptionsPanel", InterfaceOptionsFramePanelContainer);
panel.name = "DialogUI";

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge");
title:SetPoint("TOPLEFT", 16, -16);
title:SetText("DialogUI");

local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall");
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8);
subtitle:SetText("Immersive quest / gossip / book dialog frames.");

local anchor = subtitle;
local FIRST_GAP = -16;
local GAP = -8;

-- Helper: a labelled checkbox wired to get/set callbacks.
local function AddCheckbox(name, label, tooltip, getFn, setFn)
    local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate");
    cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", (anchor == subtitle) and 0 or 0, (anchor == subtitle) and FIRST_GAP or GAP);
    local text = getglobal(name .. "Text");
    if (text) then text:SetText(label); end
    cb.tooltipText = tooltip;
    cb:SetScript("OnShow", function(self) self:SetChecked(getFn()); end);
    cb:SetScript("OnClick", function(self) setFn(self:GetChecked() and true or false); end);
    anchor = cb;
    return cb;
end

-- Helper: a labelled slider (OptionsSliderTemplate) wired to get/set callbacks.
local function AddSlider(name, label, minV, maxV, step, getFn, setFn)
    local s = CreateFrame("Slider", name, panel, "OptionsSliderTemplate");
    s:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 4, -28);
    s:SetWidth(240);
    s:SetMinMaxValues(minV, maxV);
    s:SetValueStep(step);
    getglobal(name .. "Low"):SetText(tostring(minV));
    getglobal(name .. "High"):SetText(tostring(maxV));
    local caption = getglobal(name .. "Text");
    if (caption) then caption:SetText(label); end
    s.captionBase = label;
    s:SetScript("OnShow", function(self) self:SetValue(getFn()); end);
    s:SetScript("OnValueChanged", function(self, value)
        -- Snap to step and update the live caption.
        value = math.floor((value / step) + 0.5) * step;
        if (caption) then caption:SetText(label .. ":  " .. string.format("%.2f", value)); end
        setFn(value);
    end);
    anchor = s;
    return s;
end

AddCheckbox("DialogUIAnimCheck", "Disable text animation",
    "Turn off the typewriter / fade-in effect on quest text.",
    function() return DialogUISettings.disableAnim; end,
    function(on) DialogUISettings.disableAnim = on; DialogUI_Config:ApplyAnimation(); end);

AddCheckbox("DialogUICenterCheck", "Center dialogs",
    "Anchor the quest and gossip frames to the center of the screen.",
    function() return DialogUISettings.framePosition == "CENTER"; end,
    function(on) DialogUISettings.framePosition = on and "CENTER" or "LEFT"; if (DialogUI_Focus) then DialogUI_Focus:Apply(); end end);

AddCheckbox("DialogUIDimCheck", "Screen dimmer",
    "Dim the screen behind the quest / gossip windows (like the book reader).",
    function() return DialogUISettings.dimMode; end,
    function(on) DialogUISettings.dimMode = on; if (DialogUI_Focus) then DialogUI_Focus:Apply(); end end);

AddCheckbox("DialogUINarrowFontCheck", "Use narrow font",
    "Use Arial Narrow for the dialog text (fits more per line) instead of Friz Quadrata.",
    function() return DialogUISettings.fontFace == "arial"; end,
    function(on) DialogUISettings.fontFace = on and "arial" or "friz"; DialogUI_Config:ApplyFont(); end);

AddSlider("DialogUITextSizeSlider", "Text size", 0.8, 1.4, 0.05,
    function() return DialogUISettings.fontScale or 1.0; end,
    function(v) DialogUISettings.fontScale = v; DialogUI_Config:ApplyFont(); end);

AddSlider("DialogUIFrameScaleSlider", "Frame scale", 0.8, 1.3, 0.05,
    function() return DialogUISettings.frameScale or 1.0; end,
    function(v) DialogUISettings.frameScale = v; DialogUI_Config:ApplyScale(); end);

if (InterfaceOptions_AddCategory) then
    InterfaceOptions_AddCategory(panel);
end
