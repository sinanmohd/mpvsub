#!/usr/bin/env lua

local util = require 'lib/util'

local def_headr = {
	['User-Agent'] = 'cia',
	['Accept-Encoding'] = 'gzip, deflate, br'
}

local gen_head = function (t)
	local heads = ' '

	for k, v in pairs(t) do
		heads = heads .. "-H '" .. k .. ": " .. v .. "' "
	end

	return heads
end

local get = function (url, headr, args)
	local cmd, fetch, scode

	headr = util.table_merge(headr, def_headr)
	cmd = "curl -s --compressed --write-out %{http_code} '" ..
	       url .. "' --globoff --location " .. gen_head(headr)
	if args then
		cmd = cmd .. ' ' .. args
	end

	fetch = io.popen(cmd):read('*all')
	scode = fetch:match('%d*$')
	fetch = fetch:gsub('%s*%d*$', '')

	return fetch, tonumber(scode)
end

local zip_to_local_file = function (url, headr, out, retries)
	local tries, hcode, zip, zcode

	tries = 0
	zip = os.tmpname()

	repeat
		_, hcode = get(url, headr, '-o ' .. zip)
		tries = tries + 1
	until hcode == 200 or tries > retries

	if hcode == 200 then
		zcode = util.zip_ext_first(zip, out)
	end
	os.remove(zip)

	return (hcode == 200) and zcode
end

return {
	get = get,
	zip_to_local_file = zip_to_local_file,
}
