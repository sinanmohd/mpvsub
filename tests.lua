#!/usr/bin/env lua

local subscene = require 'server/subscene'
local opensubtitles = require 'server/opensubtitles'
local util = require 'lib/util'

local errs = 0

local test_subscene = function ()
    local out, ohash, path, rc

    out = os.tmpname()
    path = './dir/Fight Club (1999) (1080p BluRay x265 10bit Tigole) [QxR].mp4'
    ohash = 'ffec132e13e08f4c'

    rc = subscene.search(path, out)
    if not rc then
        util.error('subscene: fetch failed')
        errs = errs + 1
    end

    if rc and ohash ~= util.opensubtitles_hash(out) then
        util.error('subscene: hash mismatch')
        errs = errs + 1
    end

    os.remove(out)
end

local test_opensubtitles = function ()
    local ohash, name, id, new_id

    ohash = '395787dbe5b42001'
    name = 'Fight.Club.1999.REMASTERED.720p.BRRip.XviD.AC3-RARBG'
    id = '5449593'
    new_id = opensubtitles.search_ohash(ohash, name)
    if new_id then
        new_id = new_id:match('%d*$')
    end

    if id ~= new_id then
        util.error('opensubtitles: id mismatch')
        errs = errs + 1
    end
end

test_subscene()
test_opensubtitles()

if errs == 0  then
    print('ok: all tests ran successfully')
else
    os.exit(false)
end
