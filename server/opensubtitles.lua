#!/usr/bin/env lua

local curl = require 'lib/curl'
local util = require 'lib/util'
local attr = require 'lib/attr'

-- [[ languages supported by opensubtitles ]] --
local languages = {
	['english'] = 'eng',
	['abkhazian'] = 'abk',
	['afrikaans'] = 'afr',
	['albanian'] = 'alb',
	['arabic'] = 'ara',
	['aragonese'] = 'arg',
	['armenian'] = 'arm',
	['assamese'] = 'asm',
	['asturian'] = 'ast',
	['azerbaijani'] = 'aze',
	['basque'] = 'baq',
	['belarusian'] = 'bel',
	['bengali'] = 'ben',
	['bosnian'] = 'bos',
	['breton'] = 'bre',
	['bulgarian'] = 'bul',
	['burmese'] = 'bur',
	['catalan'] = 'cat',
	['chinese (simplified)'] = 'chi',
	['chinese (traditional)'] = 'zht',
	['chinese bilingual'] = 'zhe',
	['croatian'] = 'hrv',
	['czech'] = 'cze',
	['danish'] = 'dan',
	['dari'] = 'prs',
	['dutch'] = 'dut',
	['esperanto'] = 'epo',
	['estonian'] = 'est',
	['extremaduran'] = 'ext',
	['finnish'] = 'fin',
	['french'] = 'fre',
	['gaelic'] = 'gla',
	['galician'] = 'glg',
	['georgian'] = 'geo',
	['german'] = 'ger',
	['greek'] = 'ell',
	['hebrew'] = 'heb',
	['hindi'] = 'hin',
	['hungarian'] = 'hun',
	['icelandic'] = 'ice',
	['igbo'] = 'ibo',
	['indonesian'] = 'ind',
	['interlingua'] = 'ina',
	['irish'] = 'gle',
	['italian'] = 'ita',
	['japanese'] = 'jpn',
	['kannada'] = 'kan',
	['kazakh'] = 'kaz',
	['khmer'] = 'khm',
	['korean'] = 'kor',
	['kurdish'] = 'kur',
	['latvian'] = 'lav',
	['lithuanian'] = 'lit',
	['luxembourgish'] = 'ltz',
	['macedonian'] = 'mac',
	['malay'] = 'may',
	['malayalam'] = 'mal',
	['manipuri'] = 'mni',
	['marathi'] = 'mar',
	['mongolian'] = 'mon',
	['montenegrin'] = 'mne',
	['navajo'] = 'nav',
	['nepali'] = 'nep',
	['northern sami'] = 'sme',
	['norwegian'] = 'nor',
	['occitan'] = 'oci',
	['odia'] = 'ori',
	['persian'] = 'per',
	['polish'] = 'pol',
	['portuguese'] = 'por',
	['portuguese (br)'] = 'pob',
	['portuguese (mz)'] = 'pom',
	['pushto'] = 'pus',
	['romanian'] = 'rum',
	['russian'] = 'rus',
	['santali'] = 'sat',
	['serbian'] = 'scc',
	['sindhi'] = 'snd',
	['sinhalese'] = 'sin',
	['slovak'] = 'slo',
	['slovenian'] = 'slv',
	['somali'] = 'som',
	['spanish'] = 'spa',
	['spanish (eu)'] = 'spn',
	['spanish (la)'] = 'spl',
	['swahili'] = 'swa',
	['swedish'] = 'swe',
	['syriac'] = 'syr',
	['tagalog'] = 'tgl',
	['tamil'] = 'tam',
	['tatar'] = 'tat',
	['telugu'] = 'tel',
	['thai'] = 'tha',
	['toki pona'] = 'tok',
	['turkish'] = 'tur',
	['turkmen'] = 'tuk',
	['ukrainian'] = 'ukr',
	['urdu'] = 'urd',
	['uzbek'] = 'uzb',
	['vietnamese'] = 'vie',
	['welsh'] = 'wel',
}


local language = 'english'
local domain = 'https://www.opensubtitles.org'
local tries = 10

local search_ohash = function (ohash)
	local fetch, hcode, url, id

	url = domain .. '/en' .. '/search/sublanguageid-' ..
	      languages[language] .. '/moviehash-' .. ohash
	fetch, hcode = curl.get(url, nil, nil, tries)

	id = fetch:match('/en/subtitleserve/sub/[^\n]*\n[^\n]*iduser%-0')
	if id then
		id = id:match('/en/subtitleserve/sub/%d*')
	end

	if hcode and not id then
		util.error('opensubtitles: search_ohash')
	end

	if id then
		return domain .. id
	end
end

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

local search_filesize = function (filesize, name)
	local fetch, hcode, url, id, a

	a = attr.build(name)

	url = domain .. '/en' .. '/search/sublanguageid-' .. languages[language]
	if a.season and a.episode then
		url = url .. '/season-' .. a.season .. '/episode-' .. a.episode
	end
	url = url .. '/moviebytesize-' .. filesize

	fetch, hcode = curl.get(url, nil, nil, tries)
	if not hcode then
		return nil
	end

	print(url)
	util.table_print(ids_fetch(fetch))
	id = attr.fuzzy(name, ids_fetch(fetch))
	if id then
		print(domain .. '/en/subtitleserve/sub/' .. id)
		return domain .. '/en/subtitleserve/sub/' .. id
	end
end

local search = function (path, out, info)
	local ohash, link, name

	if util.file_exists(path) then
		ohash = util.opensubtitles_hash(path)
		link = search_ohash(ohash)
	end

	if not link then
		name = info.name or util.string_vid_path_to_name(path)
		link = search_filesize(info.filesize, name)
	end

	if link then
		return curl.zip_link_to_file(link, nil, out, tries)
	end
end

return {
	search_ohash = search_ohash,
	search_filesize = search_filesize,
	search = search
}
