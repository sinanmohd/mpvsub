local mutil = require 'mp.utils'
local util = require 'lib.util'
local iso639 = require 'lib.iso639'
local opensubtitles = require 'server.opensubtitles'

local default_lang = 'eng'

local note = function (str)
    mp.osd_message('mpvsub: ' .. str)
end

local mkdir = function (path)
    local info = mutil.file_info(path)
    if info and not info.is_dir then
        os.remove(path)
    end

    return util.run({ 'mkdir', '-p', path })
end

local sub_needed = function ()
    local duration, isvideo, name

    name = mp.get_property_native('path')
    if name:find('https?://www.youtube.com/') or
       name:find('https?://youtu.be/') then
        return false
    end

    duration = mp.get_property('duration')
    if not duration or tonumber(duration) < 900 then
        return false
    end -- ensure duration is more than 15 minutes

    for _, v in pairs(mp.get_property_native('track-list')) do
        if v['type'] == 'sub' then
            return false
        end
        if v['type'] == 'video' then
            isvideo = true
        end
    end

    return isvideo
end

local getslang = function ()
    local sslang = {}
    local slang = mp.get_property_native('slang')


    for i = 1, #slang do
        local lang = iso639.toset2(slang[i])
        if lang then
            table.insert(sslang, lang)
        end
    end

    if #sslang < 1 then
        slang.insert(default_lang)
    end

    return sslang
end

local sub_setup = function ()
    local out, name, path, r, filesize, slangs, i

    note('fetching subtitle')

    out = mp.get_property_native('sub-file-paths')[1]
    if out then
        out = out:gsub('^~/', os.getenv('HOME') .. '/')
    else
        out = os.getenv('HOME') .. '/.local/share/mpv/subs'
        mp.set_property('sub-file-paths', out)
    end

    mkdir(out)
    path = mp.get_property_native('path')
    out = out .. '/' .. util.string_vid_path_to_name(path) .. '.srt'

    if not util.file_exists(path) then
        name = mp.get_property_native('media-title')
    end
    filesize = mp.get_property_native('file-size')

    i = 1
    slangs = getslang()
    repeat
        r = opensubtitles.search(path, out, {
            name = name,
            filesize = filesize,
            iso639_2_lang = slangs[i],
        })

        i = i + 1
    until r or i > #slangs

    if r then
        mp.commandv('rescan_external_files')
        mp.set_property('sid', 1)

        mp.osd_message('fetched ' .. slangs[i - 1] .. ' subtitles')
    else
        note('failed to fetch subtitles')
    end
end

local file_listener = function ()
    if sub_needed() then
        sub_setup()
    end
end

mp.register_event('file-loaded', file_listener)
mp.add_key_binding('b', "mpvsub", sub_setup)
