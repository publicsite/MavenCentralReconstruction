#!/bin/sh

thepwd="$PWD"

cd sources/structure

find . -maxdepth 3 -mindepth 3 -type d | while read afile; do

groupId="$(printf "%s" "${afile}" | cut -d "/" -f 2)"
artifactId="$(printf "%s" "${afile}" | cut -d "/" -f 3)"
version="$(printf "%s" "${afile}" | cut -d "/" -f 4)"

	if [ -d ${groupId}/${artifactId}/${version} ]; then

		mkdir -p "${thepwd}/fileListsAndDeps/${groupId}/${artifactId}/${version}"

		if [ -d "${groupId}/${artifactId}/${version}/extractedSources" ]; then

			find "${groupId}/${artifactId}/${version}/extractedSources" -name "*.java" | while read line; do
				printf "%s\n" "$line" >> "${thepwd}/fileListsAndDeps/${groupId}/${artifactId}/${version}/${groupId}.${artifactId}_${version}_vanilla.fileList"
			done
		fi


		if [ -d "${groupId}/${artifactId}/${version}/Decompiled" ]; then
			find "${groupId}/${artifactId}/${version}/Decompiled" -name "*.java" | while read line; do
				printf "%s\n" "$line" >> "${thepwd}/fileListsAndDeps/${groupId}/${artifactId}/${version}/${groupId}.${artifactId}_${version}_decompiled.fileList"
			done
		fi


	else
		printf "%s does not exist!\n" "${groupId}/${artifactId}/${version}"
	fi

done
