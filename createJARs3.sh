#!/bin/sh

if [ -d jars ]; then
	rm -rf jars/*
else
	mkdir jars
fi

find fileListsAndDeps -maxdepth 3 -mindepth 3 -type d | while read line; do
if [ -d workingDir ]; then
	rm -rf workingDir/*
else
	mkdir workingDir
fi

	find "$line" -name "*.fileList" | while read line2; do
		if [ -d "${line2%.fileList}" ]; then
			find "${line2%.fileList}/" | while read line3; do
				baseFile="$(printf "%s\n" "${line3}" | cut -d "/" -f 6-)"
					if [ -d "${line3}" ]; then
						if ! [ -d "${PWD}/workingDir/${baseFile}" ]; then
							#printf "Created Directory: %s\n" "${baseFile}" 
							mkdir "${PWD}/workingDir/${baseFile}"
						fi
					elif [ -f "${line3}" ]; then
						if ! [ -f "${PWD}/workingDir/${baseFile}" ]; then
							#printf "Added file: %s\n" "$line3"
							cp -a "$line3" "${PWD}/workingDir/${baseFile}"
						fi
					fi
			done
		fi
	done

metainf="sources/structure/$(printf "%s" "$line" | cut -d / -f 2)/$(printf "%s" "$line" | cut -d / -f 3)/$(printf "%s" "$line" | cut -d / -f 4)/extractedSources/META-INF"

if [ -d "$metainf" ]; then
cp -R --no-preserve=mode "${metainf}" "${PWD}/workingDir/"
fi

# create jar from workingDir
jarname="$(printf "%s" "$line" | cut -d / -f 2)_$(printf "%s" "$line" | cut -d / -f 3)_$(printf "%s" "$line" | cut -d / -f 4)_reconstructed.jar"
cd workingDir
if [ "$(find -maxdepth 1 | wc -l)" -gt "1" ]; then
	printf "Creating Jar: %s\n" "${jarname}"
	if [ -f META-INF/MANIFEST.MF ]; then
		jar cfm "${jarname}" META-INF/MANIFEST.MF ./*
	else
		jar cf "${jarname}" ./*
	fi
	mv "${jarname}" ../jars/
fi
cd ..
done

rm -rf workingDir
