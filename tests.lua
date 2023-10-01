#!/usr/bin/env lua

local subscene = require 'server/subscene'
local util = require 'lib/util'

local errs = 0

local test_subscene = function ()
    local out, ohash, name

    out = os.tmpname()
    name = 'Fight Club (1999) (1080p BluRay x265 10bit Tigole) [QxR].mp4'
    ohash = 'ffec132e13e08f4c'

    if not subscene.search(name, out) then
        util.error('subscene: fetch failed')
        errs = errs + 1
    end

    if ohash ~= util.opensubtitles_hash(out) then
        util.error('subscene: hash mismatch')
        errs = errs + 1
    end

    os.remove(out)
end

test_subscene()

if errs == 0  then
    print('ok: all tests ran successfully')
else
    os.exit(false)
end
