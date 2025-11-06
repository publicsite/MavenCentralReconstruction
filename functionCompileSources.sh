#!/bin/sh

OLD_UMASK="$(umask)"
umask 0022

thepwd="$PWD"

				apackage="$(echo "$1" | cut -d '/' -f 3-)"

				mkdir -p buildlog/$apackage/fromSource
				mkdir -p classes/$apackage/fromSource

				directories=""

				if [ -d "sources/structure/$apackage/extractedSources" ]; then
					for directory in $(find "sources/structure/$apackage/extractedSources" -type d); do
						directories="$directory:$directories"
					done

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

					for javafile in $(find "sources/structure/$apackage/extractedSources" -name *.java); do
						if ! [ -f buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success ]; then
							result=""
							if [ "$2" = "jikes" ]; then
								echo "jikes ${theClassPath} -d "classes/$apackage/fromSource" -sourcepath "$directories" $javafile"
								jikes ${theClassPath} -d "classes/$apackage/fromSource" $javafile 2>buildlog/$apackage/fromSource/$(basename "${javafile%.java}").failed
								result="$?"
							else
								echo "javac ${theClassPath} -d "classes/$apackage/fromSource" -sourcepath "$directories" $javafile"
								javac ${theClassPath} -d "classes/$apackage/fromSource" -sourcepath "$directories" $javafile 2>buildlog/$apackage/fromSource/$(basename "${javafile%.java}").failed
								result="$?"
							fi
							if [ "$result" = 0 ]; then
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

								if [ -f buildlog/$apackage/hybrids/$(basename "${javafile%.java}").success ]; then
									rm buildlog/$apackage/hybrids/$(basename "${javafile%.java}").success
								fi
								if [ -f buildlog/$apackage/hybrids/$(basename "${javafile%.java}").failed ]; then
									rm buildlog/$apackage/hybrids/$(basename "${javafile%.java}").failed
								fi
								if [ -f classes/$apackage/hybrids/$(basename "${javafile%.java}").class ]; then
									rm classes/$apackage/hybrids/$(basename "${javafile%.java}").class
								fi
								mv buildlog/$apackage/fromSource/$(basename "${javafile%.java}").failed buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success
							fi
						fi
					done
				fi

		umask "${OLD_UMASK}"
		
