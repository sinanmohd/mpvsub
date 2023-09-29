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
	cmd = 'curl -s --compressed --write-out %{http_code} '
	cmd = cmd .. url .. gen_head(headr)
	if args then
		cmd = cmd .. ' ' .. args
	end

	fetch = io.popen(cmd):read('*all')
	scode = string.match(fetch, '%d*$')
	fetch = string.gsub(fetch, '%s*%d*$', '')

	return fetch, tonumber(scode)
end

return {
	get = get,
}
