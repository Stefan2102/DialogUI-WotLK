---@diagnostic disable: undefined-global

DialogUI_GossipSuppressors = DialogUI_GossipSuppressors or {}

function DialogUI_RegisterGossipSuppressor(fn)
    if type(fn) == "function" then
        table.insert(DialogUI_GossipSuppressors, fn)
    end
end

-- Returns true when another addon should replace gossip UI.
function DialogUI_ShouldSuppressGossip()
    local tmog = _G.Transmog
    local transmogFrame = _G.TransmogFrame
    if tmog and tmog.prefix == "transmog" and transmogFrame then
        if tmog.serverRequestsOverlay or transmogFrame:IsVisible() then
            return true
        end
    end

    for i = 1, #DialogUI_GossipSuppressors do
        if DialogUI_GossipSuppressors[i]() then
            return true
        end
    end

    return false
end
