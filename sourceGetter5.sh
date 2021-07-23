#!/bin/sh
#Copyright (c) J05HYYY
#Licence: https://www.gnu.org/licenses/gpl-3.0.txt

usage(){
	printf "./sourceGetter5.sh <groupId> <artifactId> <version>\n\nTry and recursively download ALL source dependencies, and their dependencies ... for a package on Maven Central.\n\n"
	printf "sourceGetter5 requires git and subversion \n\nIf it can't find a git or subversion repository for a package, it will download the sources.jar, which is unfortunately usually incomplete\n\n"
	printf "The idea of this program is to try and rescue, (yes ... rescue) some software [but in practice] probably that's easier said than done.\n\n"
}

isNumeric(){
case $1 in
    ''|*[!0-9]*) echo bad ;;
    *) echo good ;;
esac
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

			if [ -f "sources/structure/${1}/${2}/maven-metadata.xml" ]; then
				if [ "$(du "sources/structure/${1}/${2}/maven-metadata.xml" | cut -c 1-1)" = "0" ]; then
					rm sources/structure/${1}/${2}/maven-metadata.xml
				fi
			fi

			if ! [ -f sources/structure/${1}/${2}/maven-metadata.xml ]; then
				wget "${repository}$(printf "%s\n" "${1}" | sed "s#\.#/#g")/${2}/maven-metadata.xml" -O sources/structure/${1}/${2}/maven-metadata.xml 
				sleep 1
			fi

			if [ -f "sources/structure/${1}/${2}/maven-metadata.xml" ]; then
				if [ "$(du "sources/structure/${1}/${2}/maven-metadata.xml" | cut -c 1-1)" = "0" ]; then
					rm sources/structure/${1}/${2}/maven-metadata.xml
				fi
			fi

			if [ -f "sources/structure/${1}/${2}/maven-metadata.xml" ]; then
				latest="$(cat sources/structure/${1}/${2}/maven-metadata.xml | sed 's#[ \t]##g' | tr -d "\n" | sed "s#<build>.*</build>##g" | grep -o '<versioning>.*</versioning>' | grep -o '<latest>.*</latest>')"
				latest="$(printf "%s" "${latest}" | cut -c 9-)"
				version="${latest%</latest>}"
			fi

			if [ "$version" = "" ]; then
				version="$(cat sources/structure/${1}/${2}/maven-metadata.xml | sed -n "/<versions>/,/<\/versions>/p" | while read line; do
				toTestVersion="$(printf "%s" "$line" | grep -o '<version>.*</version>' | cut -c 10-)"
				toTestVersion="${toTestVersion%</version>}"

					if [ "$toTestVersion" != "" ]; then
							printf "%s\n" "$toTestVersion"
					fi
				done | sort -V | tail -n 1)"
			fi

			if [ "${1}" != "\*" ] && [ "${2}" != "\*" ]; then

				if [ -d "sources/structure/${4}/${5}/${6}" ]; then
					printf "%s\n" "${1}/${2}/${version}" >> sources/structure/${4}/${5}/${6}/dependencies.txt
				fi

				if [ "$(grep "^${1}/${2}/${version}$" sources/catalogue.txt )" = "" ]; then
					printf "FOUND DEPENDENCY: %s %s %s\n" "${1}" "${2}" "${version}"
					printf "${1}/${2}/${version}\n" >> sources/catalogue.txt
					./sourceGetter5.sh "${1}" "${2}" "${version}"
				fi
			fi
		else

			if [ "${1}" != "\*" ] && [ "${2}" != "\*" ]; then
				if [ -d "sources/structure/${4}/${5}/${6}" ]; then
					printf "%s\n" "${1}/${2}/${3}" >> sources/structure/${4}/${5}/${6}/dependencies.txt
				fi

				if [ "$(grep "^${1}/${2}/${3}$" sources/catalogue.txt )" = "" ]; then
					printf "FOUND DEPENDENCY: %s %s %s\n" "${1}" "${2}" "${3}"
					printf "${1}/${2}/${3}\n" >> sources/catalogue.txt
					./sourceGetter5.sh "${1}" "${2}" "${3}"
				fi
			fi
		fi
	fi
}

if [ "$#" != 3 ]; then
usage
exit
fi

	groupId="$1"
	artifactId="$2"
	version="$3"

	repository="https://repo1.maven.org/maven2/"

	mkdir -p sources/structure/${groupId}/${artifactId}/${version}

	if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" ]; then
		wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.pom" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom
		sleep 1
	#elif [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" | cut -c 1-1)" = "0" ]; then
	#	rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom"
	#	wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.pom" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom
	#	sleep 1
	fi

	theXML="$(cat sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom | sed 's#[ \t]##g' | tr -d "\n")"

	theXMLBuild="$(printf "%s" "${theXML}" | grep -o '<build>.*</build>')"

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

	printf '#!/bin/sh\n' >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh

	if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
		if [ "$(printf "%s\n" "$connection" | cut -c 1-8)" = "scm:git:" ]; then
			if [ "$(printf "${connection}" | cut -c 1-12)" = "scm:git:git@" ]; then
				connection="$(printf "%s" "${connection}" | sed "s#:#/#g" | sed "s#git@#git://#g")"
			fi
			printf "GETTING SOURCES %s FROM GIT\n" "$(printf "%s" "$connection" | cut -c 9-)"
			cd sources/structure/${groupId}/${artifactId}/${version}
			if [ "${tag}" = "HEAD" ] || [ "${tag}" = "" ]; then

				scmurl="$(printf "%s" "$connection" | cut -c 9-)"

				scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"

				if ! [ -d "../../../../${scmdir}/HEAD" ]; then
					mkdir -p "../../../../${scmdir}/HEAD/extractedSources"
					git clone "${scmurl}" "../../../../${scmdir}/HEAD/extractedSources"
				fi

				ln -s "../../../../${scmdir}/HEAD/extractedSources" "extractedSources"

				printf "%s\n" "#We found the git, but the branch is unknown, it might need futher modifications." >> get_skel.sh
				printf "%s\n" "git clone "${scmurl}" "../../../../${scmdir}/HEAD/extractedSources"" >> get_skel.sh
				printf "%s\n" "ln -s "../../../../${scmdir}/HEAD/extractedSources" "extractedSources"" >> get_skel.sh
			else 

				scmurl="$(printf "%s" "$connection" | cut -c 9-)"

				scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"

				if ! [ -d "../../../../${scmdir}/${tag}" ]; then
					mkdir -p "../../../../${scmdir}/${tag}/extractedSources"
					git clone -b "${tag}" "${scmurl}" "../../../../${scmdir}/${tag}/extractedSources"
				fi

				ln -s "../../../../${scmdir}/${tag}/extractedSources" "extractedSources"

				printf "%s\n" "#Great, we found the git and the right branch, hopefully it checks out." >> get_skel.sh
				printf "%s\n" "git clone -b "${tag}" "${scmurl}" "../../../../${scmdir}/${tag}/extractedSources"" >> get_skel.sh
				printf "%s\n" "ln -s "../../../../${scmdir}/${tag}/extractedSources" "extractedSources"" >> get_skel.sh
			fi
			cd ../../../../../
		elif [ "$(printf "%s\n" "$connection" | cut -c 1-8)" = "scm:svn" ]; then
			printf "GETTING SOURCES %s FROM SVN\n" "$(printf "%s" "$connection" | cut -c 9-)"
			cd sources/structure/${groupId}/${artifactId}/${version}

			scmurl="$(printf "%s\n" "$connection" | cut -c 9-)"

			scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"

			if ! [ -d "../../../../${scmdir}/${tag}" ]; then
				mkdir -p "../../../../${scmdir}/${tag}/extractedSources"
				svn co -r "${tag}" "${scmurl}" "../../../../${scmdir}/${tag}/extractedSources"
			fi
			ln -s "../../../../${scmdir}/${tag}/extractedSources" "extractedSources"

			printf "%s\n" "#Great, we found the subversion and the right tag, hopefully it checks out." >> get_skel.sh
			printf "%s\n" "svn co -r "${tag}" "${scmurl}" "../../../../${scmdir}/${tag}/extractedSources"" extractedSources" >> get_skel.sh
			printf "%s\n" "ln -s "../../../../${scmdir}/${tag}/extractedSources" "extractedSources"" extractedSources" >> get_skel.sh
			cd ../../../../../
		elif [ "$(printf "%s\n" "$connection" | cut -c 1-4)" = "git@" ]; then
			connection="$(printf "%s" "${connection}" | sed "s#:#/#g" | sed "s#git@#git://#g")"
			printf "GETTING SOURCES %s FROM GIT\n" "$(printf "%s" "$connection")"
			cd sources/structure/${groupId}/${artifactId}/${version}
			if [ "${tag}" = "HEAD" ] || [ "${tag}" = "" ]; then
				scmurl="$(printf "%s" "$connection")"

				scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"

				if ! [ -d "../../../../${scmdir}/HEAD" ]; then
					mkdir -p "../../../../${scmdir}/HEAD/extractedSources"
					git clone -b "HEAD" "${scmurl}" "../../../../${scmdir}/HEAD/extractedSources"
				fi

				ln -s "../../../../${scmdir}/HEAD/extractedSources" "extractedSources"

				printf "%s\n" "#We found the git, but the branch is unknown, it might need futher modifications." >> get_skel.sh
				printf "%s\n" "git clone -b "HEAD" "${scmurl}" "../../../../${scmdir}/HEAD/extractedSources"" extractedSources" >> get_skel.sh
				printf "%s\n" "ln -s "../../../../${scmdir}/HEAD/extractedSources" "extractedSources"" >> get_skel.sh
			else 

				scmurl="$(printf "%s" "$connection")"

				scmdir="$(printf "%s\n" "${scmurl}" | sed "s#//##g")"

				if ! [ -d "../../../../${scmdir}/${tag}" ]; then
					mkdir -p "../../../../${scmdir}/${tag}"
					git clone -b "${tag}" "${scmurl}" "../../../../${scmdir}/${tag}/extractedSources"
				fi
				ln -s "../../../../${scmdir}/${tag}/extractedSources" "extractedSources"

				printf "%s\n" "#Great, we found the git and the right branch, hopefully it checks out." >> get_skel.sh
				printf "%s\n" "git clone -b "${tag}" "${scmurl}" "../../../../${scmdir}/${tag}/extractedSources"" extractedSources" >> get_skel.sh
				printf "%s\n" "ln -s "../../../../${scmdir}/${tag}/extractedSources" "extractedSources"" >> get_skel.sh
			fi
			cd ../../../../../
		else
			printf "GETTING SOURCES %s FROM JAR\n" "$(printf "%s" "$connection" | cut -c 5-)"
			mkdir -p sources/structure/${groupId}/${artifactId}/${version}/extractedSources
			if ! [ -f sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar ]; then
				wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}-sources.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar
				sleep 1
			fi

			if [ -f sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar ]; then
				printf "%s\n" "#All the source we found was in a -sources.jar, which are known to be incomplete. You may be better off trying to find an alternative source" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
				printf "%s\n" "wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}-sources.jar" -O ${artifactId}-${version}-sources.jar" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
				unzip -o sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}-sources.jar -d sources/structure/${groupId}/${artifactId}/${version}/extractedSources
				printf "%s\n" "unzip -o ${artifactId}-${version}-sources.jar -d extractedSources" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
			fi
		fi
	fi

	if [ "$(du "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" | cut -c 1-1)" = "0" ] || ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
		if [ -f "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar" ]; then
			rm "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar"
		fi
		wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar
		sleep 1
	fi

	if [ -f sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar ]; then
		if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/Decompiled" ]; then
			mkdir -p sources/structure/${groupId}/${artifactId}/${version}/Decompiled
		fi

		#if directory is empty, decompile
		find "sources/structure/${groupId}/${artifactId}/${version}/Decompiled" -maxdepth 0 -empty -exec procyon -jar sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar -o sources/structure/${groupId}/${artifactId}/${version}/Decompiled \;
	fi

	if [ -f sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.jar ]; then
		if ! [ -d "sources/structure/${groupId}/${artifactId}/${version}/Decompiled" ]; then
			mkdir sources/structure/${groupId}/${artifactId}/${version}/Decompiled
		fi
		printf "%s\n" "#This is not ideal, all sourceGetter5 could find is a binary jar, so you will need to decompile it and/or find a different source" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
		printf "%s\n" "wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O ${artifactId}-${version}.jar" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh

		printf "%s\n" "wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.jar" -O ${artifactId}-${version}.jar" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
		printf "%s\n" "procyon -jar %s-%s.jar -o Decompiled" "${artifactId}" "${version}" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
	fi

	if [ -d "sources/structure/${groupId}/${artifactId}/${version}/extractedSources" ]; then
		if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/extractedSources/pom.xml" ]; then
			cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/extractedSources/pom.xml"
			printf "%s\n" "#no pom.xml was found, getting one. It may need modification." >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
			printf "cd extractedSources\n" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
			printf "%s\n" "wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.pom" -O extractedSources/pom.xml" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
		else
			printf "cd extractedSources\n" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
		fi
	elif [ -d "sources/structure/${groupId}/${artifactId}/${version}/Decompiled" ]; then
		if ! [ -f "sources/structure/${groupId}/${artifactId}/${version}/Decompiled/pom.xml" ]; then
			cp -a "sources/structure/${groupId}/${artifactId}/${version}/${artifactId}-${version}.pom" "sources/structure/${groupId}/${artifactId}/${version}/Decompiled/pom.xml"
			printf "%s\n" "#no pom.xml was found, getting one. It may need modification." >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
			printf "cd extractedSources\n" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
			printf "%s\n" "wget "${repository}$(printf "%s\n" "${groupId}" | sed "s#\.#/#g")/${artifactId}/${version}/${artifactId}-${version}.pom" -O Decompiled/pom.xml" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
		else
			printf "cd extractedSources\n" >> sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh
		fi
	fi

	#chmod +x sources/structure/${groupId}/${artifactId}/${version}/get_skel.sh

	#printf "%s\n" '#!/bin/sh' > sources/structure/${groupId}/${artifactId}/${version}/build_skel.sh
	#printf "%s\n" "cd extractedSources" >> sources/structure/${groupId}/${artifactId}/${version}/build_skel.sh
	#printf "%s\n" "mvn -o -s "\${1}/settings.xml" package" >> sources/structure/${groupId}/${artifactId}/${version}/build_skel.sh
	#printf "%s\n" "mvn -o -s "\${1}/settings.xml" install" >> sources/structure/${groupId}/${artifactId}/${version}/build_skel.sh

	#chmod +x sources/structure/${groupId}/${artifactId}/${version}/build_skel.sh

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

				recurse "${newGroupId}" "${newArtifactId}" "${newVersion}" "${1}" "${2}" "${3}"
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
			if [ "${newVersion}" = "\${project.version}" ] || [ "${newVersion}" = "\${pom.version}" ]; then
				newVersion="${version}"
			elif [ "$(printf "%s\n" "$newVersion" | cut -c 1-2)" = "\${" ]; then
				theSpecial="$(printf "${newVersion%\}}" | cut -c 3-)"
				special="$(printf "%s" "$theXMLnoBuild" | sed -n "s:.*<${theSpecial}>\(.*\)</${theSpecial}>.*:\1:p")"
				newVersion="${special}"
			fi
		fi
		depOn=0
	fi

	done

	if [ "${newGroupId}" != "NOTHING" ] && [ "${newArtifactId}" != "NOTHING" ] && [ "${newGroupId}" != "\*" ] && [ "${newArtifactId}" != "\*" ]; then
		if [ "$newVersion" = "" ]; then
			newVersion="NOTHING"
		fi
		recurse "${newGroupId}" "${newArtifactId}" "${newVersion}" "${1}" "${2}" "${3}"
	fi

	#dependencies="$(printf "%s" "$theXMLBuild" | grep -o '<plugin>.*</plugin>')"

	#newGroupId="NOTHING"
	#newArtifactId="NOTHING"
	#newVersion="NOTHING"

	#for dependency in $(printf "$dependencies\n"); do
	#if [ "$(printf "%s" "${dependency}" | cut -c 1-8)" = "groupId>" ]; then
	#	if [ "${newGroupId}" != "NOTHING" ] && [ "${newArtifactId}" != "NOTHING" ]; then
	#		recurse "${newGroupId}" "${newArtifactId}" "${newVersion}" "     ${indent}"
	#	fi
	#	newGroupId="$(printf "%s" "${dependency}" | cut -c 9-)"
	#	if [ "${newGroupId}" = "\${project.groupId}" ] || [ "${newGroupId}" = "\${pom.groupId}" ]; then
	#		newGroupId="${groupId}"
	#	fi
	#elif [ "$(printf "%s" "${dependency}" | cut -c 1-11)" = "artifactId>" ]; then
	#	newArtifactId="$(printf "%s" "${dependency}" | cut -c 12-)"
	#	if [ "${newArtifactId}" = "\${project.artifactId}" ] || [ "${newArtifactId}" = "\${pom.artifactId}" ]; then
	#		newArtifactId="${artifactId}"
	#	fi
	#elif [ "$(printf "%s" "${dependency}" | cut -c 1-8)" = "version>" ]; then
	#	newVersion="$(printf "%s" "${dependency}" | cut -c 9-)"
	#	if [ "${newVersion}" = "\${project.version}" ] || [ "${newVersion}" = "\${pom.version}" ]; then
	#		newVersion="${version}"
	#	elif [ "$(printf "%s\n" "$newVersion" | cut -c 1-2)" = "\${" ]; then
	#		theSpecial="$(printf "${newVersion%\}}" | cut -c 3-)"
	#		special="$(printf "%s" "$theXMLBuild" | sed -n "s:.*<${theSpecial}>\(.*\)</${theSpecial}>.*:\1:p")"
	#		newVersion="${special}"
	#	fi
	#fi
	#done

	#if [ "${newGroupId}" != "NOTHING" ] && [ "${newArtifactId}" != "NOTHING" ]; then
	#	recurse "${newGroupId}" "${newArtifactId}" "${newVersion}" "     ${indent}"
	#fi

	IFS="$old_ifs"
