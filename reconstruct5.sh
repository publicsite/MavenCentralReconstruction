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

			find -L "${groupId}/${artifactId}/${version}/extractedSources" -name "*.java" | while read line; do
				printf "$line\n"
				lineNoComments="$(sed '/\/\*.*\*\// d; /\/\*/,/\*\// d' "$line")"

				packageName="$(printf "%s\n" "$lineNoComments" | grep "^\s*package " | cut -c 9- | cut -d ";" -f 1)"

				className="$(printf "%s\n" "$lineNoComments" | grep -o "^.*\s*class .*" | head -n 1 | cut -d " " -f 2 | cut -d "<" -f 1 | cut -d "{" -f 1 | cut -d "(" -f 1 | tr -d '\n' | sed "s#\r##g" )"

				if [ "${packageName}" != "" ]; then

				if [ "${className}" = "" ]; then
					className="$(printf "%s\n" "$lineNoComments" | grep -o "^.*\s*interface .*" | head -n 1 | cut -d " " -f 3 | cut -d "<" -f 1 | cut -d "{" -f 1 | cut -d "(" -f 1 | tr -d '\n' | sed "s#\r##g")"
				fi

				if [ "${className}" = "" ]; then
					className="zzzunknownclass"
				fi

				printf "%s\n" "$line" >> "${thepwd}/fileListsAndDeps/${groupId}/${artifactId}/${version}/${packageName}.${className}_vanilla.fileList"

				fi
			done
		fi


		if [ -d "${groupId}/${artifactId}/${version}/Decompiled" ]; then

			find -L "${groupId}/${artifactId}/${version}/Decompiled" -name "*.java" | while read line; do
				printf "$line\n"
				lineNoComments="$(sed '/\/\*.*\*\// d; /\/\*/,/\*\// d' "$line")"

				packageName="$(printf "%s\n" "$lineNoComments" | grep "^\s*package " | cut -c 9- | cut -d ";" -f 1)"

				className="$(printf "%s\n" "$lineNoComments" | grep -o "^.*\s*class .*" | head -n 1 | cut -d " " -f 2 | cut -d "<" -f 1 | cut -d "{" -f 1 | cut -d "(" -f 1 | tr -d '\n' | sed "s#\r##g" )"

				if [ "${packageName}" != "" ]; then

				if [ "${className}" = "" ]; then
					className="$(printf "%s\n" "$lineNoComments" | grep -o "^.*\s*interface .*" | head -n 1 | cut -d " " -f 3 | cut -d "<" -f 1 | cut -d "{" -f 1 | cut -d "(" -f 1 | tr -d '\n' | sed "s#\r##g")"
				fi

				if [ "${className}" = "" ]; then
					className="zzzunknownclass"
				fi

					if ! [ -f "${thepwd}/fileListsAndDeps/${groupId}/${artifactId}/${version}/${packageName}.${className}_vanilla.fileList" ]; then
						printf "%s\n" "$line" >> "${thepwd}/fileListsAndDeps/${groupId}/${artifactId}/${version}/${packageName}.${className}_decompiled.fileList"
					else
						printf "%s\n" "$line" >> "${thepwd}/fileListsAndDeps/${groupId}/${artifactId}/${version}/${packageName}.${className}_decompiled.secondary.fileList"
					fi
				fi
			done
		fi


	else
		printf "%s does not exist!\n" "${groupId}/${artifactId}/${version}"
	fi

done
