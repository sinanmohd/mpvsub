#!/usr/bin/env lua

local opensubtitles = require 'server.opensubtitles'

local note = function (success, name)
    local sign

    if success then
        sign = '✅'
    else
        sign = '❌'
    end

    print(sign .. ' : ' .. name)
end


local test_opensubtitles = function ()
    local ohash, name, id

    ohash = '395787dbe5b42001'
    name = 'Fight.Club.1999.REMASTERED.720p.BRRip.XviD.AC3-RARBG'
    id = opensubtitles.search_ohash(ohash, name, 'eng')
    note(id and id:match('%d+$') == '5449593', 'search_ohash')

    name = 'Fight.Club.10th.Anniversary.Edition.1999.720p.BrRip.x264.YIFY'
    id = opensubtitles.search_filesize(1074575924, name, 'eng')
    note(id and id:match('%d+$') == '4987774', 'search_filesize')

    name = 'Fight.Club.1999.REMASTERED.720p.BRRip.XviD.AC3-RARBG'
    id = opensubtitles.search_name(name, 'eng')
    note(id and id:match('%d+$') ==  '5449593', 'search_name')
end

test_opensubtitles()
