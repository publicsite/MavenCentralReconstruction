#!/bin/sh

OLD_UMASK="$(umask)"
umask 0022

wget "https://raw.githubusercontent.com/spdx/license-list-data/main/json/licenses.json"

umask "${OLD_UMASK}"
