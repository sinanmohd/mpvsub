#!/usr/bin/env lua

local util = require 'lib/util'

local extract = function (name, patterns)
	local r

	for _, p in pairs(patterns) do
		r = r or name:match(p)
		name = name:gsub(p, '')
	end

	return name, r
end

local build_dlim = function (name, attrs)
	local dlim ,r

	attrs = attrs or {}
	dlim = '[%-%.%s]?'
	local vcodecs = {
		'[M]m[Pp][Ee][Gg]' .. dlim .. '[1234]',
	}
	local acodecs = {
		'[Dd][Tt][Ss]' .. dlim .. '[Hh][Dd]',
		'[Dd][Dd]' .. dlim .. '[57]%.1',
	}
	local sources= {
		"[Ww][Ee][Bb]" .. dlim .. "[Dd][Ll]",
		"[Hh][Dd]" .. dlim .. "[Tt][Vv]",
		"[Hh][Dd]" .. dlim .. "[Tt][Ss]",
	}
	local series = {
		'[Ss]%d%d?' .. dlim .. '[Ee]%d%d?',
	}
	local sizes = {
		'%d%d%d' .. dlim .. '[Mm][Bb]',
		'%d%d?%.%d%d?' ..  dlim .. '[Gg][Bb]',
	}
	local depths = {
		'1[02]' .. dlim .. '[Bb][Ii][Tt]'
	}

	name, attrs.vcodec = extract(name, vcodecs)
	name, attrs.source = extract(name, sources)
	name, attrs.acodecs  = extract(name, acodecs)
	name, attrs.size  = extract(name, sizes)
	name, attrs.depth  = extract(name, depths)

	name, r = extract(name, series)
	if r then
		attrs.season = tonumber(r:match('%d+'))
		attrs.episode = tonumber(r:match('%d+$'))
	end

	return name, attrs
end

local build_atom = function (name, attrs)
	local r, year

	attrs = attrs or {}
	local vcodecs = {
		"[Aa][Vv]1",
		"[xXHh]26[345]",
		"[Aa][Vv][Cc]",
		"[Hh][Ee][Vv][Cc]",
		"[Xx][Vv][Ii][Dd]",
	}
	local acodecs = {
		"[Oo][Pp][Uu][Ss]",
		"[Aa][Aa][Cc]",
		"[Ee]?[Aa][Cc]3",
		"[Dd][Tt][Ss]",
	}
	local sources= {
		"[Bb][Ll][Uu][Rr][Aa][Yy]",
		"[Bb][Rr][Rr][Ii][Pp]",
		"[Dd][Vv][Dd][Rr][Ii][Pp]",
		"[Ww][Ee][Bb][Rr][Ii][Pp]",
		"[Hh][Dd][Rr][Ii][Pp]",
		"[Rr][Ee][Rr][Ii][Pp]",
	}
	local reses = {
		"2160[Pp]",
		"1440[Pp]",
		"1080[Pp]",
		"720[Pp]",
		"480[Pp]",
		"[Uu][Hh][Dd]",
		"4[Kk]"
	}
	local series = {
		'%d%d[Xx]%d%d',
	}
	local channels = {
		'6[Cc][Hh]',
		'[57]%.1',
	}

	name, attrs.vcodec = extract(name, vcodecs)
	name, attrs.source = extract(name, sources)
	name, attrs.res  = extract(name, reses)
	name, attrs.acodecs  = extract(name, acodecs)
	name, attrs.channel  = extract(name, channels)

	name, r = extract(name, series)
	if r then
		attrs.season = tonumber(r:match('%d+'))
		attrs.episode = tonumber(r:match('%d+$'))
	end

	for y in name:gmatch('%d%d%d%d') do
		year = tonumber(y)
		if year > 1900 and year <= tonumber(os.date('%Y')) then
			attrs.year = y
		end
	end
	if  attrs.year then
		name = name:gsub(tostring(attrs.year), '')
	end

	return name, attrs
end

local build_low = function (name, attrs)
	local low_attr, lows

	lows = { 'SDH' }

	low_attr = {}
	for _, low in pairs(lows) do
		low_attr[#low_attr + 1] = name:match(low)
		name = name:gsub(low, '')
	end

	attrs = attrs or {}
	if #low_attr > 0 then
		attrs.low = low_attr
	end

	return name, attrs
end

local build_title = function (name, attrs)
	attrs.title = {}
	for w in name:gmatch('%w+') do
		attrs.title[#attrs.title + 1] = w
	end

	if #attrs.title > 1 then
		attrs.scene = attrs.title[#attrs.title]
		attrs.title[#attrs.title] = nil
	end

	return attrs
end

local build = function (name)
	local attrs = {}

	name = build_dlim(name, attrs)
	name = build_atom(name, attrs)
	name = build_low(name, attrs)
	build_title(name, attrs)

	return attrs
end

local weigh = function (a1, a2)
	local key_score, score

	key_score = {
		name = 10,
		season = 10,
		episode = 10,
		source = 7,
		scene = 5,
		vcodec = 3,
		acodec = 3,
		rese = 2,
		default = 1,
	}

	score = 0
	for k, v in pairs(a1) do
		if not a2[k] then
			goto continue
		end

		if k == 'name' then
			for _, name in pairs(v) do
				if util.array_search(a2.name, name) then
					score = score + key_score.name
				end
			end
		else
			if v == a2[k] then
				score = score + (key_score[k] or key_score.default)
			end
		end

	    ::continue::
	end

	return score
end

local fuzzy = function (name, tab)
	local name_attr, high, score

	high = {
		score = 0,
		name = next(tab)
	}

	name_attr = build(name)
	for k in pairs(tab) do
		score = weigh(name_attr, build(k))
		if score > high.score then
			high.score = score
			high.name = k
		end
	end

	return tab[high.name]
end

return {
	build = build,
	fuzzy = fuzzy,
}
