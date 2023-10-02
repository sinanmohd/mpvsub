local mutil = require 'mp.utils'
local util = require 'lib/util'
local subscene = require 'server/subscene'
local opensubtitles = require 'server/opensubtitles'

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

    duration = tonumber(mp.get_property('duration'))
    if duration < 900 then -- duration is less than 15 minutes
        return false
    end

    for _, v in pairs(mp.get_property_native('track-list')) do
        if v['type'] == 'sub' then
            return false
        end
        if v['type'] == 'video' then
            isvideo = true
        end
    end
    if not isvideo then
        return false
    end

    return true
end

local sub_setup = function ()
    local out, name, path, rc

    mp.osd_message('fetching subtitle')

    out = mp.get_property_native('sub-file-paths')[1]
    if out then
        out = out:gsub('^~/', os.getenv('HOME') .. '/')
    else
        out = os.getenv('HOME') .. '/.local/share/mpv/subs'
        mp.set_property('sub-file-paths', out)
    end

    mkdir(out)
    path = mp.get_property_native('path')
    name = util.string_vid_path_to_name(path)
    out = out .. '/' .. name .. '.srt'

    if not path:find('https?://') then
        rc = opensubtitles.search(path, out)
    end
    if not rc then
        rc = subscene.search(path, out)
    end

    if rc then
        mp.commandv('rescan_external_files')
        mp.set_property('sid', 1)
        mp.osd_message('fetch success')
    else
        mp.osd_message('fetch failure')
    end
end

local file_listener = function ()
    if sub_needed() then
        sub_setup()
    end
end

mp.register_event('file-loaded', file_listener)
