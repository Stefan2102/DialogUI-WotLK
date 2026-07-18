---@diagnostic disable: undefined-global
NUMGOSSIPBUTTONS = 32;

local totalGossipButtons = 0

local OPTION_BG = "Interface\\AddOns\\DialogUI\\src\\assets\\art\\parchment\\OptionBackground-Common";

function DGossipFrame_HideDefaultFrames()
    GossipFrameGreetingPanel:Hide()
    GossipNpcNameFrame:Hide()
    GossipFrameCloseButton:Hide()
    GossipFramePortrait:Hide()
    GossipFramePortrait:SetTexture()
end


function DGossipFrame_OnLoad()
    DGossipFrame_HideDefaultFrames()
    this:RegisterEvent("GOSSIP_SHOW");
    this:RegisterEvent("GOSSIP_CLOSED");
    -- Silence Blizzard's default GossipFrame so it never flashes before ours.
    if (GossipFrame) then
        GossipFrame:UnregisterAllEvents();
    end
    -- ESC closes via UISpecialFrames now that the Blizzard frame is silenced
    -- (OnHide calls CloseGossip).
    if (UISpecialFrames) then
        table.insert(UISpecialFrames, "DGossipFrame");
    end
end

function DGossipFrame_OnEvent()
    if (event == "GOSSIP_SHOW") then
        if (not DGossipFrame:IsVisible()) then
            ShowUIPanel(DGossipFrame);
            if (not DGossipFrame:IsVisible()) then
                CloseGossip();
                return;
            end
        end
        DGossipFrameUpdate();
        DialogUI_GossipBindNumberKeys();
    elseif (event == "GOSSIP_CLOSED") then
        DialogUI_GossipRestoreNumberKeys();
        HideUIPanel(DGossipFrame);
    end
end

-- Simplified option selection function
function DGossipSelectOption(buttonIndex)
    if not DGossipFrame:IsVisible() then
        return
    end

    for i = 1, NUMGOSSIPBUTTONS do
        local titleButton = getglobal("DGossipTitleButton" .. i)
        if titleButton and titleButton:IsVisible() and titleButton:GetText() and titleButton:GetText() ~= "" then
            local buttonText = titleButton:GetText()
            local _, _, numStr = string.find(buttonText, "^(%d+)%.")
            if numStr then
                local displayNum = tonumber(numStr)
                if displayNum == buttonIndex then
                    if titleButton.type == "Available" then
                        SelectGossipAvailableQuest(titleButton:GetID())
                    elseif titleButton.type == "Active" then
                        SelectGossipActiveQuest(titleButton:GetID())
                    else
                        SelectGossipOption(titleButton:GetID())
                    end
                    return
                end
            end
        end
    end
end

-- Function to close the gossip UI (can be called from anywhere)
function DGossipFrame_CloseUI()
    if DGossipFrame:IsVisible() then
        CloseGossip()
    end
end

-- Keep original click handler for mouse clicks (unchanged)
function DGossipTitleButton_OnClick()
    if (this.type == "Available") then
        SelectGossipAvailableQuest(this:GetID());
    elseif (this.type == "Active") then
        SelectGossipActiveQuest(this:GetID());
    else
        SelectGossipOption(this:GetID());
    end
end

function DGossipFrameUpdate()
    ClearAllGossipIcons();
    DGossipFrame.buttonIndex = 1;
    totalGossipButtons = 0; -- Reset counter
    
    DGossipGreetingText:SetText(GetGossipText());
    DGossipFrameAvailableQuestsUpdate(GetGossipAvailableQuests());
    DGossipFrameActiveQuestsUpdate(GetGossipActiveQuests());
    DGossipFrameOptionsUpdate(GetGossipOptions());

    for i = DGossipFrame.buttonIndex, NUMGOSSIPBUTTONS do
        getglobal("DGossipTitleButton" .. i):Hide();
    end
    DGossipFrameNpcNameText:SetText(TruncateName(UnitName("npc")));
    if (UnitExists("npc")) then
        -- Plain SetPortraitTexture renders a CIRCULAR portrait on 3.3.5a.
        SetPortraitTexture(DGossipFramePortrait, "npc");
    else
        DGossipFramePortrait:SetTexture("Interface\\QuestFrame\\UI-QuestLog-BookIcon");
    end

    -- Set Spacer
    if (DGossipFrame.buttonIndex > 1) then
        DGossipSpacerFrame:SetPoint("TOP", "DGossipTitleButton" .. DGossipFrame.buttonIndex - 1, "BOTTOM", 0, 0);
        DGossipSpacerFrame:Show();
    else
        DGossipSpacerFrame:Hide();
    end

    -- Update scrollframe
    DGossipGreetingScrollFrame:SetVerticalScroll(0);
    DGossipGreetingScrollFrame:UpdateScrollChildRect();
end

function DGossipFrameAvailableQuestsUpdate(...)
    local titleButton
    local titleIndex = 1

    -- 3.3.5a: GetGossipAvailableQuests returns 5 values per quest
    -- (title, level, isTrivial, isDaily, isRepeatable); only the title is used here.
    for i = 1, select("#", ...), 5 do
        if (DGossipFrame.buttonIndex > NUMGOSSIPBUTTONS) then
            message("This NPC has too many quests and/or gossip options.")
            break
        end

        titleButton = getglobal("DGossipTitleButton" .. DGossipFrame.buttonIndex)

        -- Add numbering to the text (only for first 9 options)
        local numberedText = (DGossipFrame.buttonIndex <= 9 and (DGossipFrame.buttonIndex .. ". ") or "") .. select(i, ...)
        titleButton:SetText(numberedText)
        totalGossipButtons = totalGossipButtons + 1

        titleButton:SetID(titleIndex)
        titleButton.type = "Available"

        local gossipIcon = getglobal(titleButton:GetName() .. "GossipIcon")

        if gossipIcon then
            gossipIcon:SetTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\availableQuestIcon.tga")
            gossipIcon:Show()
        end

        titleButton:SetNormalTexture(OPTION_BG)
        SetFontColor(titleButton, "Ivory")

        titleButton:SetHeight(titleButton:GetTextHeight() + 20)

        DGossipFrame.buttonIndex = DGossipFrame.buttonIndex + 1
        titleIndex = titleIndex + 1
        titleButton:Show()
    end

    if (DGossipFrame.buttonIndex > 1) then
        titleButton = getglobal("DGossipTitleButton" .. DGossipFrame.buttonIndex)
        titleButton:Hide()
        DGossipFrame.buttonIndex = DGossipFrame.buttonIndex + 1
    end
end

function DGossipFrameActiveQuestsUpdate(...)
    local titleButton;
    local titleIndex = 1;
    local isCompleteIndex = 1;

    -- 3.3.5a: GetGossipActiveQuests returns 4 values per quest
    -- (title, level, isTrivial, isComplete); only the title is used here.
    for i = 1, select("#", ...), 4 do
        if (DGossipFrame.buttonIndex > NUMGOSSIPBUTTONS) then
            message("This NPC has too many quests and/or gossip options.");
        end
        titleButton = getglobal("DGossipTitleButton" .. DGossipFrame.buttonIndex);

        -- Add numbering to the text (only for first 9 options)
        local numberedText = (DGossipFrame.buttonIndex <= 9 and (DGossipFrame.buttonIndex .. ". ") or "") .. select(i, ...)
        titleButton:SetText(numberedText);
        totalGossipButtons = totalGossipButtons + 1

        titleButton:SetID(titleIndex)
        titleButton.type = "Active"

        local gossipIcon = getglobal(titleButton:GetName() .. "GossipIcon")

        if gossipIcon then
            gossipIcon:SetTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\activeQuestIcon.tga")
            gossipIcon:Show()
        end

        DGossipFrame.buttonIndex = DGossipFrame.buttonIndex + 1
        titleIndex = titleIndex + 1
        titleButton:Show()

        titleButton:SetNormalTexture(OPTION_BG)
        titleButton:SetHeight(titleButton:GetTextHeight() + 20)
        SetFontColor(titleButton, "Ivory")
    end

    if (titleIndex > 1) then
        titleButton = getglobal("DGossipTitleButton" .. DGossipFrame.buttonIndex);
        titleButton:Hide();
        DGossipFrame.buttonIndex = DGossipFrame.buttonIndex + 1;
    end
end

function DGossipFrameOptionsUpdate(...)
    local titleButton

    local options = {}

    -- GetGossipOptions returns 2 values per option (text, type) in 3.3.5a (unchanged).
    for i = 1, select("#", ...), 2 do
        table.insert(options, {
            text = select(i, ...),
            iconType = select(i + 1, ...),
            originalIndex = ((i + 1) / 2)
        })
    end

    table.sort(options, function(a, b)
        local aPriority = 10
        local bPriority = 10

        local aText = string.lower(a.text)
        local bText = string.lower(b.text)

        if a.iconType == "trainer" or string.find(aText, "trainer") then
            if string.find(aText, "class") then
                aPriority = 1
            elseif string.find(aText, "profession") then
                aPriority = 2
            else
                aPriority = 3
            end
        end

        if b.iconType == "trainer" or string.find(bText, "trainer") then
            if string.find(bText, "class") then
                bPriority = 1
            elseif string.find(bText, "profession") then
                bPriority = 2
            else
                bPriority = 3
            end
        end

        if aPriority ~= bPriority then
            return aPriority < bPriority
        end

        return a.originalIndex < b.originalIndex
    end)

    for i, option in ipairs(options) do
        if (DGossipFrame.buttonIndex > NUMGOSSIPBUTTONS) then
            message("This NPC has too many quests and/or gossip options.")
        end
        titleButton = getglobal("DGossipTitleButton" .. DGossipFrame.buttonIndex)

        local numberedText = (DGossipFrame.buttonIndex <= 9 and (DGossipFrame.buttonIndex .. ". ") or "") .. option.text
        titleButton:SetText(numberedText)
        totalGossipButtons = totalGossipButtons + 1

        titleButton:SetID(option.originalIndex)
        titleButton.type = "Gossip"

        local gossipIcon = getglobal(titleButton:GetName() .. "GossipIcon")

        if gossipIcon then
            gossipIcon:Hide()
        end

        if titleButton.type == "Gossip" then
            titleButton:SetNormalTexture(nil)
            titleButton:SetHeight(titleButton:GetTextHeight() + 20)
            SetFontColor(titleButton, "DarkBrown")
        end

        local iconType = option.iconType
        local texturePath
        local specificType

        local iconMap = {
            ["banker"] = "bankerGossipIcon.tga",
            ["battlemaster"] = "battlemasterGossipIcon.tga",
            ["binder"] = "binderGossipIcon.tga",
            ["gossip"] = "gossipGossipIcon.tga",
            ["healer"] = "gossipGossipIcon.tga",
            ["tabard"] = "guildMasterGossipIcon.tga",
            ["taxi"] = "flightGossipIcon.tga",
            ["trainer"] = "trainerGossipIcon.tga",
            ["unlearn"] = "unlearnGossipIcon.tga",
            ["vendor"] = "vendorGossipIcon.tga",
            ["pet"] = "petTrainer.tga",
        }

        if iconType == "gossip" then
            specificType = DetermineGossipIconType(option.text)

            if specificType == "petTrainer" then
                texturePath = "Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\petTrainer.tga"
            else
                texturePath = "Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\" .. specificType .. "GossipIcon.tga"
            end
        elseif iconMap[iconType] then
            texturePath = "Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\" .. iconMap[iconType]
        else
            specificType = DetermineGossipIconType(option.text)

            if specificType == "petTrainer" then
                texturePath = "Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\petTrainer.tga"
            else
                texturePath = "Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\" .. specificType .. "GossipIcon.tga"
            end
        end

        gossipIcon:SetTexture(texturePath)
        gossipIcon:Show()

        if not gossipIcon:GetTexture() then
            gossipIcon:SetTexture("Interface\\AddOns\\DialogUI\\src\\assets\\art\\icons\\PetitionGossipIcon.tga")
        end

        DGossipFrame.buttonIndex = DGossipFrame.buttonIndex + 1
        titleButton:Show()
    end
end

function DetermineGossipIconType(gossipText)
    local text = string.lower(gossipText)

    local professions = {
        "alchemy", "blacksmithing", "enchanting", "engineering",
        "herbalism", "leatherworking", "mining", "skinning",
        "tailoring", "jewelcrafting", "inscription", "cooking", "fishing", "first aid"
    }

    for _, profession in pairs(professions) do
        if string.find(text, profession) then
            return profession
        end
    end

    local classes = {
        "warrior", "paladin", "hunter", "rogue", "priest",
        "shaman", "mage", "warlock", "druid", "death knight"
    }

    for _, class in pairs(classes) do
        if string.find(text, class) then
            return class
        end
    end

    if string.find(text, "profession") and string.find(text, "trainer") then
        return "professionTrainer"
    elseif string.find(text, "class") and string.find(text, "trainer") then
        return "classTrainer"
    elseif string.find(text, "stable") then
        return "stablemaster"
    elseif string.find(text, "inn") then
        return "innKeeper"
    elseif string.find(text, "mailbox") then
        return "mailbox"
    elseif string.find(text, "guild master") then
        return "guildMaster"
    elseif string.find(text, "trainer") and string.find(text, "pet") then
        return "petTrainer"
    elseif string.find(text, "auction") then
        return "auctionHouse"
    elseif string.find(text, "weapon") and string.find(text, "trainer") then
        return "weaponsTrainer"
    elseif string.find(text, "deeprun") then
        return "deeprunTram"
    elseif string.find(text, "bat handler") or
           string.find(text, "wind rider master") or
           string.find(text, "gryphon master") or
           string.find(text, "hippogryph master") or
           string.find(text, "flight master") then
        return "flight"
    elseif string.find(text, "bank") then
        return "banker"
    elseif string.find(text, "battleground") then
        return "battlemaster"
    elseif string.find(text, "spirit healer") or string.find(text, "spirithealer") then
        return "binder"
    else
        return "gossip"
    end
end

function ClearAllGossipIcons()
    for i = 1, NUMGOSSIPBUTTONS do
        local titleButton = getglobal("DGossipTitleButton" .. i)
        if titleButton then
            local gossipIcon = getglobal(titleButton:GetName() .. "GossipIcon")
            if gossipIcon then
                gossipIcon:Hide()
            end
        end
    end
end
