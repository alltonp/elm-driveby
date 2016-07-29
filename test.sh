#!/usr/bin/env bash

clear;
rm tests.js;
elm-make `find . -name \*.elm -not -path \*elm-stuff\*  -print` --output tests.js;
eval "./phantomjs runner.js"
