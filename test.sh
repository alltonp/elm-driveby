#!/usr/bin/env bash

FILE=tests.js

clear;
rm $FILE;
elm-make `find . -name \*.elm -not -path \*elm-stuff\*  -print` --output $FILE;

if [ -f $FILE ];
then
   echo "File $FILE exists."
   eval "./phantomjs runner.js"
else
   echo "File $FILE does not exist."
fi

