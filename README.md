MpvSUB: /comfy/ subtitles for mpv
---------------------------------

mpvsub automatically fetches subtitles "when needed" with zero interactions
from the user.

Features
--------

* no api keys or accounts needed
* search uses file hash by default
* purpose made fuzzy search (accurate results)
* native implementation (minimal dependencies)
* works with webtorrent

Installation
------------

    $ git clone https://git.sinanmohd.com/mpvsub ~/.config/mpv/scripts/mpvsub

Dependencies
------------

* curl
* unzip

TODO
----
- [ ] use language from slang and fall back to english
- [x] deprecate subscene (unreliable servers and poor db)
- [ ] add key binding to force subtitle lookup
- [ ] implement text search on all severs
- [ ] remove the default retries
- [ ] shill on reddit and matrix
- [ ] first fetch normally when key is pressed then bring up a menu to select subs(we likely got it wrong)
- [ ] remove this todo

Contact
-------

* matrix: [#chat:sinanmohd.com](https://matrix.to/#/#chat:sinanmohd.com)

you can also use email `sinan@firemail.cc` but matrix is preferred
