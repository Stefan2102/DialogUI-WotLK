---@diagnostic disable: undefined-global
-- DialogUI shared utilities

local TRUNCATE = 22;
function TruncateName(name)
    if name and string.len(name) > TRUNCATE then
        return string.sub(name, 1, TRUNCATE - 1) .. "...";
    end
    return name;
end

function SetFontColor(fontObject, key)
    local color = DialogUI_Colors[key];
    if (not color) then
        return;
    end
    if (fontObject.SetTextColor) then
        fontObject:SetTextColor(color[1], color[2], color[3]);
    elseif (fontObject.GetFontString) then
        local fontString = fontObject:GetFontString();
        if (fontString) then
            fontString:SetTextColor(color[1], color[2], color[3]);
        end
    end
end
