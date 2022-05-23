#!/bin/sh

isNumeric(){
case $1 in
    ''|*[!0-9]*) echo bad ;;
    *) echo good ;;
esac
}


thepwd="$PWD"

goagainthree=1

while [ "$goagainthree" = "1" ]; do
	goagainthree=0

	goagaintwo=1
	while [ "$goagaintwo" = "1" ]; do
		goagaintwo=0


		#cycle one is for source-only stuff
		if [ -d buildlog ]; then
			oldcount="$(find buildlog/ -mindepth 4 -maxdepth 4 -name "fromSource" -exec find {} -name "*.failed" \; | wc -l)"
		else
			oldcount="0"
		fi
		goagainone=1
		while [ "$goagainone" = "1" ]; do
		newcount=0
		echo "CYCLE 1..."

			for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
				apackage="$(echo "$apackage" | cut -d '/' -f 3-)"

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
							else
								newcount="$(expr $newcount + 1)"
							fi
						fi
					done
				fi
			done

			if [ "$oldcount" = "$newcount" ]; then
				goagainone=0
			else
				oldcount="$newcount"
				goagaintwo=1
				goagainthree=1
				goagainfour=1
			fi
		done

		#cycle 2 is for making hybrids, a mix of both decompiled and source stuff
		if [ -d buildlog ]; then
			oldcount="$(find buildlog/ -mindepth 4 -maxdepth 4 -name "hybrids" -exec find {} -name "*.failed" \; | wc -l)"
		else
			oldcount="0"
		fi

		newcount=0

		echo "CYCLE 2..."

		for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
			apackage="$(echo "$apackage" | cut -d '/' -f 3-)"

			directories=""

			if [ -d "sources/structure/$apackage/extractedSources" ] && [ -d "sources/structure/$apackage/Decompiled" ]; then

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

					theClassPath=" --class-path ${theClassPath}"
				else
					theClassPath=" --class-path ${theClassPath}"
				fi

				theClassPath="$(printf "%s" "$theClassPath" | cut -c 2-)"

				for sourcejavafile in $(find sources/structure/${apackage}/extractedSources -name "*.java"); do
					if [ -f "buildlog/$apackage/fromSource/$(basename "${sourcejavafile%.java}").failed" ] && ! [ -f "buildlog/$apackage/hybrids/$(basename "${sourcejavafile%.java}").success" ]; then
						if [ -d "sources/structure/${apackage}/Decompiled" ]; then 
							decompiledjavafile="$(find sources/structure/${apackage}/Decompiled -name $(basename ${sourcejavafile}) | head -n 1)"
							if [ "$decompiledjavafile" != "" ]; then

								echo "Attempting to make a hybrid for ${sourcejavafile}"

								mkdir -p buildlog/${apackage}/hybrids/
								cp -a "buildlog/$apackage/fromSource/$(basename "${sourcejavafile%.java}").failed" buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed

								numberOfErrors="-1"
								oldAmountOfErrors=999999
								while [ "oldAmountOfErrors" != "$numberOfErrors" ]; do
									mkdir -p hybrids/${apackage}
									./generateHybridFile.sh buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed $sourcejavafile $decompiledjavafile "$PWD" > hybrids/${apackage}/$(basename ${sourcejavafile})
									javac ${theClassPath} -d "classes/$apackage/fromSource" -sourcepath "$directories" hybrids/${apackage}/$(basename ${sourcejavafile}) 2>buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed
									if [ "$?" = 0 ]; then
										if [ -f buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success ]; then
											rm buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success
										fi
										if [ -f buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed ]; then
											rm buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed
										fi
										if [ -f classes/$apackage/decompiledOnly/$(basename "${javafile%.java}").class ]; then
											rm classes/$apackage/decompiledOnly/$(basename "${javafile%.java}").class
										fi

										mv "buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed" "buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").success"
										break
									else
										newcount="$(expr $newcount + 1)"
									fi
									oldAmountOfErrors="$numberOfErrors"

									numberOfErrors="$(tail -n 1 "buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed" | cut -d " " -f 1)"

									if [ "$(isNumeric ${numberOfErrors})" = "bad" ] || [ "${numberOfErrors}" = "" ]  ; then
										break
									fi
								done
							fi
						fi
					fi
				done
			fi
		done

		if [ "$oldcount" = "$newcount" ]; then
			goagainone=0
			goagaintwo=0
		else
			oldcount="$newcount"
			goagainthree=1
			goagainfour=1
		fi
	done

	#cycle 3 is for decompiled stuff
	if [ -d buildlog ]; then
		oldcount="$(find buildlog/ -mindepth 4 -maxdepth 4 -name "decompiledOnly" -exec find {} -name "*.failed" \; | wc -l)"
	else
		oldcount="0"
	fi

	newcount=0
	echo "CYCLE 3..."

	for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
		apackage="$(echo "$apackage" | cut -d '/' -f 3-)"

		mkdir -p buildlog/$apackage/decompiledOnly
		mkdir -p classes/$apackage/decompiledOnly

		directories=""


		if [ -d "sources/structure/$apackage/Decompiled" ]; then


			if [ -d "sources/structure/$apackage/extractedSources" ]; then
				#we use the extractedSources source path if it exists
				for directory in $(find "sources/structure/$apackage/extractedSources" -type d); do
					directories="$directory:$directories"
				done
			else
				#otherwise we use the decompiled source path
				for directory in $(find "sources/structure/$apackage/Decompiled" -type d); do
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

				theClassPath=" --class-path ${theClassPath}"
			else
				theClassPath=" --class-path ${theClassPath}"
			fi

			theClassPath="$(printf "%s" "$theClassPath" | cut -c 2-)"

			for javafile in $(find "sources/structure/$apackage/Decompiled" -name *.java); do
				if ! [ -f buildlog/$apackage/fromSource/$(basename "${javafile%.java}").success ] && ! [ -f buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success ] && ! [ -f buildlog/$apackage/hybrids/$(basename "${javafile%.java}").success ]; then
					echo "javac -d "classes/$apackage/decompiledOnly" "${theClassPath}" -sourcepath "$directories" $javafile"
					javac ${theClassPath} -d "classes/$apackage/decompiledOnly" -sourcepath "$directories" $javafile 2>buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed
					if [ "$?" = 0 ]; then
						mv buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").failed buildlog/$apackage/decompiledOnly/$(basename "${javafile%.java}").success
					else
						newcount="$(expr $newcount + 1)"
					fi
				fi
			done
		fi
	done

	if [ "$oldcount" = "$newcount" ]; then
		goagainone=0
		goagaintwo=0
		goagainthree=0
	else
		oldcount="$newcount"
		goagainfour=1
	fi
done