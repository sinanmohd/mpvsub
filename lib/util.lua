#!/usr/bin/env lua

local table_merge = function (t1, t2)
	t1 = t1 or {}
	t2 = t2 or {}

	for k, v in pairs(t2) do
		t1[k] = v
	end

	return t1
end

local table_print = function (t)
	for k, v in pairs(t) do
		print( '|'.. k .. '=' .. v .. '|')
	end
end

local table_match_or_any = function (t, key)
	local str

	str= t[key]
	if not str then
		_, str = next(t, nil)
	end

	return str
end

local zip_ext_first = function (zip, out)
	local dir, rc, srt

	dir = os.tmpname()
	os.remove(dir)
	os.execute('mkdir -p ' .. dir)

	rc = os.execute('unzip -qq ' .. zip .. ' -d ' .. dir)
	srt = io.popen('find ' .. dir .. ' -type f -name *.srt'):read('*l')
	os.execute("mv '" .. srt .. "' '"  .. out .. "'")
	os.remove(dir)

	return rc
end

local string_rm_vid_ext = function (str)
	local extensions = {
		"mkv",
		"mp4",
		"webm",
		"flv",
		"gif",
		"gifv",
		"avi",
		"mpeg",
		"3gp"
	}

	for _, ext in ipairs(extensions) do
		str = str:gsub('.' .. ext, '')
	end

	return str
end

local error = function (str)
	str = 'error: ' .. str
	if mp then
		mp.msg.warn(str)
	else
		print(str)
	end
end

return {
	table_merge = table_merge,
	table_print = table_print,
	table_match_or_any = table_match_or_any,
	zip_ext_first = zip_ext_first,
	string_rm_vid_ext = string_rm_vid_ext,
	error = error,
}
