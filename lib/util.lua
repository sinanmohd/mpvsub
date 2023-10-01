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

local opensubtitles_hash = function (fileName)
        local fil = io.open(fileName, "rb")
	if not fil then
		return nil
	end

        local lo,hi = 0,0
        for i = 1,8192 do
                local a,b,c,d = fil:read(4):byte(1,4)
                lo = lo + a + b*256 + c*65536 + d*16777216
                a,b,c,d = fil:read(4):byte(1,4)
                hi = hi + a + b*256 + c*65536 + d*16777216
                while lo >= 4294967296 do
                        lo = lo - 4294967296
                        hi = hi + 1
                end
                while hi >= 4294967296 do
                        hi = hi - 4294967296
                end
        end

        local size = fil:seek("end", -65536) + 65536
        for i = 1,8192 do
                local a,b,c,d = fil:read(4):byte(1,4)
                lo = lo + a + b*256 + c*65536 + d*16777216
                a,b,c,d = fil:read(4):byte(1,4)
                hi = hi + a + b*256 + c*65536 + d*16777216
                while lo >= 4294967296 do
                        lo = lo - 4294967296
                        hi = hi + 1
                end
                while hi >= 4294967296 do
                        hi = hi - 4294967296
                end
        end

        lo = lo + size
	while lo >= 4294967296 do
		lo = lo - 4294967296
		hi = hi + 1
	end
	while hi >= 4294967296 do
		hi = hi - 4294967296
	end

        fil:close()
        return string.format("%08x%08x", hi,lo), size
end

return {
	table_merge = table_merge,
	table_print = table_print,
	table_match_or_any = table_match_or_any,
	zip_ext_first = zip_ext_first,
	string_rm_vid_ext = string_rm_vid_ext,
	opensubtitles_hash = opensubtitles_hash,
	error = error,
}
