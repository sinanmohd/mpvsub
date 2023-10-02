#!/usr/bin/env lua

local util = require 'lib/util'

local def_headr = {
	['User-Agent'] = 'cia',
	['Accept-Encoding'] = 'gzip, deflate, br'
}

local head_to_args = function (t)
	local args = {}

	for k, v in pairs(t) do
		args[#args + 1] = '-H' .. k .. ": " .. v
	end

	return args
end

local get = function (url, headr, args)
	local fetch, hcode, def_args

	def_args = {
		'curl',
		'--silent',
		'--compressed',
		'--write-out',
		'%{http_code}',
		'--globoff',
		'--location',
		url,
	}

	args = util.array_merge(def_args, args)
	headr = util.table_merge(def_headr, headr)
	args = util.array_merge(args, head_to_args(headr))

	fetch = util.run(args)
	hcode = fetch:match('%d*$') or 000
	fetch = fetch:gsub('%s*%d*$', '')

	return fetch, tonumber(hcode)
end

local zip_to_local_file = function (url, headr, out, retries)
	local tries, hcode, zip, zcode

	tries = 0
	zip = os.tmpname()

	repeat
		_, hcode = get(url, headr, { '-o'.. zip })
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
