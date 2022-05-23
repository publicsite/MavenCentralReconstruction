#!/bin/sh

if [ -d workingdir ]; then
rm -rf workingdir
fi

mkdir workingdir

for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
rm -rf workingdir/*
	apackage="$(echo "$apackage" | cut -d '/' -f 3-)"
	foundfiles=0

	complete=1

	if [ -d "sources/structure/$apackage/Decompiled" ]; then
		for javafile in $(find "sources/structure/$apackage/Decompiled" -name *.java); do
			mkdir -p "workingdir/"$(dirname "$(echo "$javafile" | cut -d '/' -f 7-)")""
			if ! [ -f "buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success" ]; then
				if ! [ -f "buildlog/$apackage/hybrids/$(basename "${javafile%.java}").success" ]; then
					if [ -f "buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success" ]; then
						cp -a "${javafile}" workingdir/$(dirname $(echo "$javafile" | cut -d '/' -f 7-))/
						echo "$(dirname $(echo "$javafile" | cut -d '/' -f 7-))/$(basename "${javafile}") came from a decompiled bin jar, and was then reproduced." >> workingdir/replica-origins.txt
						foundfiles=1
					else
						echo "$(dirname $(echo "$javafile" | cut -d '/' -f 7-))/$(basename "${javafile}") failed to be reproduced, so was scrubbed from this jar." >> workingdir/replica-origins.txt
						complete=0
					fi
				fi
			fi
		done
	fi

	if [ -d "sources/structure/$apackage/extractedSources" ]; then
		for javafile in $(find "sources/structure/$apackage/extractedSources" -name *.java); do
			mkdir -p "workingdir/"$(dirname "$(echo "$javafile" | cut -d '/' -f 7-)")""
			if [ -f "buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success" ]; then
				cp -a "${javafile}" workingdir/$(dirname $(echo "$javafile" | cut -d '/' -f 7-))/
				echo "$(dirname $(echo "$javafile" | cut -d '/' -f 7-))/$(basename "${javafile}") came from a sources jar, and was reproduced as-is." >> workingdir/replica-origins.txt
				foundfiles=1
			elif [ -f "buildlog/$apackage/hybrids/$(basename "${javafile%.java}").success" ]; then
				cp -a "hybrids/$apackage/$(basename "${javafile}")" workingdir/$(dirname $(echo "$javafile" | cut -d '/' -f 7-))/
				echo "$(dirname $(echo "$javafile" | cut -d '/' -f 7-))/$(basename "${javafile}") came from a sources jar but was patched, with sections taken from a decompiled bin jar, then reproduced." >> workingdir/replica-origins.txt
				foundfiles=1
			elif ! [ -f "buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success" ]; then
				echo "$(dirname $(echo "$javafile" | cut -d '/' -f 7-))/$(basename "${javafile}") failed to be reproduced, so was scrubbed from this jar." >> workingdir/replica-origins.txt
				complete=0
			fi
		done
	fi

	if [ -f "sources/structure/$apackage/extractedSources/META-INF/MANIFEST.MF" ]; then
		mkdir -p workingdir/META-INF
		cp -a "sources/structure/$apackage/extractedSources/META-INF/MANIFEST.MF" workingdir/META-INF/
	elif [ -f "sources/structure/$apackage/Decompiled/META-INF/MANIFEST.MF" ]; then
		mkdir -p workingdir/META-INF
		cp -a "sources/structure/$apackage/Decompiled/META-INF/MANIFEST.MF" workingdir/META-INF/
	fi

	jarname="$(echo $apackage | cut -d '/' -f 2)-$(echo $apackage | cut -d '/' -f 3)-sources.jar"

	mkdir -p outCleansedJars/jars/$apackage

	cd workingdir
	if [ "$foundfiles" = "1" ]; then

		if [ "$complete" = 1 ]; then
			echo "$apackage appears to be a complete reconstructed source jar" >> ../outCleansedJars/sourceJarsComplete.txt
		fi

		printf "Creating Jar: %s\n" "${jarname}"
		if [ -f "$PWD/META-INF/MANIFEST.MF" ]; then
			jar cfm "${jarname}" "$PWD/META-INF/MANIFEST.MF" ./*
		else
			jar cf "${jarname}" ./*
		fi
		mv "${jarname}" ../outCleansedJars/jars/$apackage/
	fi
	cd ..
done

rm -rf workingdir