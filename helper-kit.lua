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

function numWithCommas(n)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

function clearCheckpoint()
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
        sampAddChatMessage('USAGE: (/def)ine [query]', 0xAFAFAF)
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
        sampAddChatMessage('USAGE: (/loc)ate [query]', 0xAFAFAF)
        return
    end
    local bm = getMatch(locations, kw)
    if bm == nil then
        sampAddChatMessage('No match found.', -1)
        return
    end
    clearCheckpoint()
    blip = addBlipForCoord(bm.X, bm.Y, bm.Z)
    setCoordBlipAppearance(blip, 2)
    checkpoint = createCheckpoint(2, bm.X, bm.Y, bm.Z, bm.X, bm.Y, bm.Z, 15)
    lua_thread.create(function()
        while checkpoint ~= nil or blip ~= nil do
            local cx, cy, cz = getCharCoordinates(PLAYER_PED)
            if getDistanceBetweenCoords3d(cx, cy, cz, bm.X, bm.Y, bm.Z) <= 15 then
                clearCheckpoint()
                addOneOffSound(cx, cy, cz, 1058)
                break
            end
            wait(100)
        end
    end)
    sampAddChatMessage(string.format('Follow the checkpoint to %s.', bm.keywords[1]), -1)
end

function cmdLvl(level)
    level = tonumber(level)
    if level == nil or level < 2 then
        sampAddChatMessage('USAGE: /lvl [n>=2]', 0xAFAFAF)
        return
    end
    local rp = 8 + (level - 2) * 4
    local mon = 5000 + (level - 2) * 2500
    local rpsum = (level - 1) * (8 + rp) / 2
    local monsum = (level - 1) * (5000 + mon) / 2
    sampAddChatMessage(string.format("{33CCFF}Level %s:{FFFFFF} %s respect points + $%s | {33CCFF}Total:{FFFFFF} %s respect points + $%s",
        numWithCommas(level),
        numWithCommas(rp),
        numWithCommas(mon),
        numWithCommas(rpsum),
        numWithCommas(monsum)
    ), -1)
end

function cmdEn(msg)
    if #msg == 0 then
        sampAddChatMessage('USAGE: (/e)xtendon(n)ewbie [text]', 0xAFAFAF)
        return
    end
    local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    local prefix = '** ###### Helper ' .. sampGetPlayerNickname(id) .. ': '
    sampSendChat('/newb ' .. msg:sub(1, 126 - #prefix), -1)
    if #prefix + #msg > 127 then
        sampSendChat('/newb' .. ' -..' .. msg:sub(127 - #prefix, #msg), -1)
    end
end

function cmdHrs()
    sampSendChat('/helprequests')
end

function cmdAhr(params)
    if #params == 0 then
        sampAddChatMessage('USAGE: (/a)ccept(h)elp(r)equest [playerid]', 0xAFAFAF)
        return
    end
    sampSendChat('/accepthelp ' .. params)
end

function cmdLvl1s()
    local lvl1s = {}
    for id = 0, sampGetMaxPlayerId(false), 1 do
        if sampIsPlayerConnected(id) then
            if sampGetPlayerScore(id) == 1 then
                if string.find(sampGetPlayerNickname(id), '_') then
                    table.insert(lvl1s, id)
                end
            end
        end
    end
    if #lvl1s == 0 then
        sampAddChatMessage('No level 1 player is online, but this may be a mistake. Try pressing TAB and waiting a few moments.', -1)
        return
    end
    sampAddChatMessage('Level 1 Players Online:', 0xFFA500)
    local final = {}
    local team = {}
    local r = 1
    for i, id in pairs(lvl1s) do
        if r == 4 then
            r = 1
            table.insert(final, team)
            team = {}
        end
        table.insert(team, string.format('{33CCFF}(%i){FFFFFF} %s', id, string.gsub(sampGetPlayerNickname(id), '_', ' ')))
        r = r + 1
    end
    for i, team in pairs(final) do
        sampAddChatMessage(table.concat(team, " | "), -1)
    end
end

function cmdHkhelp()
    sampAddChatMessage('_______________________________________', 0x33CCFF)
    sampAddChatMessage('*** HELPER KIT HELP *** - type a command for more infomation.', -1)
    sampAddChatMessage('*** HELPER KIT ALL *** /def /loc /lvl /hrs /lvl1s', 0xCBCCCE)
    sampAddChatMessage('*** HELPER KIT SENIORS *** /en /ahr', 0xCBCCCE)
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
    sampRegisterChatCommand('hrs', cmdHrs)
    sampRegisterChatCommand('ahr', cmdAhr)
    sampRegisterChatCommand('hkhelp', cmdHkhelp)
    sampRegisterChatCommand('en', cmdEn)
    sampRegisterChatCommand('lvl1s', cmdLvl1s)
    while true do wait(100) end
end

function events.onSendCommand(command)
    local cl = command:lower()
    if cl:sub(1, 4) == '/kcp' or cl:sub(1, 15) == '/killcheckpoint' then
        clearCheckpoint()
    end
end