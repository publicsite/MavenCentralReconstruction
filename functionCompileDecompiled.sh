#!/bin/sh
echo "$2"

thepwd="$PWD"

		apackage="$(echo "$1" | cut -d '/' -f 3-)"

		mkdir -p buildlog/$apackage/decompiledOnly
		mkdir -p classes/$apackage/decompiledOnly

		directories=""


		if [ -d "sources/structure/$apackage/${2}" ]; then


			if [ -d "sources/structure/$apackage/extractedSources" ]; then
				#we use the extractedSources source path if it exists
				for directory in $(find "sources/structure/$apackage/extractedSources" -type d); do
					directories="$directory:$directories"
				done
			else
				#otherwise we use the decompiled source path
				for directory in $(find "sources/structure/$apackage/${2}" -type d); do
					directories="$directory:$directories"
				done
			fi

			theClassPath="${thepwd}/classes/${apackage}/fromSource:${thepwd}/classes/${apackage}/hybrids:${thepwd}/classes/${apackage}/decompiledOnly"

			if [ -f "${thepwd}/sources/structure/${apackage}/dependencies.txt" ]; then

				oldIFS="$IFS"
				IFS="$(printf "\n")"
				while read line2; do
					theClassPath="${theClassPath}:${thepwd}/classes/${line2}/fromSource:${thepwd}/classes/${apackage}/hybrids:${thepwd}/classes/${line2}/decompiledOnly"
				done < "${thepwd}/sources/structure/${apackage}/dependencies.txt"
				IFS="$oldIFS"

				theClassPath=" -classpath ${theClassPath}"
			else
				theClassPath=" -classpath ${theClassPath}"
			fi

			theClassPath="$(printf "%s" "$theClassPath" | cut -c 2-)"

			for javafile in $(find "sources/structure/$apackage/${2}" -name *.java); do
				if ! [ -f buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success ] && ! [ -f buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success ] && ! [ -f buildlog/$apackage/hybrids/$(basename "${javafile%.java}").success ]; then
					result=""
					if [ "$2" = "jikes" ]; then
						echo "jikes ${theClassPath} -d "classes/$apackage/decompiledOnly" $javafile"
						jikes ${theClassPath} -d "classes/$apackage/decompiledOnly" $javafile 2>buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed
						result="$?"
					else
						echo "javac ${theClassPath} -d "classes/$apackage/decompiledOnly" -sourcepath "$directories" $javafile"
						javac ${theClassPath} -d "classes/$apackage/decompiledOnly" -sourcepath "$directories" $javafile 2>buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed
						result="$?"
					fi
					if [ "$result" = 0 ]; then
						mv buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success
					fi
				fi
			done
		fi