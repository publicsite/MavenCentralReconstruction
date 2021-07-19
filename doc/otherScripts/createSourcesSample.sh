#!/bin/sh
thepwd="${PWD}"
cd sources.bak/structure
find . -name Decompiled | while read line; do
	if [ $(find $(dirname $line)/extractedSources -maxdepth 1 | wc -l ) -gt 2 ]; then
		if [ $(find $(dirname $line)/Decompiled -maxdepth 1 | wc -l ) -gt 1 ]; then
			mkdir -p "${thepwd}/sources/structure/$(dirname $line)"
			cp -a "$(dirname $line)/extractedSources" "${thepwd}/sources/structure/$(dirname $line)"
			cp -a "$(dirname $line)/Decompiled" "${thepwd}/sources/structure/$(dirname $line)"
		fi
	fi
done

#find . -name Decompiled | while read line; do
#	if [ "$(find $(dirname $line)/extractedSources -maxdepth 1 | wc -l )" -le 2 ]; then
#		if [ $(find $(dirname $line)/Decompiled -maxdepth 1 | wc -l ) -gt 1 ]; then
#			mkdir -p "${thepwd}/sources/structure/$(dirname $line)"
#			#cp -a "$(dirname $line)/extractedSources" "${thepwd}/sources/structure/$(dirname $line)"
#			cp -a "$(dirname $line)/Decompiled" "${thepwd}/sources/structure/$(dirname $line)"
#		fi
#	fi
#done