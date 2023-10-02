#!/usr/bin/env lua

local curl = require 'lib/curl'
local util = require 'lib/util'

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
local retries = 10

local search_ohash = function (ohash)
	local fetch, tries, hcode, url, id

	url = domain .. '/en' .. '/search/sublanguageid-' ..
	      languages[language] .. '/moviehash-' .. ohash
	tries = 0
	repeat
		fetch, hcode = curl.get(url, nil, nil)
		tries = tries + 1
	until hcode == 200 or not hcode or tries > retries

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

local search = function (path, out)
	local ohash, link

	ohash = util.opensubtitles_hash(path)
	link = search_ohash(ohash)
	if link then
		return curl.zip_link_to_file(link, nil, out, retries)
	end
end

return {
	search_ohash = search_ohash,
	search = search
}
