#!/usr/bin/env lua

local curl = require 'lib/curl'
local util = require 'lib/util'

-- [[ languages supported by subscene ]] --
local languages = {
	['arabic'] = 2,
	['bengali'] = 54,
	['brazillian-portuguese'] = 4,
	['chinese-bg-code'] = 7,
	['czech'] = 9,
	['danish'] = 10,
	['dutch'] = 11,
	['english'] = 13,
	['farsipersian'] = 46,
	['finnish'] = 17,
	['french'] = 18,
	['german'] = 19,
	['greek'] = 21,
	['hebrew'] = 22,
	['indonesian'] = 44,
	['italian'] = 26,
	['japanese'] = 27,
	['korean'] = 28,
	['malay'] = 50,
	['norwegian'] = 30,
	['polish'] = 31,
	['portuguese'] = 32,
	['romanian'] = 33,
	['spanish'] = 38,
	['swedish'] = 39,
	['thai'] = 40,
	['turkish'] = 41,
	['vietnamese'] = 45,
	['albanian'] = 1,
	['armenian'] = 73,
	['azerbaijani'] = 55,
	['basque'] = 74,
	['belarusian'] = 68,
	['big-5-code'] = 3,
	['bosnian'] = 60,
	['bulgarian'] = 5,
	['bulgarian_english'] = 6,
	['burmese'] = 61,
	['cambodian_khmer'] = 79,
	['catalan'] = 49,
	['croatian'] = 8,
	['dutch_english'] = 12,
	['english_german'] = 15,
	['esperanto'] = 47,
	['estonian'] = 16,
	['georgian'] = 62,
	['greenlandic'] = 57,
	['hindi'] = 51,
	['hungarian'] = 23,
	['hungarian_english'] = 24,
	['icelandic'] = 25,
	['kannada'] = 78,
	['kinyarwanda'] = 81,
	['kurdish'] = 52,
	['latvian'] = 29,
	['lithuanian'] = 43,
	['macedonian'] = 48,
	['malayalam'] = 64,
	['manipuri'] = 65,
	['mongolian'] = 72,
	['nepali'] = 80,
	['pashto'] = 67,
	['punjabi'] = 66,
	['russian'] = 34,
	['serbian'] = 35,
	['sinhala'] = 58,
	['slovak'] = 36,
	['slovenian'] = 37,
	['somali'] = 70,
	['sundanese'] = 76,
	['swahili'] = 75,
	['tagalog'] = 53,
	['tamil'] = 59,
	['telugu'] = 63,
	['ukrainian'] = 56,
	['urdu'] = 42,
	['yoruba'] = 71,
}

local language = 'english'
local domain = 'https://subscene.com'
local headr = {['Cookie'] = 'LanguageFilter=' ..languages[language]}
local retries = 10

local title_search = function (key)
	local url, args, fetch, hcode, tries, title, rc

	url = domain .. '/subtitles/searchbytitle'
	args = { '--data-raw',  'query=' .. key }

	tries = 0
	repeat
		fetch, hcode = curl.get(url, headr, args)
		tries = tries + 1
	until hcode == 200 or not hcode or tries > retries

	title = fetch:match('href="/subtitles/[^"]*')
	if title then
		title = title:gsub('href="',  domain)
	end
	rc = (hcode == 200 and title ~= nil)

	if hcode and not rc then
		util.error('subscene: title_search')
	end

	return title, rc
end

local id_fetch = function (title)
	local tab, id, name, fetch, hcode, tries, iter, line

	tries = 0
	repeat
		fetch, hcode = curl.get(title, headr, nil)
		tries = tries + 1
	until hcode == 200 or not hcode or tries > retries

	tab = {}
	iter = fetch:gmatch('[^\n\r]+')
	while true do
		line = iter()
		if not line then
			break
		end

		id = line:match('/subtitles/[^/]*/[^/]*/%d*')
		if id then
			iter()
			iter()
			iter()
			iter()

			name = iter():match('%S[^\n\r]*%S')
			tab[name] = domain .. id
			id = nil
		end
	end

	if hcode and tab == {} then
		util.error('subscene: id_fetch')
	end

	return tab
end

local link_fetch = function (id)
	local fetch, tries, hcode, link, rc

	tries = 0
	repeat
		fetch, hcode = curl.get(id, headr, nil)
		tries = tries + 1
	until hcode == 200 or not hcode or tries > retries
	rc = hcode == 200

	if rc then
		link = domain .. fetch:match('/subtitles/[%l_-]*%-text/[^"]*')
	end

	if hcode and not rc then
		util.error('subscene: link_fetch')
	end

	return link, rc
end

local search = function (path, out)
	local title, id, link, rc, key

	key = util.string_vid_path_to_name(path)
	title, rc = title_search(key)
	if not rc then
		return false
	end

	id = id_fetch(title)
	id = util.table_match_or_any(id, key)
	if not id then
		return false
	end

	link, rc = link_fetch(id)
	if not rc then
		return false
	end

	rc = curl.zip_link_to_file(link, headr, out, retries)
	if not rc then
		return false
	end

	return true
end

return {
	title_search = title_search,
	id_fetch = id_fetch,
	link_fetch = link_fetch,
	search = search,
}
