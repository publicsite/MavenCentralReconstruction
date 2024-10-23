#!/bin/sh
#arg1: groupId
#arg2: artifactId
#arg3: version
#arg4: groupId of parent
#arg5: artifactId of parent
#arg6: version of parent

recurse(){
toappend="$1"
find "$2" -maxdepth 1 -mindepth 1 -type d | while read line; do
if [ -f "$line/build.gradle.kts" ]; then
echo "${line}/build.gradle.kts" | cut -c 3-
else
thisfolder="$(echo $line | cut -c 3-)"
recurse . "${toappend}/${thisfolder}"
fi
done
}

thepwd="$PWD"
OLDIFS="$IFS"

if [ ! -f "pom.xml" ]; then

	printf "<project>\n" >> pom.xml

	if [ "$4" != "" ] && [ "$5" != "" ] && [ "$6" != "" ]; then
		printf "\t<parent>\n\t\t<groupId>%s</groupId>\n\t\t<artifactId>%s</artifactId>\n\t\t<version>%s</version>\n\t</parent>\n" "$4" "$5" "$6" >> pom.xml
	fi

	if [ -f "gradle.properties" ]; then
		astring="$(grep -o "APP_PACKAGE=.*$" gradle.properties | cut -c 13-)"

		groupId="$(echo $astring | rev | cut -d '.' -f 2- | rev)"


		artifactId="$(echo $astring | rev | cut -d '.' -f 1 | rev)"


		version="$(grep -o "APP_VERSION_NAME=.*$" gradle.properties | cut -c 18-)"

	fi

	if [ "$1" != "" ]; then
		groupId="$1"
	fi

	if [ "$2" != "" ]; then
		artifactId="$2"
	fi

	if [ "$3" != "" ]; then
		version="$3"
	fi

	echo "\t<groupId>$groupId</groupId>" >> pom.xml
	echo "\t<artifactId>$artifactId</artifactId>" >> pom.xml
	echo "\t<version>$version</version>" >> pom.xml

	#print repositories

	first=0
	repositories="$(cat build.gradle.kts | tr '\n' '^' | grep -o "\^repositories.*{.*}" | cut -d "}" -f1)"
	repositories="$(printf "$repositories " | tr '^' '\n')"
export IFS='
'
	repositoriestoprint=""

	for line in $(printf "%s" "$repositories"); do
		line="$(echo $line | sed "s#^[[:space:]]*##g" )"
		if [ "$(echo "$line" | grep "[[:alnum:]]")" != "" ]; then
			if [ "$line" = "mavenCentral()" ]; then

				repositoriestoprint="${repositoriestoprint}\t\t<repository>\n"
				repositoriestoprint="${repositoriestoprint}\t\t\t<url>https://repo1.maven.org/maven2/</url>\n"
				repositoriestoprint="${repositoriestoprint}\t\t</repository>\n"
				first=1
			elif [ "$line" = "google()" ]; then
				repositoriestoprint="${repositoriestoprint}\t\t<repository>\n"
				repositoriestoprint="${repositoriestoprint}\t\t\t<url>https://dl.google.com/android/maven2/</url>\n"
				repositoriestoprint="${repositoriestoprint}\t\t</repository>\n"
				first=1
			elif [ "$(echo "$line" | grep -o "[[:alnum:]].*$" | cut -c 1-3)" = "url" ]; then
				repo="$(echo "$line" | cut -d '"' -f 2)"
				if [ $repo = "" ]; then
				repo="$(echo "$line" | cut -d "\'" -f 2)"
			fi
				repositoriestoprint="${repositoriestoprint}\t\t<repository>\n"
				repositoriestoprint="${repositoriestoprint}\t\t\t<url>$repo</url>\n"
				repositoriestoprint="${repositoriestoprint}\t\t</repository>\n"
				first=1
			fi
		fi
	done

	#if [ "$4" != "" ]; then
	#	repositoriestoprint="${repositoriestoprint}$(printf "%s" "${4}" | tr "^" "\n")"
	#	first=1
	#fi

	if [ "$first" = 1 ]; then
		echo "\t<repositories>\n${repositoriestoprint}\t</repositories>" >> pom.xml
	fi

	export IFS="$OLDIFS"

#handle submodules

	modulesString=""

	if [ -f settings.gradle ]; then
		
export IFS='
'
		for line in $(recurse . .); do
		submodule="$(dirname "$line")"

		oldpwd="$PWD"
			if [ -d "$submodule" ]; then
				modulesString="${modulesString}\t\t<module>${submodule}</module>\n"
				cd "$submodule"
				${thepwd}/convert.sh "$groupId" "${submodule}" "$version" "$groupId" "$artifactId" "$version" #"$(printf "%s" "${repositoriestoprint}" | tr '\n' '^')"
				cd "$oldpwd"
			fi
		done
		export IFS="$OLDIFS"
	fi

	if [ "$modulesString" != "" ]; then
		printf "\t<modules>\n" >> pom.xml
		printf "$modulesString" >> pom.xml
		printf "\t</modules>\n" >> pom.xml
	fi

#print dependencies
	printf "\t<dependencies>\n" >> pom.xml

	#we don't look for "classpath" keyword, as that is in the buildscript block and not in the root block
	#the buildscript block is not for dependencies your project depends on and are only for the build
	#instead, we find the "compile" keyword at the root of the build.grade script
	#I think this block is fixed for kts
	cat build.gradle.kts \
	| grep -o "[[:alnum:]].*$" \
	| grep -i "compile "\
	| sed -e "s/^compile //Ig" -e "s/^testCompile //Ig"\
	| sed -e "s/\/\/.*//g"\
	| sed -e "s/files(.*//g"\
	| grep -v ^$\
	| tr -d "\""\
	| tr -d "("\
	| tr -d ")"\
	| sed -e "s/\([-_[:alnum:]\.]*\):\([-_[:alnum:]\.]*\):\([-+_[:alnum:]\.]*\)/\t\t<dependency>\n\t\t\t<groupId>\1<\/groupId>\n\t\t\t<artifactId>\2<\/artifactId>\n\t\t\t<version>\3<\/version>\n\t\t<\/dependency>/g" >> pom.xml
	
	#I think this block is fixed for kts
	cat build.gradle.kts | grep -o "[[:alnum:]].*$" \
	| grep -i "^api[[:space:]]*([[:space:]]*\""\
	| cut -d '(' -f 2 \
	| sed -e "s/^api //Ig" -e "s/^testCompile //Ig"\
	| sed -e "s/\/\/.*//g"\
	| sed -e "s/files(.*//g"\
	| grep -v ^$\
	| tr -d "\""\
	| tr -d "("\
	| tr -d ")"\
	| sed -e "s/\([-_[:alnum:]\.]*\):\([-_[:alnum:]\.]*\):\([-+_[:alnum:]\.]*\)/\t\t<dependency>\n\t\t\t<groupId>\1<\/groupId>\n\t\t\t<artifactId>\2<\/artifactId>\n\t\t\t<version>\3<\/version>\n\t\t<\/dependency>/g" >> pom.xml

	#I think this block is fixed for kts
	cat build.gradle.kts | grep -o "[[:alnum:]].*$" \
	| grep -i "^implementation[[:space:]]*([[:space:]]*\""\
	| cut -d '(' -f 2 \
	| sed -e "s/^implementation //Ig" -e "s/^testCompile //Ig"\
	| sed -e "s/\/\/.*//g"\
	| sed -e "s/files(.*//g"\
	| grep -v ^$\
	| tr -d "\""\
	| tr -d "("\
	| tr -d ")"\
	| sed -e "s/\([-_[:alnum:]\.]*\):\([-_[:alnum:]\.]*\):\([-+_[:alnum:]\.]*\)/\t\t<dependency>\n\t\t\t<groupId>\1<\/groupId>\n\t\t\t<artifactId>\2<\/artifactId>\n\t\t\t<version>\3<\/version>\n\t\t<\/dependency>/g" >> pom.xml

	#this is a new block for kts
	cat build.gradle.kts | grep -o "[[:alnum:]].*$" \
	| grep -i "^db[[:space:]]*([[:space:]]*\""\
	| cut -d '(' -f 2 \
	| sed -e "s/^db //Ig" -e "s/^testCompile //Ig"\
	| sed -e "s/\/\/.*//g"\
	| sed -e "s/files(.*//g"\
	| grep -v ^$\
	| tr -d "\""\
	| tr -d "("\
	| tr -d ")"\
	| sed -e "s/\([-_[:alnum:]\.]*\):\([-_[:alnum:]\.]*\):\([-+_[:alnum:]\.]*\)/\t\t<dependency>\n\t\t\t<groupId>\1<\/groupId>\n\t\t\t<artifactId>\2<\/artifactId>\n\t\t\t<version>\3<\/version>\n\t\t<\/dependency>/g" >> pom.xml

	#this is a new block for kts
	cat build.gradle.kts | grep -o "[[:alnum:]].*$" \
	| grep -i "integTestImplementation[[:space:]]*([[:space:]]*\""\
	| sed -e "s/^integTestImplementation //Ig" -e "s/^testCompile //Ig"\
	| sed -e "s/\/\/.*//g"\
	| sed -e "s/files(.*//g"\
	| grep -v ^$\
	| tr -d "\""\
	| tr -d "("\
	| tr -d ")"\
	| sed -e "s/\([-_[:alnum:]\.]*\):\([-_[:alnum:]\.]*\):\([-+_[:alnum:]\.]*\)/\t\t<dependency>\n\t\t\t<groupId>\1<\/groupId>\n\t\t\t<artifactId>\2<\/artifactId>\n\t\t\t<version>\3<\/version>\n\t\t<\/dependency>/g" >> pom.xml

	#I think this block is fixed for kts
	internalps="$(cat build.gradle.kts | grep -o "[[:alnum:]].*$" \
	| grep -i "implementation[[:space:]]project" \
	| sed -e "s/^implementation[[:space:]]project//Ig" -e "s/^testCompile //Ig" \
	| cut -d ':' -f2 | cut -d "\"" -f1)"

	echo "$internalps" | while read line; do
		if [ "$line" != "" ]; then
			printf "\t\t<dependency>\n\t\t\t<groupId>%s</groupId>\n\t\t\t<artifactId>%s</artifactId>\n\t\t\t<version>%s</version>\n\t\t</dependency>\n" "${groupId}" "${line}" "${version}" >> pom.xml
		fi
	done

	#I think this block is fixed for kts
	cat build.gradle.kts \
	| grep -o "[[:alnum:]].*$" \
	| grep -i "compileOnly "\
	| sed -e "s/^compileOnly //Ig" -e "s/^testCompile //Ig"\
	| sed -e "s/\/\/.*//g"\
	| sed -e "s/files(.*//g"\
	| grep -v ^$\
	| tr -d "\""\
	| tr -d "("\
	| tr -d ")"\
	| sed -e "s/\([-_[:alnum:]\.]*\):\([-_[:alnum:]\.]*\):\([-+_[:alnum:]\.]*\)/\t\t<dependency>\n\t\t\t<groupId>\1<\/groupId>\n\t\t\t<artifactId>\2<\/artifactId>\n\t\t\t<version>\3<\/version>\n\t\t<\/dependency>/g" >> pom.xml

	#I think this block is fixed for kts
	cat build.gradle.kts \
	| grep -o "[[:alnum:]].*$" \
	| grep -i "coreLibraryDesugaring "\
	| sed -e "s/^coreLibraryDesugaring //Ig" -e "s/^testCompile //Ig"\
	| sed -e "s/\/\/.*//g"\
	| sed -e "s/files(.*//g"\
	| grep -v ^$\
	| tr -d "\""\
	| tr -d "("\
	| tr -d ")"\
	| sed -e "s/\([-_[:alnum:]\.]*\):\([-_[:alnum:]\.]*\):\([-+_[:alnum:]\.]*\)/\t\t<dependency>\n\t\t\t<groupId>\1<\/groupId>\n\t\t\t<artifactId>\2<\/artifactId>\n\t\t\t<version>\3<\/version>\n\t\t<\/dependency>/g" >> pom.xml

	printf "\t</dependencies>\n" >> pom.xml

	printf "</project>\n" >> pom.xml
fi