#!/bin/sh

OLD_UMASK="$(umask)"
umask 0022

if [ -d workingdir ]; then
rm -rf workingdir
fi

mkdir workingdir

for apackage in $(find sources/structure -mindepth 3 -maxdepth 3 -type d); do
rm -rf workingdir/*
	apackage="$(echo "$apackage" | cut -d '/' -f 3-)"
	foundfiles=0

	if [ -d "classes/$apackage/fromSource" ]; then
		for classfile in $(find "classes/$apackage/fromSource" -name *.class); do
			if ! [ -f "buildlog/$apackage/fromSource/$(basename ${classfile%.class}).failed" ]; then
				mkdir -p "$(dirname "workingdir/$(echo "$classfile" | cut -d '/' -f 6-)")"
				cp "$classfile" "workingdir/$(echo "$classfile" | cut -d '/' -f 6-)"
				echo "$(echo "$classfile" | cut -d '/' -f 6-) came from a sources jar, and was reproduced as-is." >> workingdir/replica-origins.txt
				foundfiles=1
			fi
		done
	fi

	if [ -d "classes/$apackage/hybrids" ]; then
		for classfile in $(find "classes/$apackage/hybrids" -name *.class); do
			if ! [ -f "buildlog/$apackage/hybrids/$(basename ${classfile%.class}).failed" ]; then
				mkdir -p "$(dirname "workingdir/$(echo "$classfile" | cut -d '/' -f 6-)")"
				if ! [ -f "workingdir/$(echo "$classfile" | cut -d '/' -f 6-)" ]; then 
					cp "$classfile" "workingdir/$(echo "$classfile" | cut -d '/' -f 6-)"
					echo "$(echo "$classfile" | cut -d '/' -f 6-) came from a sources jar but was patched, with sections taken from a decompiled bin jar, then reproduced." >> workingdir/replica-origins.txt
					foundfiles=1
				fi
			fi
		done
	fi

	if [ -d "classes/$apackage/decompiledOnly" ]; then
		for classfile in $(find "classes/$apackage/decompiledOnly" -name *.class); do
			if ! [ -f "buildlog/$apackage/decompiledOnly/$(basename ${classfile%.class}).failed" ]; then
				mkdir -p "$(dirname "workingdir/$(echo "$classfile" | cut -d '/' -f 6-)")"
				if ! [ -f "workingdir/$(echo "$classfile" | cut -d '/' -f 6-)" ]; then 
					cp "$classfile" "workingdir/$(echo "$classfile" | cut -d '/' -f 6-)"
					echo "$(echo "$classfile" | cut -d '/' -f 6-) came from a decompiled bin jar, and was then reproduced." >> workingdir/replica-origins.txt
					foundfiles=1
				fi
			fi
		done
	fi

	complete=1

#tell the user about files that were not included


	if [ -d "sources/structure/$apackage/extractedSources" ]; then
		for checkin in $(find "sources/structure/$apackage/extractedSources" -type f -name "*.java"); do
			if ! [ -f "buildlog/$apackage/fromSource/$(basename ${checkin%.java}).success" ]; then
				if ! [ -f "buildlog/$apackage/hybrids/$(basename "${checkin%.java}").success" ]; then
					if ! [ -f "buildlog/$apackage/decompiledOnly/$(basename "${checkin%.java}").success" ]; then
						echo "$(echo $checkin | cut -d '/' -f 7-) failed to be compiled, so was scrubbed from this jar." >> workingdir/replica-origins.txt
						complete=0
					fi
				fi
			fi
		done
	fi

	if [ -d "sources/structure/$apackage/Decompiled" ]; then
		for checkin in $(find "sources/structure/$apackage/Decompiled" -type f -name "*.java"); do
			if ! [ -f "buildlog/$apackage/fromSource/$(basename ${checkin%.java}).success" ]; then
				if ! [ -f "buildlog/$apackage/hybrids/$(basename "${checkin%.java}").success" ]; then
					if ! [ -f "buildlog/$apackage/decompiledOnly/$(basename "${checkin%.java}").success" ]; then
						if ! [ -f "buildlog/$apackage/fromSource/$(basename ${checkin%.java}).failed" ]; then
							echo "$(echo $checkin | cut -d '/' -f 7-) failed to be compiled, so was scrubbed from this jar." >> workingdir/replica-origins.txt
							complete=0
						fi
					fi
				fi
			fi
		done
	fi

#create manifest if it exist

	if [ -f "sources/structure/$apackage/Decompiled/META-INF/MANIFEST.MF" ]; then
		mkdir -p workingdir/META-INF

		#copy the file excluding blank lines
		oldIFS="$IFS"
		IFS="\n"
		cat "sources/structure/$apackage/Decompiled/META-INF/MANIFEST.MF" | while read manifestline; do
			if [ "$(echo "$manifestline" | grep "^[[:space:]]*$")" = "" ]; then
				echo "$manifestline" >> workingdir/META-INF/MANIFEST.MF
			fi
		done
		IFS="$oldIFS"
	elif [ -f "sources/structure/$apackage/extractedSources/META-INF/MANIFEST.MF" ]; then
		mkdir -p workingdir/META-INF

		#copy the file excluding blank lines
		oldIFS="$IFS"
		IFS="\n"
		cat "sources/structure/$apackage/extractedSources/META-INF/MANIFEST.MF" | while read manifestline; do
			if [ "$(echo "$manifestline" | grep "^[[:space:]]*$")" = "" ]; then
				echo "$manifestline" >> workingdir/META-INF/MANIFEST.MF
			fi
		done
		IFS="$oldIFS"
	fi

	#append the main class to the jar
	themainclass=""
	if [ -f workingdir/META-INF/MANIFEST.MF ]; then
		if [ "$(grep "^Main-Class:" workingdir/META-INF/MANIFEST.MF | cut -d : -f2- | tr -d ' ')" = "" ]; then
			themainclass="$(grep -o "<mainClass>.*<\/mainClass>" sources/structure/$apackage/*.pom | cut -d ">" -f2 | cut -d "<" -f1 | head -n 1)"
			if [ "$themainclass" != "" ]; then
				echo "Main-Class: ${themainclass}" >> workingdir/META-INF/MANIFEST.MF
			fi
		fi
	else
		themainclass="$(grep -o "<mainClass>.*<\/mainClass>" sources/structure/$apackage/*.pom | cut -d ">" -f2 | cut -d "<" -f1 | head -n 1)"
		if [ "$themainclass" != "" ]; then
			echo "Main-Class: ${themainclass}" >> workingdir/META-INF/MANIFEST.MF
		fi
	fi

	jarname="$(echo $apackage | cut -d '/' -f 2)-$(echo $apackage | cut -d '/' -f 3).jar"

	mkdir -p outCleansedJars/jars/$apackage

	cd workingdir
	if [ "$foundfiles" = "1" ]; then

		if ! [ -f "../outCleansedJars/jars/$apackage/$(echo $apackage | cut -d '/' -f 2)-$(echo $apackage | cut -d '/' -f 3).pom" ]; then
			if [ -f "../sources/structure/$apackage/$(echo $apackage | cut -d '/' -f 2)-$(echo $apackage | cut -d '/' -f 3).pom" ]; then
				cp -a "../sources/structure/$apackage/$(echo $apackage | cut -d '/' -f 2)-$(echo $apackage | cut -d '/' -f 3).pom" "../outCleansedJars/jars/$apackage/$(echo $apackage | cut -d '/' -f 2)-$(echo $apackage | cut -d '/' -f 3).pom"
			fi
		fi

		if [ "$complete" = 1 ]; then
			if [ ! -f ../outCleansedJars/binJarsComplete.txt ]; then
				echo "$apackage appears to be a complete reconstructed bin jar" >> ../outCleansedJars/binJarsComplete.txt
			else
				if [ "$(grep "^${apackage} " ../outCleansedJars/binJarsComplete.txt)" = "" ]; then
					echo "$apackage appears to be a complete reconstructed bin jar" >> ../outCleansedJars/binJarsComplete.txt
				fi
			fi
		fi

		printf "Creating Jar: %s\n" "${jarname}"
		if [ -f "$PWD/META-INF/MANIFEST.MF" ]; then
			jar cfm "${jarname}" "$PWD/META-INF/MANIFEST.MF" ./*
		else
			jar cf "${jarname}" ./*
		fi
		mv "${jarname}" ../outCleansedJars/jars/$apackage
	fi
	cd ..
done

rm -rf workingdir

umask "${OLD_UMASK}"
