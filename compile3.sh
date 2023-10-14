#!/bin/sh

J=2

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

			if [ "$1" = "jikes" ]; then
				#for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
				pexec -n $J -r $(find sources/structure -mindepth 3 -maxdepth 3 -type d) -e apackage -o - -c \
					'./functionCompileSources.sh "$apackage" "jikes"'
				#done
			else
				#for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
				pexec -n $J -r $(find sources/structure -mindepth 3 -maxdepth 3 -type d) -e apackage -o - -c \
					'./functionCompileSources.sh "$apackage"'
				#done
			fi

			newcount="$(find buildlog/ -mindepth 4 -maxdepth 4 -name "fromSource" -exec find {} -name "*.failed" \; | wc -l)"

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

		if [ "$1" = "jikes" ]; then
			#for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
				pexec -n $J -r $(find sources/structure -mindepth 3 -maxdepth 3 -type d) -e apackage -o - -c \
					'./functionGenerateHybrid.sh "$apackage" "jikes"'
			#done
		else
			#for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
				pexec -n $J -r $(find sources/structure -mindepth 3 -maxdepth 3 -type d) -e apackage -o - -c \
					'./functionGenerateHybrid.sh "$apackage" "$1"'
			#done
		fi

		newcount="$(find buildlog/ -mindepth 4 -maxdepth 4 -name "hybrids" -exec find {} -name "*.failed" \; | wc -l)"

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

	#for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
			pexec -n $J -r $(find sources/structure -mindepth 3 -maxdepth 3 -type d) -e apackage -o - -c \
				'./functionCompileDecompiled.sh $apackage DecompiledCFR'
	#done

	#for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
			pexec -n $J -r $(find sources/structure -mindepth 3 -maxdepth 3 -type d) -e apackage -o - -c \
				'./functionCompileDecompiled.sh $apackage DecompiledProcyon'
	#done

	newcount="$(find buildlog/ -mindepth 4 -maxdepth 4 -name "decompiledOnly" -exec find {} -name "*.failed" \; | wc -l)"

	if [ "$oldcount" = "$newcount" ]; then
		goagainone=0
		goagaintwo=0
		goagainthree=0
	else
		oldcount="$newcount"
		goagainfour=1
	fi
done