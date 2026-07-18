---@diagnostic disable: undefined-global
-- DialogUI: dialog positioning (left / center) and optional screen dimmer.

DialogUI_Focus = DialogUI_Focus or {};

local FADE = 0.5;

local function IsCentered()
    return (DialogUISettings and DialogUISettings.framePosition) == "CENTER";
end

local function IsDimmed()
    return (DialogUISettings and DialogUISettings.dimMode) and true or false;
end

-- Shared full-screen dimmer behind the quest/gossip frame.
local backdrop = CreateFrame("Frame", "DDialogFocusBackdrop", UIParent);
backdrop:SetFrameStrata("FULLSCREEN");
backdrop:SetAllPoints(UIParent);
backdrop:EnableMouse(true);
backdrop:Hide();
local dim = backdrop:CreateTexture(nil, "BACKGROUND");
dim:SetAllPoints(true);
dim:SetTexture(0, 0, 0);
dim:SetAlpha(0.5);
-- Clicking the dimmed area closes the open dialog.
backdrop:SetScript("OnMouseUp", function()
    if (DQuestFrame and DQuestFrame:IsVisible()) then HideUIPanel(DQuestFrame); end
    if (DGossipFrame and DGossipFrame:IsVisible()) then CloseGossip(); end
end);

local function AnyDialogVisible()
    return (DQuestFrame and DQuestFrame:IsVisible())
        or (DGossipFrame and DGossipFrame:IsVisible());
end

-- Position a frame: center or top-left. Elevates strata when dimmer is on.
function DialogUI_Focus:PlaceFrame(frame)
    if (not frame) then return; end
    frame:ClearAllPoints();
    if (IsDimmed()) then
        frame:SetFrameStrata("FULLSCREEN_DIALOG");
    else
        frame:SetFrameStrata("DIALOG");
    end
    if (IsCentered()) then
        frame:SetPoint("CENTER", UIParent, "CENTER", -64, 20);
    else
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104);
    end
end

-- Called from a dialog's OnShow.
function DialogUI_Focus:OnShow(frame)
    self:PlaceFrame(frame);
    if (not IsDimmed()) then return; end
    UIFrameFadeRemoveFrame(backdrop);
    if (backdrop:IsShown() and backdrop:GetAlpha() > 0) then
        backdrop:SetAlpha(1);
    else
        backdrop:Show();
        backdrop:SetAlpha(0);
        UIFrameFadeIn(backdrop, FADE, 0, 1);
    end
end

-- Called from a dialog's OnHide.
function DialogUI_Focus:OnHide()
    if (AnyDialogVisible()) then return; end
    if (not backdrop:IsShown()) then return; end
    UIFrameFadeRemoveFrame(backdrop);
    UIFrameFade(backdrop, {
        mode = "OUT",
        timeToFade = FADE,
        startAlpha = backdrop:GetAlpha(),
        endAlpha = 0,
        finishedFunc = function() backdrop:Hide(); end,
    });
end

-- Re-apply when a setting is toggled from the options panel.
function DialogUI_Focus:Apply()
    if (DQuestFrame and DQuestFrame:IsVisible()) then self:PlaceFrame(DQuestFrame); end
    if (DGossipFrame and DGossipFrame:IsVisible()) then self:PlaceFrame(DGossipFrame); end
    if (IsDimmed() and AnyDialogVisible()) then
        UIFrameFadeRemoveFrame(backdrop);
        backdrop:Show();
        UIFrameFadeIn(backdrop, FADE, backdrop:GetAlpha(), 1);
    else
        UIFrameFadeRemoveFrame(backdrop);
        backdrop:Hide();
    end
end
