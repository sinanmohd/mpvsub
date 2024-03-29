#!/usr/bin/env lua

local table_to_cmd = function(t)
	local str = ""

	for _, v in ipairs(t) do
		v = v:gsub("'", "'")
		str = str .. " '" .. v .. "' "
	end

	return str
end

local file_exists = function(path)
	return io.open(path, "r") and true or false
end

local run = function(args)
	local sig, rc, stdout, cmd

	if mp then
		cmd = mp.command_native({
			name = "subprocess",
			capture_stdout = true,
			args = args,
		})
		if cmd then
			stdout = cmd.stdout
			rc = (cmd.status >= 0)
		end
	else
		cmd = io.popen(table_to_cmd(args))
		if cmd then
			stdout = cmd:read("*all")
			_, sig, rc = cmd:close()
			rc = (sig == "signal") or (sig == "exit" and rc == 0)
		end
	end

	return stdout or "", rc
end

local table_merge = function(t1, t2)
	local t = {}
	t1 = t1 or {}
	t2 = t2 or {}

	for k, v in pairs(t1) do
		t[k] = v
	end
	for k, v in pairs(t2) do
		t[k] = v
	end

	return t
end

local array_merge = function(a1, a2)
	local a = {}
	a1 = a1 or {}
	a2 = a2 or {}

	for _, v in ipairs(a1) do
		a[#a + 1] = v
	end
	for _, v in ipairs(a2) do
		a[#a + 1] = v
	end

	return a
end

local array_search = function(a, key)
	for _, v in pairs(a) do
		if v == key then
			return true
		end
	end

	return false
end

local table_print = function(t)
	for k, v in pairs(t) do
		print("|" .. k .. "=" .. v .. "|")
	end
end

local table_match_or_any = function(t, key)
	local str

	str = t[key]
	if not str then
		_, str = next(t, nil)
	end

	return str
end

local zip_ext_first = function(zip, out)
	local dir, rc, srt, findcmd

	dir = os.tmpname()
	os.remove(dir)
	findcmd = { "find", dir, "-type", "f", "-name", "*.srt" }

	_, rc = run({ "unzip", "-qq", zip, "-d", dir })
	srt = run(findcmd):match("[^\n]*")
	run({ "mv", srt, out })
	os.remove(dir)

	return rc
end

local string_vid_path_to_name = function(str)
	local extensions = {
		"mkv",
		"mp4",
		"webm",
		"flv",
		"gif",
		"gifv",
		"avi",
		"mpeg",
		"3gp",
	}

	str = str:match("[^/]*$")
	for _, ext in ipairs(extensions) do
		str = str:gsub("." .. ext, "")
	end

	return str
end

local error = function(str)
	str = "error: " .. str
	if mp then
		mp.msg.warn(str)
	else
		print(str)
	end
end

local opensubtitles_hash = function(fileName)
	local fil = io.open(fileName, "rb")
	if not fil then
		return nil
	end

	local lo, hi = 0, 0
	for _ = 1, 8192 do
		local a, b, c, d = fil:read(4):byte(1, 4)
		lo = lo + a + b * 256 + c * 65536 + d * 16777216
		a, b, c, d = fil:read(4):byte(1, 4)
		hi = hi + a + b * 256 + c * 65536 + d * 16777216
		while lo >= 4294967296 do
			lo = lo - 4294967296
			hi = hi + 1
		end
		while hi >= 4294967296 do
			hi = hi - 4294967296
		end
	end

	local size = fil:seek("end", -65536) + 65536
	for _ = 1, 8192 do
		local a, b, c, d = fil:read(4):byte(1, 4)
		lo = lo + a + b * 256 + c * 65536 + d * 16777216
		a, b, c, d = fil:read(4):byte(1, 4)
		hi = hi + a + b * 256 + c * 65536 + d * 16777216
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
	return string.format("%08x%08x", hi, lo), size
end

return {
	table_merge = table_merge,
	table_print = table_print,
	table_match_or_any = table_match_or_any,
	array_merge = array_merge,
	array_search = array_search,
	zip_ext_first = zip_ext_first,
	string_vid_path_to_name = string_vid_path_to_name,
	opensubtitles_hash = opensubtitles_hash,
	file_exists = file_exists,
	run = run,
	error = error,
}
