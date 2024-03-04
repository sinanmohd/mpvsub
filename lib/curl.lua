#!/usr/bin/env lua

local util = require 'lib.util'

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
	hcode = fetch:match('%d*$')
	fetch = fetch:gsub('%s*%d*$', '')

	return fetch, tonumber(hcode)
end

local zip_link_to_file = function (url, headr, out)
	local hcode, zip, rc, args

	zip = os.tmpname()
	args = { '-o'.. zip }

	_, hcode = get(url, headr, args)

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
