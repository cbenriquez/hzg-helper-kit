script_name('Helper Kit')
script_version('1')
script_author('Evan West')

local events = require('samp.events')

local dictPath = 'moonloader\\config\\helper-kit\\dict.json'
local dict = {}

local locationsPath = 'moonloader\\config\\helper-kit\\locations.json'
local locations = {}

local checkpoint, blip

function getMatch(a, kw)
    kw = kw:lower():gsub(' ', ''):gsub('-', '')
    local bm, bmd
    for _, e in ipairs(a) do
        if e.keywords and type(e.keywords) == 'table' then
            for _, ekw in ipairs(e.keywords) do
                local ekws = ekw:lower():gsub(' ', ''):gsub('-', '')
                if kw == ekws:sub(1, #kw) then
                    local d = math.abs(#kw - #ekws)
                    if bmd == nil or d < bmd then
                        bmd = d
                        bm = e
                    end
                end
            end
        end
    end
    return bm
end

function clearMarker()
    if blip ~= nil then
        removeBlip(blip)
        blip = nil
    end
    if checkpoint ~= nil then
        deleteCheckpoint(checkpoint)
        checkpoint = nil
    end
end

function cmdDef(kw)
    if #kw == 0 then
        sampAddChatMessage('USAGE: (/def)ine [query]', -1)
        return
    end
    local bm = getMatch(dict, kw)
    if bm == nil then
        sampAddChatMessage('No match found.', -1)
        return
    end
    local msgt = {bm.keywords[1]}
    for n, v in pairs(bm) do
        if n == 'keywords' then goto continue end
        table.insert(msgt, string.format('%s: %s', n:sub(1, 1):upper() .. n:sub(2, #n), v))
        ::continue::
    end
    local msg = ''
    for i, v in pairs(msgt) do
        msg = msg .. v
        if i == #msgt then goto continue end
        msg = msg .. ' | '
        ::continue::
    end
    msgt = nil
    while #msg > 144 do
        sampAddChatMessage(msg:sub(1, 144), -1)
        msg = '-..' .. msg:sub(145, #msg)
    end
    sampAddChatMessage(msg, -1)
end

function cmdLoc(kw)
    if #kw == 0 then
        sampAddChatMessage('USAGE: (/loc)ate [query]', -1)
        return
    end
    local bm = getMatch(locations, kw)
    if bm == nil then
        sampAddChatMessage('No match found.', -1)
        return
    end
    clearMarker()
    blip = addBlipForCoord(bm.X, bm.Y, bm.Z)
    setCoordBlipAppearance(blip, 2)
    checkpoint = createCheckpoint(2, bm.X, bm.Y, bm.Z, bm.X, bm.Y, bm.Z, 15)
    lua_thread.create(function()
        while checkpoint ~= nil or blip ~= nil do
            local cx, cy, cz = getCharCoordinates(PLAYER_PED)
            if getDistanceBetweenCoords3d(cx, cy, cz, bm.X, bm.Y, bm.Z) <= 15 then
                clearMarker()
                addOneOffSound(cx, cy, cz, 1058)
                break
            end
            wait(100)
        end
    end)
    sampAddChatMessage(string.format('A marker has been placed on %s.', bm.keywords[1]), -1)
end

function cmdLvl(level)
    level = tonumber(level)
    if level == nil or level < 2 then
        sampAddChatMessage('USAGE: /lvl [>=2]', -1)
        return
    end
    local rp = 8 + (level - 2) * 4
    local mon = 5000 + (level - 2) * 2500
    sampAddChatMessage(string.format("Level %d = %d respect points + $%d", level, rp, mon), -1)
end

function cmdN(msg)
    if #msg == 0 then
        sampAddChatMessage('USAGE: (/n)ewbie [text]', -1)
        return
    end
    local prefix = '** Junior Helper ' .. sampGetPlayerNickname(sampGetPlayerIdByCharHandle(PLAYER_PED)):gsub('_', ' ') .. ': '
    sampSendChat('/newb ' .. msg:sub(1, 126 - #prefix), -1)
    if #prefix + #msg > 127 then
        sampSendChat('/g -..' .. msg:sub(127 - #prefix, #msg), -1)
    end
end

function main()
    while not isSampAvailable() do wait(100) end
    local f = io.open(dictPath, 'rb')
    if f ~= nil then
        dict = decodeJson(f:read('*a'))
        f:close()
        f = nil
    end
    f = io.open(locationsPath, 'rb')
    if f ~= nil then
        locations = decodeJson(f:read('*a'))
        f:close()
        f = nil
    end
    sampRegisterChatCommand('def', cmdDef)
    sampRegisterChatCommand('loc', cmdLoc)
    sampRegisterChatCommand('lvl', cmdLvl)
    sampRegisterChatCommand('n', cmdN)
    while true do wait(100) end
end

function events.onSendCommand(command)
    local cl = command:lower()
    if cl:sub(1, 4) == '/kcp' or cl:sub(1, 15) == '/killcheckpoint' then
        clearMarker()
    end
end