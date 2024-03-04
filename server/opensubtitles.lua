#!/usr/bin/env lua

local curl = require 'lib.curl'
local util = require 'lib.util'
local attr = require 'lib.attr'

local domain = 'https://www.opensubtitles.org'

local ids_fetch = function (page)
	local iter, no_name, line, id, name, tab

	tab = {}
	no_name = 0
	iter = page:gmatch('[^\n\r]+')
	while true do
		line = iter()
		if not line then
			break
		end

		id = line:match('/en/subtitles/%d*')
		if id then
			id = id:match('%d+$')

			line = iter() -- movie
			if line:find('%.%.%.$') then
				-- name cuts off...
				name = line:gsub('"[^"]*$', '')
				name = name:match('[^"]+$')
			else
				name = line:gsub('<br/><a rel.*$', '')
				name = name:match('[^>]+$')
			end

			if not name then
				line = iter()

				if line:find('^%[S%d%dE%d%d%]$') then
					-- it's a series
					line = iter()
					if line:find('%.%.%.$') then
						name = line:gsub('^.*title="', '')
						name = name:match('[^"]+')
					else
						name = line:match('[^<]+')
					end
				else
					-- no name
					name = tostring(no_name)
					no_name = no_name + 1
				end
			end

			tab[name] = id
		end
	end

	return tab
end

local search_ohash = function (ohash, name, lang)
	local fetch, hcode, url, id

	url = domain .. '/en' .. '/search/sublanguageid-' .. lang ..
	      '/moviehash-' .. ohash
	fetch, hcode = curl.get(url, nil, nil)

	id = attr.fuzzy(name, ids_fetch(fetch))
	if hcode and not id then
		util.error('opensubtitles: search_ohash failed')
	end

	if id then
		return domain .. '/en/subtitleserve/sub/' .. id
	end
end

local search_filesize = function (filesize, name, lang)
	local fetch, hcode, url, id, a

	a = attr.build(name)

	url = domain .. '/en' .. '/search/sublanguageid-' .. lang
	if a.season and a.episode then
		url = url .. '/season-' .. a.season .. '/episode-' .. a.episode
	end
	url = url .. '/moviebytesize-' .. filesize

	fetch, hcode = curl.get(url, nil, nil)
	if not hcode then
		return nil
	end

	id = attr.fuzzy(name, ids_fetch(fetch))
	if hcode and not id then
		util.error('opensubtitles: search_filesize failed')
	end

	if id then
		return domain .. '/en/subtitleserve/sub/' .. id
	end
end

local search = function (path, out, info)
	local ohash, link, name, lang

	lang = info.iso639_2_lang or 'eng'
	name = info.name or util.string_vid_path_to_name(path)

	if util.file_exists(path) then
		ohash = util.opensubtitles_hash(path)
		link = search_ohash(ohash, name, lang)
	end
	if not link then
		link = search_filesize(info.filesize, name, lang)
	end

	if link then
		return curl.zip_link_to_file(link, nil, out)
	end
end

return {
	search_ohash = search_ohash,
	search_filesize = search_filesize,
	search = search
}
