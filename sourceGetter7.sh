#!/bin/sh
#Copyright (c) J05HYYY
#Licence: https://www.gnu.org/licenses/gpl-3.0.txt

forcepomgood="FORCE" #change to "LIBREONLY" to switch to only libre software

usage(){
	printf "./sourceGetter7.sh <groupId> <artifactId> <version>\n\nTry and recursively download ALL source dependencies, and their dependencies ... for a package on Maven Central.\n\n"
	printf "sourceGetter7 requires git and subversion \n\nIf it can't find a git or subversion repository for a package, it will download the sources.jar, which is unfortunately usually incomplete\n\n"
	printf "The idea of this program is to try and rescue, (yes ... rescue) some software [but in practice] probably that's easier said than done.\n\n"
}

deleteDuplicates(){
#merge $2 into $1
#there must be a newline at the end of the array
#delimited also by newlines
out="$1"
old_ifs=$IFS
IFS="
"
for tocheck in $(printf "$2"); do
	foundcheck=false
	for tocheck2 in $(printf "$1"); do
		if [ "$tocheck" = "$tocheck2" ]; then
			foundcheck=true
		fi
	done
	if [ "$foundcheck" != "true" ]; then
		#echo "$tocheck"
		out="${out}\n${tocheck}\n"
	fi

done
IFS=$old_ifs
printf "$out"

}

getRepos(){
	echo "https://repo1.maven.org/maven2"
if [ -f "$1" ]; then
	theXML="$(cat $1 | sed 's#\r##g' | sed 's#[ \t]##g' | tr -d "\n")"
	theXMLnoBuild="$(printf "%s" "${theXML}" | sed "s#<build>.*</build>##g")"
	old_ifs="$IFS"
	IFS="<"
	geturl=0
	for atag in $(printf "%s" "$theXMLnoBuild" | grep -o '<repositories>.*</repositories>'); do
		if [ "$atag" = "repository>" ]; then
			geturl=1
		fi
		if [ "$geturl" = 1 ] && [ "$(printf "%s" "$atag" | cut -d '>' -f 1)" = "url" ]; then
			if [ "$(echo "$atag" | cut -d '>' -f 2)" != "https://repo1.maven.org/maven2" ]; then
				echo "$atag" | cut -d '>' -f 2 | sed 's/\/*$//g'
			fi
			geturl=0
		fi
	done
	IFS="$old_ifs"
fi
}

isNumeric(){
case $1 in
    ''|*[!0-9]*) echo bad ;;
    *) echo good ;;
esac
}

pomxmldependencies(){

	groupId="$2"
	artifactId="$3"
	version="$4"

	theXML="$(cat $1 | sed 's#\r##g' | sed 's#[ \t]##g' | tr -d "\n")"

	theXMLnoBuild="$(printf "%s" "${theXML}" | sed "s#<build>.*</build>##g")"

	theXMLnoBuildNoParent="$(printf "%s" "${theXMLnoBuild}" | sed "s#<parent>.*</parent>##g")"

	dependencies="$(printf "%s" "$theXMLnoBuild" | grep -o '<dependencies>.*</dependencies>')"

	newGroupId="NOTHING"
	newArtifactId="NOTHING"
	newVersion="NOTHING"

	excludeOn="0"

	old_ifs="$IFS"
	IFS="<"
	for dependency in $(printf "$dependencies\n"); do

	if [ "$(printf "%s" "${dependency}" | cut -c 1-10)" = "exclusion>" ]; then
		excludeOn="1"
	elif [ "$(printf "%s" "${dependency}" | cut -c 1-11)" = "/exclusion>" ]; then
		excludeOn="0"
	fi

	if [ "${excludeOn}" = "0" ]; then
		if [ "$(printf "%s" "${dependency}" | cut -c 1-8)" = "groupId>" ]; then
			if [ "${newGroupId}" != "NOTHING" ] && [ "${newArtifactId}" != "NOTHING" ] && [ "${newGroupId}" != "\*" ] && [ "${newArtifactId}" != "\*" ]; then
				if [ "$newVersion" = "" ]; then
					newVersion="NOTHING"
				fi

				recurse "${newGroupId}" "${newArtifactId}" "${newVersion}" "${2}" "${3}" "${4}"
			fi
			newGroupId="$(printf "%s" "${dependency}" | cut -c 9-)"
			if [ "${newGroupId}" = "\${project.groupId}" ] || [ "${newGroupId}" = "\${pom.groupId}" ]; then
				newGroupId="${groupId}"
			elif [ "$(printf "%s\n" "$newGroupId" | cut -c 1-2)" = "\${" ]; then
				theSpecial="$(printf "${newGroupId%\}}" | cut -c 3-)"
				special="$(printf "%s" "$theXMLnoBuild" | sed -n "s:.*<${theSpecial}>\(.*\)</${theSpecial}>.*:\1:p")"
				newGroupId="${special}"
			fi
		elif [ "$(printf "%s" "${dependency}" | cut -c 1-11)" = "artifactId>" ]; then
			newArtifactId="$(printf "%s" "${dependency}" | cut -c 12-)"
			if [ "${newArtifactId}" = "\${project.artifactId}" ] || [ "${newArtifactId}" = "\${pom.artifactId}" ]; then
				newArtifactId="${artifactId}"
			elif [ "$(printf "%s\n" "$newArtifactId" | cut -c 1-2)" = "\${" ]; then
				theSpecial="$(printf "${newArtifactId%\}}" | cut -c 3-)"
				special="$(printf "%s" "$theXMLnoBuild" | sed -n "s:.*<${theSpecial}>\(.*\)</${theSpecial}>.*:\1:p")"
				newArtifactId="${special}"
			fi
		elif [ "$(printf "%s" "${dependency}" | cut -c 1-8)" = "version>" ]; then
			newVersion="$(printf "%s" "${dependency}" | cut -c 9-)"
			if [ "${newVersion}" = "\${project.version}" ] || [ "${newVersion}" = "\${pom.version}" ] || [ "${newVersion}" = "\${pom.currentVersion}" ]; then
				newVersion="${version}"
			elif [ "$(printf "%s\n" "$newVersion" | cut -c 1-2)" = "\${" ]; then
				theSpecial="$(printf "${newVersion%\}}" | cut -c 3-)"
				special="$(printf "%s" "$theXMLnoBuild" | sed -n "s:.*<${theSpecial}>\(.*\)</${theSpecial}>.*:\1:p")"
				newVersion="${special}"
			fi

			if [ "$(echo "${newVersion}" | cut -c 1-1)" = "[" ]; then
				newVersion="NOTHING"
			fi
		fi
		depOn=0
	fi

	done

	if [ "${newGroupId}" != "NOTHING" ] && [ "${newArtifactId}" != "NOTHING" ] && [ "${newGroupId}" != "\*" ] && [ "${newArtifactId}" != "\*" ]; then
		if [ "$newVersion" = "" ]; then
			newVersion="NOTHING"
		fi
		recurse "${newGroupId}" "${newArtifactId}" "${newVersion}" "${2}" "${3}" "${4}"
	fi

	IFS="$old_ifs"
}

recurse(){
#1 newGroupId
#2 newArtifactId
#3 newVersion
#4 oldGroupId
#5 oldArtifactId
#6 oldVersion

	if [ "${2}" != "NOTHING" ]; then
		if [ "${3}" = "NOTHING" ]; then

			mkdir -p sources/structure/${1}/${2}

			if [ "$4" = "" ]; then
				repository="https://repo1.maven.org/maven2"
 				if [ -f "sources/structure/${1}/${2}/maven-metadata.xml" ]; then
					if [ "$(du "sources/structure/${1}/${2}/maven-metadata.xml" | cut -c 1-1)" = "0" ]; then
						rm sources/structure/${1}/${2}/maven-metadata.xml
					fi
				fi

				if ! [ -f sources/structure/${1}/${2}/maven-metadata.xml ]; then
echo "${repository}/$(printf "%s\n" "${1}" | sed "s#\.#/#g")/${2}/maven-metadata.xml"
					wget "${repository}/$(printf "%s\n" "${1}" | sed "s#\.#/#g")/${2}/maven-metadata.xml" -O sources/structure/${1}/${2}/maven-metadata.xml 
					sleep 1
				fi

				if [ -f "sources/structure/${1}/${2}/maven-metadata.xml" ]; then
					if [ "$(du "sources/structure/${1}/${2}/maven-metadata.xml" | cut -c 1-1)" = "0" ]; then
						rm sources/structure/${1}/${2}/maven-metadata.xml
					fi
				fi
			else
				if [ "$theRepos" = "" ]; then
					theRepos="$(deleteDuplicates "$theRepos" "https://repo1.maven.org/maven2")"
					theRepos="$(deleteDuplicates "$theRepos" "$(printf "%s\n%s\n" "${theRepos}" "$(getRepos "sources/structure/${1}/${2}/${3}/${2}-${3}.pom")" )")"
				fi
				theRepos="$(deleteDuplicates "$theRepos" "$(printf "%s\n%s" "${theRepos}" "$(getRepos "sources/structure/${4}/${5}/${6}/${5}-${6}.pom")" )")"

				old_ifs=$IFS
IFS="
"
				for repository in $theRepos; do
					if [ -f "sources/structure/${1}/${2}/maven-metadata.xml" ]; then
						if [ "$(du "sources/structure/${1}/${2}/maven-metadata.xml" | cut -c 1-1)" = "0" ]; then
							rm sources/structure/${1}/${2}/maven-metadata.xml
						fi
					fi

					if ! [ -f sources/structure/${1}/${2}/maven-metadata.xml ]; then
echo "${repository}/$(printf "%s\n" "${1}" | sed "s#\.#/#g")/${2}/maven-metadata.xml"
						wget "${repository}/$(printf "%s\n" "${1}" | sed "s#\.#/#g")/${2}/maven-metadata.xml" -O sources/structure/${1}/${2}/maven-metadata.xml 
					fi
	
					if [ -f "sources/structure/${1}/${2}/maven-metadata.xml" ]; then
						if [ "$(du "sources/structure/${1}/${2}/maven-metadata.xml" | cut -c 1-1)" = "0" ]; then
							rm sources/structure/${1}/${2}/maven-metadata.xml
						else
							break
						fi
					fi

				done
				IFS=$old_ifs
			fi

			if [ -f "sources/structure/${1}/${2}/maven-metadata.xml" ]; then
				latest="$(cat sources/structure/${1}/${2}/maven-metadata.xml | sed 's#[ \t]##g' | tr -d "\n" | sed "s#<build>.*</build>##g" | grep -o '<versioning>.*</versioning>' | grep -o '<latest>.*</latest>')"
				latest="$(printf "%s" "${latest}" | cut -c 9-)"
				version="${latest%</latest>}"


				version="$(cat "sources/structure/${1}/${2}/maven-metadata.xml" | sed "/<versions>/,/<\/versions>/d" | grep -o "<version>.*</version>" | cut -d '>' -f 2 | cut -d '<' -f 1)"

				if [ "$version" = "" ]; then
					version="$(cat "sources/structure/${1}/${2}/maven-metadata.xml" | sed -n "/<versions>/,/<\/versions>/p" | while read line; do
						toTestVersion="$(printf "%s" "$line" | grep -o '<version>.*</version>' | cut -c 10-)"
						toTestVersion="${toTestVersion%</version>}"
						if [ "$toTestVersion" != "" ]; then
							printf "%s\n" "$toTestVersion"
						fi
					done | sort -V | while read line2; do
						if [ "$(isNumeric $(echo "$line2" | cut -c 1-1))" = "good" ]; then
							echo "$line2"
						fi
					done | tail -n 1)"
	
					if [ "$version" = "" ]; then
						version="$(cat "sources/structure/${1}/${2}/maven-metadata.xml" | sed -n "/<versions>/,/<\/versions>/p" | while read line; do
							toTestVersion="$(printf "%s" "$line" | grep -o '<version>.*</version>' | cut -c 10-)"
							toTestVersion="${toTestVersion%</version>}"
							if [ "$toTestVersion" != "" ]; then
								printf "%s\n" "$toTestVersion"
							fi
						done | sort -V | while read line2; do
							if [ "$(isNumeric $(echo "$line2" | cut -c 1-1))" = "bad" ]; then
								echo "$line2"
							fi
						done | tail -n 1)"
					fi
				fi

			fi

			if [ "${1}" != "\*" ] && [ "${2}" != "\*" ]; then

				if [ -d "sources/structure/${4}/${5}/${6}" ]; then
					if [ ! -f "sources/structure/${4}/${5}/${6}/dependencies.txt" ]; then
						printf "%s\n" "${1}/${2}/${version}" >> sources/structure/${4}/${5}/${6}/dependencies.txt
					elif [ "$(grep "^${1}/${2}/${version}$" "sources/structure/${4}/${5}/${6}/dependencies.txt")" = "" ]; then
						printf "%s\n" "${1}/${2}/${version}" >> sources/structure/${4}/${5}/${6}/dependencies.txt
					fi
				fi

				if [ "$(grep "^${1}/${2}/${version}$" sources/catalogue.txt )" = "" ]; then
#					printf "FOUND DEPENDENCY: %s %s %s\n" "${1}" "${2}" "${version}"
					printf "${1}/${2}/${version}\n" >> sources/catalogue.txt
					./sourceGetter7.sh "${1}" "${2}" "${version}" "${4}" "${5}" "${6}" "1"
				fi
			fi
		else

			if [ "${1}" != "\*" ] && [ "${2}" != "\*" ]; then
				if [ -d "sources/structure/${4}/${5}/${6}" ]; then
					if [ ! -f "sources/structure/${4}/${5}/${6}/dependencies.txt" ]; then
						printf "%s\n" "${1}/${2}/${3}" >> sources/structure/${4}/${5}/${6}/dependencies.txt
					elif [ "$(grep "^${1}/${2}/${3}$" "sources/structure/${4}/${5}/${6}/dependencies.txt")" = "" ]; then
						printf "%s\n" "${1}/${2}/${3}" >> sources/structure/${4}/${5}/${6}/dependencies.txt
					fi
				fi

				if [ "$(grep "^${1}/${2}/${3}$" sources/catalogue.txt )" = "" ]; then
#					printf "FOUND DEPENDENCY: %s %s %s\n" "${1}" "${2}" "${3}"
					printf "${1}/${2}/${3}\n" >> sources/catalogue.txt
					./sourceGetter7.sh "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "1"
				fi
			fi
		fi
	fi
}

if [ "$#" != 3 ] && [ "$#" != 4 ] && [ "$#" != 6 ] && [ "$#" != 7 ]; then
echo "$@<<<"
usage
exit
fi
#echo
#echo
echo $@

	groupId="$1"
	artifactId="$2"
	version="$3"

	processDeps="no"

		if [ ! -f "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt" ]; then

			#if dependencies file does not exist ...

			#search the directory for jars and process them
			if [ -d "sources/structure/${groupId}/${artifactId}/${version}" ]; then
				find "sources/structure/${groupId}/${artifactId}/${version}" -name "*.jar" | while read subjar; do

					jarType=""
					if [ "$(echo "$subjar" | grep "sources.jar$")" != "" ] || [ "$(echo "$subjar" | grep "source.jar$")" != "" ]; then
						jarType="source"
					else
						jarType="bin"
					fi

					if [ -d tempExtract ]; then
						rm -rf tempExtract
					fi

					mkdir tempExtract
					unzip "$subjar" -d tempExtract

					subjarpom="$(find tempExtract -name pom.xml | head -n 1)"

					if [ -f "$subjarpom" ]; then
						theXMLTwo="$(cat $subjarpom | sed 's#\r##g' | sed 's#[ \t]##g' | tr -d "\n")"

						theXMLTwonoParent="$(printf "%s" "${theXMLTwo}" | sed "s#<parent>.*</parent>##g" | sed "s#<build>.*</build>##g" | sed "s#<dependencies>.*</dependencies>##g" | sed "s#<reporting>.*</reporting>##g")"
						theXMLTwonoBuild="$(printf "%s" "${theXMLTwo}" | sed "s#<build>.*</build>##g")"
						groupIdTwo="$(printf "%s" "${theXMLTwonoBuild}" | sed "s#<dependencies>.*</dependencies>##g" | grep -o '<groupId>.*</groupId>' | cut -d '>' -f 2 | cut -d '<' -f 1 )"

						if [ "${groupIdTwo}" = "" ]; then
							groupIdTwo="${groupId}"
						fi

						testVersionTwo="$(printf "%s" "${theXMLTwonoParent}" | grep -o '<version>.*</version>'| cut -d '>' -f 2 | cut -d '<' -f 1)"
		
						if [ "$(printf "%s\n" "$testVersionTwo" | cut -c 1-2)" = "\${" ]; then
							theSpecialTwo="$(printf "${testVersionTwo%\}}" | cut -c 3-)"
							specialTwo="$(printf "%s" "$theXMLTwonoParent" | sed -n "s:.*<${theSpecial}>\(.*\)</${theSpecial}>.*:\1:p")"
							testVersionTwo="${specialTwo}"
						fi

						if [ "${testVersionTwo}" = "" ]; then
							testVersionTwo="$(printf "%s" "${theXMLTwo}" | grep -o '<version>.*</version>'| cut -d '>' -f 2 | cut -d '<' -f 1)"
						fi

						if [ "${testVersionTwo}" = "" ]; then
							testVersionTwo="${version}"
						fi

						testArtifactIdTwo="$(printf "%s" "${theXMLTwonoParent}" | grep -o '<artifactId>.*</artifactId>' | cut -d '>' -f 2 | cut -d '<' -f 1)"

						mkdir -p sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}
#echo "sources/structure/${groupId}/${testArtifactIdTwo}/${testVersionTwo} <<<<"
						if [ "$jarType" = "source" ]; then
							#source jar

							if [ -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" ]; then
								if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" | cut -c 1-1)" = "0" ]; then
									rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar"
									if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
										rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
									fi
								elif [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" | cut -f 1)" -lt "$(du "$subjar" | cut -f 1)" ]; then
									rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar"		
									if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
										rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
									fi
								fi
							elif [ -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" ]; then
								if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" | cut -c 1-1)" = "0" ]; then
									rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar"
									if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
										rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
									fi
								elif [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" | cut -f 1)" -lt "$(du "$subjar" | cut -f 1)" ]; then
									rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar"
									if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
										rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
									fi
								fi
							fi	

							if [ ! -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" ]; then
								mv "$subjar" sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar
							elif [ ! -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" ]; then
								mv "$subjar" sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar
							fi

							if [ ! -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.pom" ]; then
								cp -a "$subjarpom" sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.pom
							fi

							if [ -f "$subjar" ]; then
								if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" | cut -f 1)" -ge "$(du "$subjar" | cut -f 1)" ]; then
									rm -f "$subjar"
								elif  [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" | cut -f 1)" -ge "$(du "$subjar" | cut -f 1)" ]; then
									rm -f "$subjar"
								fi
							fi

							mv tempExtract sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources
						else
							#bin jar
							if [ -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" ]; then
								if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" | cut -c 1-1)" = "0" ]; then
									rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar"
									if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon" ]; then
										rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon"
									fi
									if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR" ]; then
										rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR"
									fi
								elif [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" | cut -f 1)" -lt "$(du "$subjar" | cut -f 1)" ]; then
									rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar"
									if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon" ]; then
										rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon"
									fi
									if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR" ]; then
										rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR"
									fi
								fi
							fi

							if [ ! -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" ]; then
								mv "$subjar" sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar
							fi

							if [ -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.pom" ]; then
								if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.pom" | cut -c 1-1)" = "0" ]; then
									rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.pom"
								fi
							fi

							if [ ! -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.pom" ]; then
								cp -a "$subjarpom" sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.pom
							fi

							if [ -f "$subjar" ]; then
								if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" | cut -f 1)" -ge "$(du "$subjar" | cut -f 1)" ]; then
									rm -f "$subjar"
								fi
							fi
							rm -rf tempExtract
						fi

						if [ ! -f "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt" ]; then
							echo "${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
						elif [ "$(grep "^${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}$" "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt")" = "" ]; then
							echo "${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
						fi
						pomxmldependencies "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.pom" "${1}" "${2}" "${3}"

					else
						echo "UH OH, NO POM."

						groupIdTwo="unknown.group.id"
						testArtifactIdTwo="$(basename "$subjar" | cut -d '_' -f 1)"
						testVersionTwo="$(basename "$subjar" | cut -d '_' -f 2)"
						testVersionTwo="${testVersionTwo%.jar}"

						if [ "${testVersionTwo}" = "" ]; then
							testVersionTwo="${version}"
						fi

						if [ "${testArtifactIdTwo}" = "" ]; then
							testArtifactIdTwo="$(basename "$subjar")"
						fi

						if [ "$(printf "%s" "$testArtifactIdTwo" | grep ".jar$")" != "" ]; then
							testArtifactIdTwo="${testArtifactIdTwo%.jar}"
						fi

						if [ "$(printf "%s" "$testArtifactIdTwo" | grep "javadoc$")" = "" ]; then


							if [ "$(printf "%s" "$testArtifactIdTwo" | grep "sources$")" != "" ] || [ "$(printf "%s" "$testArtifactIdTwo" | grep "source$")" != "" ]; then

								#source jar
								testArtifactIdTwo=""
								if [ "$(printf "%s" "$testArtifactIdTwo" | grep "source$")" != "" ]; then
									testArtifactIdTwo="${testArtifactIdTwo%.source}"
								elif [ "$(printf "%s" "$testArtifactIdTwo" | grep "sources$")" != "" ]; then
									testArtifactIdTwo="${testArtifactIdTwo%.sources}"
								fi

								mkdir -p sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}

								if [ -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" ]; then
									if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" | cut -c 1-1)" = "0" ]; then
										rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar"
										if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
											rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
										fi
									elif [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" | cut -f 1)" -lt "$(du "$subjar" | cut -f 1)" ]; then
										rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar"
										if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
											rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
										fi
									fi
								elif [ -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" ]; then
									if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" | cut -c 1-1)" = "0" ]; then
										rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar"
										if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
											rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
										fi
									elif [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" | cut -f 1)" -lt "$(du "$subjar" | cut -f 1)" ]; then
										rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar"
										if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
											rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
										fi
									fi
								fi

								if [ ! -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" ]; then
									mv "$subjar" sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar
								elif [ ! -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" ]; then
									mv "$subjar" sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar
								fi

								if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
									if [ "$(find "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" -follow -maxdepth 1 -mindepth 1)" = "" ]; then
										rmdir "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources"
									fi
								fi

								if [ ! -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources" ]; then
									mv tempExtract sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/extractedSources
								fi

								if [ -f "$subjar" ]; then
									if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-sources.jar" | cut -f 1)" -ge "$(du "$subjar" | cut -f 1)" ]; then
										rm -f "$subjar"
									elif [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}-source.jar" | cut -f 1)" -ge "$(du "$subjar" | cut -f 1)" ]; then
										rm -f "$subjar"
									fi
								fi

							else
								#bin jar
								mkdir -p sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}

								if [ -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" ]; then
									if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" | cut -c 1-1)" = "0" ]; then
										rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar"
										if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon" ]; then
											rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon"
										fi
										if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR" ]; then
											rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR"
										fi
									elif [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" | cut -f 1)" -lt "$(du "$subjar" | cut -f 1)" ]; then
										rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar"
										if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon" ]; then
											rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon"
										fi
										if [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR" ]; then
											rm -rf "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR"
										fi
									fi
								fi

								if [ ! -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" ]; then
									mv "$subjar" sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar
								fi

								if [ -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" ]; then
									if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" | cut -c 1-1)" = "0" ]; then
										rm -f "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar"
									fi
								fi

								if [ -f sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar ]; then
									if ! [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon" ]; then
										mkdir -p sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon
									fi
									if ! [ -d "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR" ]; then
										mkdir -p sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR
									fi
		
									find "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon" -follow -maxdepth 0 -empty -exec procyon -jar sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar -o sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledProcyon \;
									find "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR" -follow -maxdepth 0 -empty -exec java -jar cfr/cfr.jar sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar --outputdir sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/DecompiledCFR \;
								fi

								if [ -f "$subjar" ]; then
									if [ "$(du "sources/structure/${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}/${testArtifactIdTwo}-${testVersionTwo}.jar" | cut -f 1)" -ge "$(du "$subjar" | cut -f 1)" ]; then
										rm -f "$subjar"
									fi
								fi
							fi

							if [ ! -f "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt" ]; then
								echo "${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
							elif [ "$(grep "^${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}$" "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt")" = "" ]; then
								echo "${groupIdTwo}/${testArtifactIdTwo}/${testVersionTwo}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
							fi

						else
							mkdir -p sources/javadoc
							mv "$subjar" sources/javadoc
						fi

						if [ -d "tempExtract" ]; then
							rm -rf tempExtract
						fi
					fi
				done
			fi

			processDeps="yes"

		else
			#if dependencies file does exist ...
			if [ ! -f "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt" ]; then
				touch "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt"
			fi 
			cat "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt" | while read adependency; do
				if [ "$(printf "%s" "${adependency}" | cut -d '/' -f 1)" != "unknown.group.id" ]; then
				./sourceGetter7.sh "$(printf "%s" "${adependency}" | cut -d '/' -f 1)" "$(printf "%s" "${adependency}" | cut -d '/' -f 2)" "$(printf "%s" "${adependency}" | cut -d '/' -f 3)" "${groupId}" "${artifactId}" "${version}"
				fi
			done
		fi


	sourceNumber=1

	if [ "${7}" != "" ]; then
		sourceNumber="${7}"
	fi
	repository=""

	mkdir -p sources/structure/${groupId}/${artifactId}/${version}

	if [ "$theRepos" = "" ]; then
		export theRepos="$(deleteDuplicates "$theRepos" "https://repo1.maven.org/maven2")"
		export theRepos="$(deleteDuplicates "$theRepos" "$(printf "%s\n%s\n" "${theRepos}" "$(getRepos "sources/structure/${1}/${2}/${3}/${2}-${3}.pom")" )")"
	fi
	export theRepos="$(deleteDuplicates "$theRepos" "$(printf "%s\n%s" "${theRepos}" "$(getRepos "sources/structure/${4}/${5}/${6}/${5}-${6}.pom")" )")"

	ispomgood=""

	if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then
		if ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then

			if [ -f "sources/structure/${groupId}/${artifactId}/${version}/extractedSources/build.gradle" ] || [ -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources/build.gradle" ]; then
				if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/build.gradle" ] || ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/build.gradle" ]; then
					cat "sources/structure/${groupId}/${artifactId}/${version}/extractedSources/build.gradle" | sed -n '/^\/\*.*\*\//!p' | sed -n '/ \/\/.*/!p' | sed 's|/\*|\n&|g;s|*/|&\n|g' | sed '/\/\*/,/*\//d' > "sources/structure/${groupId}/${artifactId}/${version}/build.gradle"
				fi
			fi

			if [ -f "sources/structure/${groupId}/${artifactId}/${version}/build.gradle" ] || [ -L "sources/structure/${groupId}/${artifactId}/${version}/build.gradle" ]; then

				#if there is a build.gradle, use gradle2pom.sh to create a pom
				thispwd="$PWD"
				cd "sources/structure/${groupId}/${artifactId}/${version}"
				$thispwd/gradle2pom.sh "${groupId}" "${artifactId}" "${version}"
				mv pom.xml ${artifactId}-${version}.pom
				cd "$thispwd"
			else

				anindex=1
				old_ifs=$IFS
IFS="
"
				for repository in $theRepos; do
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.pom"
						wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.pom" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom
						if [ "$?" = 0 ]; then
							#check licence information
							if [ "$forcepomgood" = "FORCE" ]; then
								ispomgood="GOOD"
							else
								ispomgood="$(./checkLicencePom.sh "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom")"
							fi

							#if the pom doesn't contain licence information, get maven-metadata.xml and check that

							if [ "$ispomgood" = "NO" ]; then
 								if [ -f "sources/structure/${groupId}/${artifactId}/maven-metadata.xml" ]; then
									if [ "$(du "sources/structure/${groupId}/${artifactId}/maven-metadata.xml" | cut -c 1-1)" = "0" ]; then
										rm sources/structure/${groupId}/${artifactId}/maven-metadata.xml
									fi
								fi

								if ! [ -f sources/structure/${groupId}/${artifactId}/maven-metadata.xml ]; then
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/maven-metadata.xml"
								wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/maven-metadata.xml" -O sources/structure/${groupId}/${artifactId}/maven-metadata.xml 
									sleep 1
								fi

								if [ -f "sources/structure/${groupId}/${artifactId}/maven-metadata.xml" ]; then
									if [ "$(du "sources/structure/${groupId}/${artifactId}/maven-metadata.xml" | cut -c 1-1)" = "0" ]; then
										rm sources/structure/${groupId}/${artifactId}/maven-metadata.xml
									fi
								fi

								ispomgood="$(./checkLicencePom.sh "sources/structure/${groupId}/${artifactId}/maven-metadata.xml")"
							fi

							echo "${groupId}/${artifactId}/${version}	${ispomgood}" >> sources/structure/${groupId}/${artifactId}/${version}/licences.txt


							found=yes
							break
						fi
					anindex="$(expr $anindex + 1)"
				done
				IFS=$old_ifs
			fi
		fi
	fi

#	if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then
#		found=yes
#	fi

##echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}"

	if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then

		if ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then
			if [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" | cut -c 1-1)" = "0" ]; then
				rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom"
				found=no
			else
				found=yes
				#if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then
				#	cat "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" | sed -n "/<modules>/,/<\/modules>/p" | grep -o "<module>.*</module>" | cut -d '>' -f 2 | cut -d '<' -f 1 | while read amodule; do
				#		echo "${groupId}/${amodule}/${version}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
				#	done
				#fi
			fi
		else
			found=yes
			#if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then
			#	cat "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" | sed -n "/<modules>/,/<\/modules>/p" | grep -o "<module>.*</module>" | cut -d '>' -f 2 | cut -d '<' -f 1 | while read amodule; do
			#		echo "${groupId}/${amodule}/${version}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
			#	done
			#fi
		fi
	fi

	if [ "$found" = "yes" ]; then

		theXML=""
		if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then
			theXML="$(cat "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" | sed 's#\r##g' | sed 's#[ \t]##g' | tr -d "\n")"
		fi

		theXMLnoBuild="$(printf "%s" "${theXML}" | sed "s#<build>.*</build>##g")"

		scm="$(printf "%s" "$theXMLnoBuild" | grep -o '<scm>.*</scm>')"
		connection="$(printf "%s\n" "$scm" | sed -n "s:.*<connection>\(.*\)</connection>.*:\1:p" )"

		aconnectionvar="$(printf "%s" "$connection" | grep -o "\${.*}")"

		if [ "$aconnectionvar" != "" ]; then
			aconnectionvar="$(printf "${aconnectionvar%\}}" | cut -c 3-)"
			toreplaceconnection="$(printf "%s" "$theXMLnoBuild" | sed -n "s:.*<${aconnectionvar}>\(.*\)</${aconnectionvar}>.*:\1:p")"
			connection="$(printf "%s" "$connection" | sed "s#\${${aconnectionvar}}#${toreplaceconnection}#g")"
		fi

		tag="$(printf "%s\n" "$scm" | grep -o '<tag>.*</tag>' | cut -c 6-)"
		tag="${tag%</tag>}"

		printf "${indent}sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}\n" >> buildOrder.txt

		if [ "$ispomgood" = "GOOD" ] && ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ] && ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
			sourcesJarDownloadFailed=1

			#gprintf "GETTING SOURCES %s FROM JAR\n" "$(printf "%s" "$connection" | cut -c 5-)"
			mkdir -p sources/structure/${groupId}/${artifactId}/${version}/extractedSources
IFS="
"

			if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar" ]; then
				if ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar" ]; then
					if [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar" | cut -c 1-1)" = "0" ]; then
						rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar"
					fi
				fi
			elif [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar" ]; then
				if ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar" ]; then
					if [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar" | cut -c 1-1)" = "0" ]; then
						rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar"
					fi
				fi
			fi

			if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar" ]; then
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}-sources.jar"
				wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}-sources.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar
				sleep 1
			elif ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar" ]; then
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}-source.jar"
				wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}-source.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar
				sleep 1
			fi

			if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar" ]; then
				if ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar" ]; then
					if ! [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar" | cut -c 1-1)" = "0" ]; then
						if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
							mkdir "sources/structure/${groupId}/${artifactId}/${version}/extractedSources"
						fi
						if [ "$(find -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" -maxdepth 1 -mindepth 1)" = "" ]; then
							unzip "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar" -d sources/structure/${groupId}/${artifactId}/${version}/extractedSources
							if [ "$?" = 0 ]; then
								sourcesJarDownloadFailed=0
							fi 
						fi
					else
						rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar"
					fi
				fi
			elif [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar" ]; then
				if ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar" ]; then
					if ! [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar" | cut -c 1-1)" = "0" ]; then
						if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
							mkdir "sources/structure/${groupId}/${artifactId}/${version}/extractedSources"
						fi
						if [ "$(find -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" -maxdepth 1 -mindepth 1)" = "" ]; then
							unzip "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar" -d sources/structure/${groupId}/${artifactId}/${version}/extractedSources
							if [ "$?" = 0 ]; then
								sourcesJarDownloadFailed=0
							fi 
						fi
					else
						rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-source.jar"
					fi
				fi
			fi

			if [ "$sourcesJarDownloadFailed" = 1 ]; then


				if [ "$(printf "%s\n" "$connection" | cut -c 1-8)" = "scm:git:" ]; then
					if [ "$(printf "${connection}" | cut -c 1-12)" = "scm:git:git@" ]; then
						connection="$(printf "%s" "${connection}" | sed "s#:#/#g" | sed "s#git@#git://#g")"
					fi
					#printf "GETTING SOURCES %s FROM GIT\n" "$(printf "%s" "$connection" | cut -c 9-)"
					cd sources/structure/${groupId}/${artifactId}/${version}
					if [ "${tag}" = "HEAD" ] || [ "${tag}" = "" ]; then

						scmurl="$(printf "%s" "$connection" | cut -c 9- | sed "s#git://github.com#https://github.com#g")"
	
						scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"

						if ! [ -d "extractedSources" ]; then
							mkdir -p "extractedSources"
echo "${scmurl}"
							git clone "${scmurl}" "extractedSources"
							if [ "$?" != 0 ]; then
								gitfailed=1
							fi
						fi
					else 

						scmurl="$(printf "%s" "$connection" | cut -c 9- | sed "s#git://github.com#https://github.com#g")"

						scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"
	
						if ! [ -d "extractedSources" ]; then
							mkdir -p "extractedSources"
echo "${scmurl} -b ${tag}"
							git clone -b "${tag}" "${scmurl}" "extractedSources"
							if [ "$?" != 0 ]; then
								gitfailed=1
							fi
						fi
					fi
					cd ../../../../../
				elif [ "$(printf "%s\n" "$connection" | cut -c 1-8)" = "scm:svn" ]; then
					#printf "GETTING SOURCES %s FROM SVN\n" "$(printf "%s" "$connection" | cut -c 9-)"
					cd sources/structure/${groupId}/${artifactId}/${version}
		
					scmurl="$(printf "%s\n" "$connection" | cut -c 9- | sed "s#git://github.com#https://github.com#g")"
		
					scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"
	
					if ! [ -d "extractedSources" ]; then
						mkdir -p "extractedSources"
						svn co -r "${tag}" "${scmurl}" "extractedSources"
						if [ "$?" != 0 ]; then
								gitfailed=1
						fi
					fi
	
					cd ../../../../../
				elif [ "$(printf "%s\n" "$connection" | cut -c 1-4)" = "git@" ]; then
					connection="$(printf "%s" "${connection}" | sed "s#:#/#g" | sed "s#git@#git://#g")"
					#printf "GETTING SOURCES %s FROM GIT\n" "$(printf "%s" "$connection")"
					cd sources/structure/${groupId}/${artifactId}/${version}
					if [ "${tag}" = "HEAD" ] || [ "${tag}" = "" ]; then
							scmurl="$(printf "%s" "$connection" | sed "s#git://github.com#https://github.com#g")"
		
						scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"
	
							if ! [ -d "extractedSources" ]; then
						mkdir -p "extractedSources"
echo "${scmurl} -b HEAD"
							git clone -b "HEAD" "${scmurl}" "extractedSources"
							if [ "$?" != 0 ]; then
								gitfailed=1
							fi
						fi
					else 
		
						scmurl="$(printf "%s" "$connection" | sed "s#git://github.com#https://github.com#g")"
	
						scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"
	
						if ! [ -d "extractedSources" ]; then
							mkdir -p "extractedSources"
echo "${scmurl} -b HEAD"
							git clone -b "${tag}" "${scmurl}" "extractedSources"
							if [ "$?" != 0 ]; then
								gitfailed=1
							fi
						fi
	
					fi
					cd ../../../../../
				else
					gitfailed=1
				fi
			fi

			#get binary jar
			if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
				if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
					rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
				fi
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar"
				wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar
				sleep 1
			elif [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" | cut -c 1-1)" = "0" ]; then
				if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
					rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
				fi
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar"
				wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar
				sleep 1
			fi

			if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
				if [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" | cut -c 1-1)" = "0" ]; then
					rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
				fi
			fi

			if [ -f sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar ]; then
				if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" ]; then
					mkdir -p sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon
				fi
				if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" ]; then
					mkdir -p sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR
				fi
		
				#if directory is empty, decompile
				find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" -follow -maxdepth 0 -empty -exec procyon -jar sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar -o sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon \;
				find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" -follow -maxdepth 0 -empty -exec java -jar cfr/cfr.jar sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar --outputdir sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR \;
			fi

			if [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" ]; then
				if [ "$(find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" -follow -maxdepth 1 -mindepth 1)" != "" ]; then
					if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon/pom.xml" ]; then
						cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon/pom.xml"
					fi
				else
					rmdir "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon"
				fi
			fi

			if [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" ]; then
				if [ "$(find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" -follow -maxdepth 1 -mindepth 1)" != "" ]; then
					if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR/pom.xml" ]; then
						cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR/pom.xml"
					fi
				else
					rmdir "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR"
				fi
			fi
		fi

		if [ -d "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ] || [ -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
			if [ "$(find -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" -maxdepth 1 -mindepth 1)" = "" ]; then

				if ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
					rmdir "sources/structure/${groupId}/${artifactId}/${version}/extractedSources"
				fi

				#try a different mirror
				if [ "$(echo $theRepos | wc -l)" -gt "$sourceNumber" ]; then
					sourceNumber="$(expr $sourceNumber + 1)"
					./sourceGetter7.sh "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${sourceNumber}"
				fi
			else
				if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/extractedSources/pom.xml" ]; then
					if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then
						cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/extractedSources/pom.xml"

						if [ "$forcepomgood" = "FORCE" ]; then
							ispomgood="GOOD"
						else
							ispomgood="$(./checkLicencePom.sh "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom")"
						fi
					fi
				fi

				if [ "$ispomgood" = "GOOD" ]; then

					old_ifs=$IFS
IFS="
"
					for repository in $theRepos; do

						#get binary jar too
						if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
							if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
								rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
							fi
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar"
							wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar
							sleep 1
						elif [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" | cut -c 1-1)" = "0" ]; then
							if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
								rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
							fi
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar"
							wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar
							sleep 1
						fi

						if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
							if [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" | cut -c 1-1)" = "0" ]; then
								rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
							fi
						fi
	
					done
					IFS=$old_ifs

					if [ -f sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar ]; then
						if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" ]; then
							mkdir -p sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon
						fi
						if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" ]; then
							mkdir -p sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR
						fi
		
						#if directory is empty, decompile
						find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" -follow -maxdepth 0 -empty -exec procyon -jar sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar -o sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon \;
						find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" -follow -maxdepth 0 -empty -exec java -jar cfr/cfr.jar sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar --outputdir sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR \;
					fi

					if [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" ]; then
						if [ "$(find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" -follow -maxdepth 1 -mindepth 1)" != "" ]; then
							if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon/pom.xml" ]; then
								cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon/pom.xml"
							fi
						else
							rmdir "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon"
						fi
					fi

					if [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" ]; then
						if [ "$(find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" -follow -maxdepth 1 -mindepth 1)" != "" ]; then
							if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR/pom.xml" ]; then
								cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR/pom.xml"
							fi
						else
							rmdir "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR"
						fi
					fi
	
				fi
			fi
		else
			#try a different mirror
			if [ "$(echo $theRepos | wc -l)" -gt "$sourceNumber" ]; then
				sourceNumber="$(expr $sourceNumber + 1)"
				./sourceGetter7.sh "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${sourceNumber}"
			fi
		fi

		if [ "$processDeps" = "yes" ]; then
			#if dependencies file does not exist ...

			#process dependencies

			pomxmldependencies "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "${1}" "${2}" "${3}"

			#process submodules

			if [ -d "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ] || [ -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then

				find "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" -mindepth 2 -name pom.xml -printf "%d %p\n" | sort -nr | cut -d ' ' -f 2- | while read submodule; do

					if [ -f "$submodule" ]; then
						theXML="$(cat $submodule | sed 's#\r##g' | sed 's#[ \t]##g' | tr -d "\n")"
					fi

					theXMLnoParent="$(printf "%s" "${theXML}" | sed "s#<parent>.*</parent>##g" | sed "s#<build>.*</build>##g" | sed "s#<dependencies>.*</dependencies>##g" | sed "s#<reporting>.*</reporting>##g")"
					testVersion="$(printf "%s" "${theXMLnoParent}" | grep -o '<version>.*</version>'| cut -d '>' -f 2 | cut -d '<' -f 1)"
		
					if [ "$(printf "%s\n" "$testVersion" | cut -c 1-2)" = "\${" ]; then
						theSpecial="$(printf "${testVersion%\}}" | cut -c 3-)"
						special="$(printf "%s" "$theXMLnoParent" | sed -n "s:.*<${theSpecial}>\(.*\)</${theSpecial}>.*:\1:p")"
						testVersion="${special}"
					fi
	
					testArtifactId="$(printf "%s" "${theXMLnoParent}" | grep -o '<artifactId>.*</artifactId>' | cut -d '>' -f 2 | cut -d '<' -f 1)"


					if [ "$(printf "%s\n" "$testArtifactId" | cut -c 1-2)" = "\${" ]; then
						theSpecial="$(printf "${testArtifactId%\}}" | cut -c 3-)"
						special="$(printf "%s" "$theXMLnoParent" | sed -n "s:.*<${theSpecial}>\(.*\)</${theSpecial}>.*:\1:p")"
						testArtifactId="${special}"
					fi
	
					if [ "$testVersion" = "" ]; then
						mkdir -p sources/structure/${groupId}/${testArtifactId}/${version}

						#printf "%s\n" "${groupId}/${testArtifactId}/${version}" >> sources/structure/${1}/${2}/${3}/dependencies.txt

						if ! [ -L "sources/structure/${groupId}/${testArtifactId}/${version}/${testArtifactId}-${version}.pom" ]; then
							if [ -f "$(dirname "${submodule}")/pom.xml" ]; then
								cp -a "$(dirname "${submodule}")/pom.xml" "sources/structure/${groupId}/${testArtifactId}/${version}/${testArtifactId}-${version}.pom"
							fi
						fi

						if ! [ -L "sources/structure/${groupId}/${testArtifactId}/${version}/extractedSources" ]; then
							if [ -d "$(dirname "${submodule}")" ]; then
								mv "$(dirname "${submodule}")" "sources/structure/${groupId}/${testArtifactId}/${version}/extractedSources"
							fi
						fi

						if [ ! -f "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt" ]; then
							echo "${groupId}/${testArtifactId}/${version}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
						elif [ "$(grep "^${groupId}/${testArtifactId}/${version}$" "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt")" = "" ]; then
							echo "${groupId}/${testArtifactId}/${version}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
						fi

						pomxmldependencies "sources/structure/${groupId}/${testArtifactId}/${version}/${testArtifactId}-${version}.pom" "${1}" "${2}" "${3}"

						#if [ -f "sources/structure/${groupId}/${testArtifactId}/${version}/${testArtifactId}-${version}.pom" ]; then
						#	cat "sources/structure/${groupId}/${testArtifactId}/${version}/${testArtifactId}-${version}.pom" | sed -n "/<modules>/,/<\/modules>/p" | grep -o "<module>.*</module>" | cut -d '>' -f 2 | cut -d '<' -f 1 | while read amodule; do
						#	done
						#fi

					else
						mkdir -p sources/structure/${groupId}/${testArtifactId}/${testVersion}

						#printf "%s\n" "${groupId}/${testArtifactId}/${testVersion}" >> sources/structure/${1}/${2}/${3}/dependencies.txt

						if ! [ -L "sources/structure/${groupId}/${testArtifactId}/${testVersion}/${testArtifactId}-${testVersion}.pom" ]; then
							if [ -f "$(dirname "${submodule}")/pom.xml" ]; then
								cp -a "$(dirname "${submodule}")/pom.xml" "sources/structure/${groupId}/${testArtifactId}/${testVersion}/${testArtifactId}-${testVersion}.pom"
							fi
						fi

						if ! [ -L "sources/structure/${groupId}/${testArtifactId}/${testVersion}/extractedSources" ]; then
							if [ -d "$(dirname "${submodule}")" ]; then
								mv "$(dirname "${submodule}")" "sources/structure/${groupId}/${testArtifactId}/${testVersion}/extractedSources"
							fi
						fi

						if [ ! -f "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt" ]; then
							echo "${groupId}/${testArtifactId}/${testVersion}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
						elif [ "$(grep "^${groupId}/${testArtifactId}/${testVersion}$" "sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt")" = "" ]; then
							echo "${groupId}/${testArtifactId}/${testVersion}" >> sources/structure/${groupId}/${artifactId}/${version}/dependencies.txt
						fi

						pomxmldependencies "sources/structure/${groupId}/${testArtifactId}/${testVersion}/${testArtifactId}-${testVersion}.pom" "${1}" "${2}" "${3}"

						#if [ -f "sources/structure/${groupId}/${testArtifactId}/${version}/${testArtifactId}-${testVersion}.pom" ]; then
						#	cat "sources/structure/${groupId}/${testArtifactId}/${testVersion}/${testArtifactId}-${testVersion}.pom" | sed -n "/<modules>/,/<\/modules>/p" | grep -o "<module>.*</module>" | cut -d '>' -f 2 | cut -d '<' -f 1 | while read amodule; do
						#	done
						#fi
					fi


				done

			fi
		fi

	#if not found, try a different mirror
	elif [ "$(echo $theRepos | wc -l)" -gt "$sourceNumber" ] && [ "$4" != "" ]; then
		sourceNumber="$(expr $sourceNumber + 1)"
		./sourceGetter7.sh "${1}" "${2}" "${3}" "${4}" "${5}" "${6}" "${sourceNumber}"

	#if not found and no mirrors left
	else
		if [ "$ispomgood" = "GOOD" ] && ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
			if ! [ -L "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
			#get binary jar from mavencentral as a last resort

				old_ifs=$IFS
IFS="
"
				for repository in $theRepos; do
					if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar"
						wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar
						sleep 1
					elif [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" | cut -c 1-1)" = "0" ]; then
						if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
							rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
						fi
echo "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar"
						wget "${repository}/$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar
						sleep 1
					fi

					if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
						if [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" | cut -c 1-1)" = "0" ]; then
							rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
						fi
					fi

					if [ -f sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar ]; then
						if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" ]; then
							mkdir -p sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon
						fi
						if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" ]; then
							mkdir -p sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR
						fi

						#if directory is empty, decompile
						find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" -follow -maxdepth 0 -empty -exec procyon -jar sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar -o sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon \;
						#TODO
					fi

					if [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" ]; then
						if [ "$(find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon" -follow -maxdepth 1 -mindepth 1)" != "" ]; then
							if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon/pom.xml" ]; then
								cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon/pom.xml"
							fi
							break
						else
							rmdir "sources/structure/${groupId}/${artifactId}/${version}/DecompiledProcyon"
						fi
					fi

					if [ -d "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" ]; then
						if [ "$(find "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR" -follow -maxdepth 1 -mindepth 1)" != "" ]; then
							if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR/pom.xml" ]; then
								cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR/pom.xml"
							fi
							break
						else
							rmdir "sources/structure/${groupId}/${artifactId}/${version}/DecompiledCFR"
						fi
					fi

				done
				IFS=$old_ifs


#				echo "recurse "${1}" "${2}" "NOTHING" "${4}" "${5}" "${6}""
				#also try to get a substitute version

				#recurse "${1}" "${2}" "NOTHING" "${4}" "${5}" "${6}"

			fi
		fi
	fi



