local mutil = require 'mp.utils'
local subscene = require 'server/subscene'

local notify = function (str, sec)
    mp.osd_message(str, sec)
end

local mkdir = function (path)
    local info = mutil.file_info(path)
    if info and not info.is_dir then
        os.remove(path)
    end

    return os.execute('mkdir -p ' .. path)
end

local sub_needed = function ()
    local duration, isvideo

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
    local out, name

    notify('fetching subtitles')

    out = mp.get_property_native('sub-file-paths')[1]
    if out then
        out = out:gsub('^~/', os.getenv('HOME') .. '/')
    else
        out = os.getenv('HOME') .. '.local/share/subs'
        mp.set_property('sub-file-paths', out)
    end

    mkdir(out)
    name = mp.get_property_native('path')
    out = out .. '/' .. name .. '.srt'

    if subscene.search(name, out) then
        mp.commandv('rescan_external_files')
        notify('fetch success')
    else
        notify('fetch failure')
    end
end

local file_listener = function ()
    if not sub_needed() then
        return
    end

    sub_setup()
end

mp.register_event('file-loaded', file_listener)
