#!/usr/bin/env bash

# requires: brew install entr

#cd elm

#multimap/*.elm typeahead/*.elm taggage/*.elm
#typeahead/*.elm multimap/*.elm taggage/*.elm

#elm-make src/Main.elm --output chrome/elm.js
ls `find . -name '*.elm' -not -path '*elm-stuff*' -print` | entr sh -c 'clear; rm elm.js; elm-make `find . -name \*.elm -not -path \*elm-stuff\*  -print` --output elm.js'
#ls `find . -name '*.elm'  -print` | entr sh -c 'clear; rm ../chrome/elm.js; elm-make `find . -name \*.elm -print` --output ../chrome/elm.js'
#ls `find . -name '*.elm'  -print` | entr sh -c 'elm-make `find . -name \*.elm -print` --output ../chrome/elm.js'
