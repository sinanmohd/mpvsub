#!/usr/bin/env lua

local subscene = require 'server/subscene'
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

test_subscene()

if errs == 0  then
    print('ok: all tests ran successfully')
else
    os.exit(false)
end
