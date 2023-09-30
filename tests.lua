#!/usr/bin/env lua

local subscene = require 'server/subscene'

local errs = 0

local file_hash_verify = function (path, sha256)
	local newhash = io.popen('sha256sum ' .. path):read(64)
	return (newhash == sha256)
end

local test_subscene = function ()
    local out, sha256, name

    out = os.tmpname()
    name = 'Fight Club (1999) (1080p BluRay x265 10bit Tigole) [QxR].mp4'
    sha256 = 'fe88e2c1345a7daed82cb570952c13fae6a6867449f7dd5e719ea0a0c1e2e242'

    if not subscene.search(name, out) then
        print('err: subscene: failed to fetch subtitles')
        errs = errs + 1
    end

    if not file_hash_verify(out, sha256) then
        print('err: subscene: subtitle hash mismatch')
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
