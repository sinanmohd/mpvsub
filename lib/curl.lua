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

local get = function (url, headr, args, tries)
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

	repeat
		fetch = util.run(args)
		-- hcode can be nil, it means curl was't able to fulfill the http request, either
		-- because curl package is broken or mpv killed it prematurely. we can exit
		-- out of retry loop early if hcode is nil since there's no point in retrying
		hcode = fetch:match('%d*$')

		tries = tries - 1
	until hcode == '200' or not hcode or tries <= 0

	fetch = fetch:gsub('%s*%d*$', '')
	return fetch, tonumber(hcode)
end

local zip_link_to_file = function (url, headr, out, tries)
	local hcode, zip, rc, args

	zip = os.tmpname()
	args = { '-o'.. zip }

	_, hcode = get(url, headr, args, tries)

	rc = (hcode == 200)
	if rc then
		rc = util.zip_ext_first(zip, out)
	end
	os.remove(zip)

	if hcode and not rc then
		util.error('curl: zip_link_to_file')
	end

	return rc
end

return {
	get = get,
	zip_link_to_file = zip_link_to_file,
}
