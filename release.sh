#!/usr/bin/env bash

elm-package diff
elm-package bump
git tag -a 1.0.1 -m "first update"
git push --tags
elm-package publish