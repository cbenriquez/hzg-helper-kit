script_name('Helper Dictionary')
script_author('Evan West')

local http = require('socket.http')

local dictVersionPath = 'moonloader\\config\\helper-dict\\dict-version'
local dictPath = 'moonloader\\config\\helper-dict\\dict.json'

local hd = {}

function cmdDef(kw)
    kw = kw:lower():gsub(' ', ''):gsub('-', '')
    local bm, bmd
    for _, e in ipairs(hd) do
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
    if bm == nil then return end
    kw, bmd = nil, nil
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

function main()
    while not isSampAvailable() do wait(100) end
    local localDictVersionFile = io.open(dictVersionPath, 'r+b')
    if localDictVersionFile == nil then goto skipupdate end
    local localDictVersion = tonumber(localDictVersionFile:read('*a'))
    local remoteDictVersion = http.request('https://raw.githubusercontent.com/cbenriquez/hzg-helper-kit/master/config/helper-kit/dict-version')
    remoteDictVersion = tonumber(remoteDictVersion)
    if remoteDictVersion == nil then goto skipupdate end
    if localDictVersion >= remoteDictVersion then goto skipupdate end
    localDictVersion = nil
    local remoteDict = http.request('https://raw.githubusercontent.com/cbenriquez/hzg-helper-kit/master/config/helper-kit/dict.json')
    if remoteDict == nil then goto skipupdate end
    local localDictFile = io.open(dictPath, 'wb')
    localDictFile:write(remoteDict)
    localDictFile:close()
    remoteDict, localDictFile = nil, nil
    localDictVersionFile:write(encodeJson(vcj))
    localDictVersionFile:close()
    localDictVersionFile = nil
    ::skipupdate::
    local file = io.open(dictPath, 'rb')
    if file ~= nil then
        hd = decodeJson(file:read('*a'))
        file:close()
        file = nil
    end
    sampRegisterChatCommand('def', cmdDef)
    while true do wait(100) end
end