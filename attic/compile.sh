#!/bin/sh

thepwd="$PWD"

mastergoagain=1

while [ "$mastergoagain" = "1" ]; do
	mastergoagain=0


	#cycle one is for source-only stuff
	if [ -d buildlog ]; then
		oldcount="$(find buildlog/ -mindepth 4 -maxdepth 4 -name "fromSource" -exec find {} -name "*.failed" \; | wc -l)"
	else
		oldcount="0"
	fi
	goagain=1
	while [ "$goagain" = "1" ]; do
	newcount=0
	echo "CYCLE 1..."

		for apackage in $(find sources/structure -type d -mindepth 3 -maxdepth 3); do
			apackage="$(echo "$apackage" | cut -d '/' -f 3-)"

			mkdir -p buildlog/$apackage/fromSource
			mkdir -p classes/$apackage/fromSource

			directories=""

			for directory in $(find "sources/structure/$apackage/extractedSources" -type d); do
				directories="$directory:$directories"
			done

			theClassPath="${thepwd}/classes/${apackage}/fromSource:${thepwd}/classes/${apackage}/decompiledOnly"

			if [ -f "${thepwd}/sources/structure/${apackage}/dependencies.txt" ]; then

				oldIFS="$IFS"
				IFS="$(printf "\n")"
				while read line2; do
					theClassPath="${theClassPath}:${thepwd}/classes/${line2}/fromSource:${thepwd}/classes/${line2}/decompiledOnly"
				done < "${thepwd}/sources/structure/${apackage}/dependencies.txt"
				IFS="$oldIFS"

				theClassPath=" --class-path ${theClassPath}"
			else
				theClassPath=" --class-path ${theClassPath}"
			fi

			theClassPath="$(printf "%s" "$theClassPath" | cut -c 2-)"

			for javafile in $(find "sources/structure/$apackage/extractedSources" -name *.java); do
				if ! [ -f buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success ]; then
					echo "javac -d "classes/$apackage/fromSource" "${theClassPath}" -sourcepath "$directories" $javafile"
					javac ${theClassPath} -d "classes/$apackage/fromSource" -sourcepath "$directories" $javafile 2>buildlog/$apackage/fromSource/$(basename "${javafile%.java}").failed
					if [ "$?" = 0 ]; then
						#as the source build succeded, we delete logs for any decompiled builds and we also delete the decompiled class file if it exists
						if [ -f buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success ]; then
							rm buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success
						fi
						if [ -f buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed ]; then
							rm buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed
						fi
						if [ -f classes/$apackage/decompiledOnly/$(basename "${javafile%.java}").class ]; then
							rm classes/$apackage/decompiledOnly/$(basename "${javafile%.java}").class
						fi
						mv buildlog/$apackage/fromSource/$(basename "${javafile%.java}").failed buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success
					else
						newcount="$(expr $newcount + 1)"
					fi
				fi
			done
		done

		if [ "$oldcount" = "$newcount" ]; then
			goagain=0
		else
			oldcount="$newcount"
			mastergoagain=1
		fi
	done


	#cycle 3 is for decompiled stuff
	if [ -d buildlog ]; then
		oldcount="$(find buildlog/ -mindepth 4 -maxdepth 4 -name "decompiledOnly" -exec find {} -name "*.failed" \; | wc -l)"
	else
		oldcount="0"
	fi
	goagain=1
	while [ "$goagain" = "1" ]; do
	newcount=0
	echo "CYCLE 3..."

		for apackage in $(find sources/structure -mindepth 3 -type d -maxdepth 3); do
			apackage="$(echo "$apackage" | cut -d '/' -f 3-)"

			mkdir -p buildlog/$apackage/decompiledOnly
			mkdir -p classes/$apackage/decompiledOnly

			directories=""


			if [ -d "sources/structure/$apackage/extractedSources" ]; then
				#we use the extractedSources source path if it exists
				for directory in $(find "sources/structure/$apackage/extractedSources" -type d); do
					directories="$directory:$directories"
				done
			else
				#otherwise we use the decompiled source path
				for directory in $(find "sources/structure/$apackage/decompiled" -type d); do
					directories="$directory:$directories"
				done
			fi

			theClassPath="${thepwd}/classes/${apackage}/fromSource:${thepwd}/classes/${apackage}/decompiledOnly"

			if [ -f "${thepwd}/sources/structure/${apackage}/dependencies.txt" ]; then

				oldIFS="$IFS"
				IFS="$(printf "\n")"
				while read line2; do
					theClassPath="${theClassPath}:${thepwd}/classes/${line2}/fromSource:${thepwd}/classes/${line2}/decompiledOnly"
				done < "${thepwd}/sources/structure/${apackage}/dependencies.txt"
				IFS="$oldIFS"

				theClassPath=" --class-path ${theClassPath}"
			else
				theClassPath=" --class-path ${theClassPath}"
			fi

			theClassPath="$(printf "%s" "$theClassPath" | cut -c 2-)"

			for javafile in $(find "sources/structure/$apackage/decompiled" -name *.java); do
				if ! [ -f buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success ] && ! [ -f buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success ]; then
					echo "javac -d "classes/$apackage/decompiledOnly" "${theClassPath}" -sourcepath "$directories" $javafile"
					javac ${theClassPath} -d "classes/$apackage/decompiledOnly" -sourcepath "$directories" $javafile 2>buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed
					if [ "$?" = 0 ]; then
						mv buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success
					else
						newcount="$(expr $newcount + 1)"
					fi
				fi
			done
		done

		if [ "$oldcount" = "$newcount" ]; then
			goagain=0
		else
			oldcount="$newcount"
			mastergoagain=1
		fi
	done
done