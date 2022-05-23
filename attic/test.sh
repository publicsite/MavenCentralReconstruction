#!/bin/sh

isNumeric(){
case $1 in
    ''|*[!0-9]*) echo bad ;;
    *) echo good ;;
esac
}

thepwd="$PWD"

for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
	apackage="$(echo "$apackage" | cut -d '/' -f 3-)"

	for sourcejavafile in $(find sources/structure/${apackage}/extractedSources -name "*.java"); do
		if [ -f "buildlog/$apackage/fromSource/$(basename "${sourcejavafile%.java}").failed" ]; then
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
						javac hybrids/${apackage}/$(basename ${sourcejavafile}) 2>buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed
						if [ "$?" = 0 ]; then
							mv "buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed" "buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").success"
							break
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
done