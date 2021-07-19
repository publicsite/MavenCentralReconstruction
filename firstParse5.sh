#!/bin/sh

##tryFixUnderErrors="100"

mineSound(){
paplay /usr/share/sounds/freedesktop/stereo/complete.oga
}

isNumeric(){
case $1 in
    ''|*[!0-9]*) echo bad ;;
    *) echo good ;;
esac
}

doStuff(){
thepwd="$1"
number="$2"
tryFixUnderErrors="$3"
line="$4"

		found="1"

		#if it's already been built, do not rebuild


		if [ -f "${thepwd}/buildlog/$(basename ${line%_decompiled.secondary.fileList}_vanilla_$(printf "%s" "${line}" | cut -d "/" -f 4).built)" ]; then
			if [ -f "${thepwd}/buildlog/$(basename ${line%_decompiled.secondary.fileList}_vanilla_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)" ]; then
				rm "${thepwd}/buildlog/$(basename ${line%_decompiled.secondary.fileList}_vanilla_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)"
			fi
			found="0"
		fi

		if [ -f "${thepwd}/buildlog/$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).built)" ]; then
			if [ -f "${thepwd}/buildlog/$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)" ]; then
				rm "${thepwd}/buildlog/$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)"
			fi
			found="0"
		fi

		printf "%s" "${line%.fileList}" > "${thepwd}/buildlog/$(basename "${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).pointer")"

		if [ "${found}" = "1" ]; then

			bnTheFile="$(basename "${line}")"
			
			if  [ "$5" = "vanilla" ]; then
				#groupArtifact="${line%.vanilla.fileList}"
				bnTheFileMinusType="${bnTheFile%_vanilla.fileList}"
			elif [ "$5" = "decompiled" ]; then
				#groupArtifact="${line%.decompiled.fileList}"
				bnTheFileMinusType="${bnTheFile%_decompiled.fileList}"
			else
				#groupArtifact="${line%.decompiled.secondary.fileList}"
				bnTheFileMinusType="${bnTheFile%_decompiled.secondary.fileList}"
			fi
			basicPath="$(dirname "${line}")"
			cd "$basicPath"
			if ! [ -d "$bnTheFileMinusType" ]; then
				mkdir "$bnTheFileMinusType"
			fi

			theClassPath="${thepwd}/fileListsAndDeps/$(printf "%s" ${basicPath} | cut -c 3-)/build"

			if [ -f "${thepwd}/sources/structure/${basicPath}/dependencies.txt" ]; then

				oldIFS="$IFS"
				IFS="$(printf "\n")"
				while read line2; do
					theClassPath="${theClassPath}:${thepwd}/fileListsAndDeps/${line2}/build"
				done < "${thepwd}/sources/structure/${basicPath}/dependencies.txt"
				IFS="$oldIFS"

				theClassPath=" --class-path ${theClassPath}"
			else
				theClassPath=" --class-path ${theClassPath}"
			fi

			theClassPath="$(printf "%s" "$theClassPath" | cut -c 2-)"

			filesToCompile=""

			oldIFS="$IFS"
			IFS="$(printf "\n")"
			while read line2; do
				if [ -f "${thepwd}/sources/structure/$(printf "%s" "${basicPath}" | cut -c 3-)/extractedSources/$(printf "%s" "${line2}" | cut -d / -f 5-)" ]; then
					filesToCompile="${filesToCompile} $(printf "%s" "${line2}" | cut -d / -f 5-)"
				fi
			done < "${bnTheFile}"
			IFS="$oldIFS"

			printf "Cycle %s...\n" "${number}" 1>&2 
#echo "${basicPath}==="

			cd "${thepwd}/sources/structure/$(printf "%s" "${basicPath}" | cut -c 3-)/extractedSources"
			if [ ! -d "${thepwd}/fileListsAndDeps/$(printf "%s" ${basicPath} | cut -c 3-)/build" ]; then
				mkdir "${thepwd}/fileListsAndDeps/$(printf "%s" ${basicPath} | cut -c 3-)/build"
			fi
			printf "javac %s -d "%s/fileListsAndDeps/%s/build"%s 1>/dev/null 2>%s/buildlog/%s\n" "${theClassPath}" "${thepwd}" "$(printf "%s" ${basicPath} | cut -c 3-)" "${filesToCompile}" "${thepwd}" "$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)"
			javac ${theClassPath} -d "${thepwd}/fileListsAndDeps/$(printf "%s" ${basicPath} | cut -c 3-)/build"${filesToCompile} 1>/dev/null 2>"${thepwd}/buildlog/$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)"
			if [ "$?" = "0" ]; then
				cd "${thepwd}/fileListsAndDeps/${basicPath}"
				if [ -f "${thepwd}/buildlog/$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)" ]; then
					rm "${thepwd}/buildlog/$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)"
				fi
				mineSound
				printf "Parse %s succeeded.\n" "$number" >> "${thepwd}/buildlog/$(basename "${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).built")"
				printf "... Compiled\n\n" 1>&2
				#cd "${thepwd}/classpath"
				#find "../fileListsAndDeps/$(dirname "${line}")/${bnTheFile%.fileList}" | while read line2; do
				#	baseFile="$(printf "%s\n" "${line2}" | cut -d "/" -f 8-)"
				#		if [ -d "${line2}" ]; then
				#			if ! [ -d "${PWD}/${baseFile}" ]; then
				#				mkdir "${PWD}/${baseFile}"
				#			fi
				#		elif [ -f "${line2}" ]; then
				#			if [ -f "${PWD}/${baseFile}" ]; then
				#				rm "${PWD}/${baseFile}"
				#			fi
				#			ln -s "${thepwd}/fileListsAndDeps/$(printf "${line2}" | cut -d "/" -f 4-)" "${baseFile}"
				#		fi
				#done
			else

				##delete this line
				##if [ "$(tail -n 1 "${thepwd}/buildlog/$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)" | cut -d " " -f 1)" -le "${tryFixUnderErrors}" ]; then


				cd "${thepwd}/fileListsAndDeps/${basicPath}"


#				if [ ! -f "${thepwd}/fileListsAndDeps/${basicPath}/extractedSources/${bnTheFile}.classErrors.log" ]; then
#fixes/${basicPath}

					mkdir -p "${thepwd}/fixes/structure/${basicPath}/generatedPatches"

					filesToCompile=""

					oldIFS="$IFS"
					IFS="$(printf "\n")"
					while read line2; do
						mkdir -p "${thepwd}/fixes/structure/$(dirname "${line2}")"
						if [ -f "${thepwd}/sources/structure/${line2}" ]; then
							if [ -f "${thepwd}/fixes/structure/${line2}" ]; then
								rm "${thepwd}/fixes/structure/${line2}"
							fi
							cp -p "${thepwd}/sources/structure/${line2}" "${thepwd}/fixes/structure/$(dirname "${line2}")/"
							filesToCompile="${filesToCompile} $(printf "%s" "${line2}" | cut -d / -f 5-)"
						fi
					done < "${bnTheFile}"
					IFS="$oldIFS"

					mkdir -p "${thepwd}/fixes/structure/${basicPath}/extractedSources"
					cd "${thepwd}/fixes/structure/${basicPath}/extractedSources"

					initAmountOfErrors="99999"
					oldAmountOfErrors="${initAmountOfErrors}"

					patchNumber="0"

					cp -p "${thepwd}/buildlog/$(basename ${line%.fileList}_$(printf "%s" "${line}" | cut -d "/" -f 4).failed)" "${thepwd}/fixes/structure/$(printf "%s" "${basicPath}" | cut -c 3-)/extractedSources/${bnTheFile}.classErrors.log"

#cat ${bnTheFile}.classErrors.log

					while true; do

						numberOfErrors="$(tail -n 1 "${thepwd}/fixes/structure/$(printf "%s" "${basicPath}" | cut -c 3-)/extractedSources/${bnTheFile}.classErrors.log" | cut -d " " -f 1)"

						if [ "$(isNumeric ${numberOfErrors})" = "bad" ] && [ "${numberOfErrors})" != "" ]  ; then
							numberOfErrors=9999
						fi

						fixBasicPath="$(printf "%s" "${basicPath}" | cut -c 3-)"

						if [ "${numberOfErrors}" = "" ]; then

							#===goodSet Patches code starts here===
							if [ "$(find "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches" -type f -maxdepth 1 -name *".patch" | wc -l )" != "0" ]; then
								if [ ! -d "${thepwd}/fixes/structure/${fixBasicPath}/goodSetOfPatches" ]; then
									mkdir "${thepwd}/fixes/structure/${fixBasicPath}/goodSetOfPatches"
								fi
								find "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/" -maxdepth 1 -type f -name "${bnTheFile}_"*".patch" -exec cp -p {} "${thepwd}/fixes/structure/${fixBasicPath}/goodSetOfPatches/" \;
								find "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/" -maxdepth 1 -type f -name "${bnTheFile}_"*".patch" -exec rm {} \;
								find "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/" -maxdepth 1 -type f -name "${bnTheFile}_overwrites_"*".sh" -exec cp -p {} "${thepwd}/fixes/structure/${fixBasicPath}/goodSetOfPatches/" \;
								find "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/" -maxdepth 1 -type f -name "${bnTheFile}_overwrites_"*".sh" -exec rm {} \;
							fi
								printf "\nAll errors fixed in %s\n" "$bnTheFile"
								mineSound
								break
							#===goodSet Patches code ends here===

						elif [ "${numberOfErrors}" -ge "${oldAmountOfErrors}" ]; then
							printf "The last patch didn't help, it will be deleted, and this means no more patches can be generated for %s in this cycle\n\n" "$bnTheFile"

							if [ -f "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_$(expr ${patchNumber} - 1).patch" ]; then
									rm "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_$(expr ${patchNumber} - 1).patch"
							fi

							#try using the decompiled .java file where errors occur instead

							cd "${thepwd}/fileListsAndDeps/${basicPath}"

							filesToCompile=""

							printf "Attempting replacing some .java files with their [whole] decompiled versions.\n"

							overwroteSome="0"

							zfiles=""
IFS='
'

							printf "#!/bin/sh\n" >> "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh"

							while read line2; do
								for zFile in $(grep "^.*\.java:[0-9]*:[0-9]*" "${thepwd}/fixes/structure/${fixBasicPath}/extractedSources/${bnTheFile}.classErrors.log" | cut -d ":" -f 1); do
									zound="0"

									for checkzFile in $zfiles; do
										if [ "$checkzFile" = "$zFile" ]; then
											zound=1
											break
										fi
									done

									if [ "$zound" = "0" ]; then

										if [ "$(printf "%s" "${line2}" | cut -d "/" -f 5-)" = "${zFile}" ]; then
											decompiledNew="$(printf "%s" "${line2}" | cut -d "/" -f 1-3)/Decompiled/$(printf "%s" "${line2}" | cut -d "/" -f 5-)"

											if [ -f "${thepwd}/sources/structure/${decompiledNew}" ]; then
												if [ -f "${thepwd}/fixes/structure/${line2}" ]; then
													rm "${thepwd}/fixes/structure/${line2}"
												fi
												printf "Overwriting %s\n" "$(basename ${decompiledNew})"
												printf "cp -p "sources/structure/%s" "/fixes/structure/%s/"\n" "${decompiledNew}" "$(dirname "${line2}")" >> "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh"
												overwroteSome="1"
												cp -p "${thepwd}/sources/structure/${decompiledNew}" "${thepwd}/fixes/structure/$(dirname "${line2}")/"
											fi
										fi
zfiles="${zfiles}
${zFile}"
									fi
								done

								filesToCompile="${filesToCompile} ${thepwd}/fixes/structure/$(printf "%s" "${basicPath}" | cut -c 3-)/extractedSources/$(printf "%s" "${line2}" | cut -d "/" -f 5-)"

							done < "${bnTheFile}"
							IFS="$oldIFS"


							if [ "${overwroteSome}" = "0" ]; then
								printf "No matching decompiled .java files found.\n\n"
								if [ -f "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh" ]; then
										rm "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh"
								fi
								break
							else
								printf "Attempting to compile with overwritten .java file(s).\n"

								cd "${thepwd}/fixes/structure/${basicPath}/extractedSources"

								javac ${theClassPath} -d "${thepwd}/gsAndDeps/$(printf "%s" ${basicPath} | cut -c 3-)/build" ${filesToCompile} 1>/dev/null 2>"${thepwd}/fixes/structure/${fixBasicPath}/extractedSources/${bnTheFile}.classErrors.log"

								oldAmountOfErrorsTemp="${numberOfErrors}"
								numberOfErrorsTemp="$(tail -n 1 "${thepwd}/fixes/structure/$(printf "%s" "${basicPath}" | cut -c 3-)/extractedSources/${bnTheFile}.classErrors.log" | cut -d " " -f 1)"

								if [ "${numberOfErrorsTemp}" = "" ]; then
									#===goodSet Patches code starts here===
									if [ "$(find "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches" -type f -maxdepth 1 -name *".patch" | wc -l )" != "0" ]; then
										if [ ! -d "${thepwd}/fixes/structure/${fixBasicPath}/goodSetOfPatches" ]; then
											mkdir "${thepwd}/fixes/structure/${fixBasicPath}/goodSetOfPatches"
										fi
										find "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/" -maxdepth 1 -type f -name "${bnTheFile}_"*".patch" -exec cp -p {} "${thepwd}/fixes/structure/${fixBasicPath}/goodSetOfPatches/" \;
										find "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/" -maxdepth 1 -type f -name "${bnTheFile}_"*".patch" -exec rm {} \;
										find "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/" -maxdepth 1 -type f -name "${bnTheFile}_overwrites_"*".sh" -exec cp -p {} "${thepwd}/fixes/structure/${fixBasicPath}/goodSetOfPatches/" \;
										find "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/" -maxdepth 1 -type f -name "${bnTheFile}_overwrites_"*".sh" -exec rm {} \;
									fi
										printf "\nAll errors fixed in %s\n" "$bnTheFile"
										mineSound
										break
									#===goodSet Patches code ends here===
								elif [ "${numberOfErrorsTemp}" -lt "${oldAmountOfErrorsTemp}" ]; then
										if [ ! -d "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches" ]; then
											mkdir "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches"
										fi
										if [ -f "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh" ]; then
											cp "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh" "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/"
											rm "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh"
										fi

									patchNumber="$(expr $patchNumber + 1)"

									printf "Replacing some files in %s helped by reducing the amount of errors.\n" "${bnTheFile}"
								else
									printf "Replacing files ceased to help for %s in this cycle\n\n" "${bnTheFile}"
									if [ -f "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh" ]; then
										rm "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_overwrites_${patchNumber}.sh"
									fi
									break
								fi
							fi
						else
							if [ "${oldAmountOfErrors}" != "${initAmountOfErrors}" ]; then
								if [ ! -d "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches" ]; then
									mkdir "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches"
								fi
								if [ -f "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_$(expr ${patchNumber} - 1).patch" ]; then
									cp "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_$(expr ${patchNumber} - 1).patch" "${thepwd}/fixes/structure/${fixBasicPath}/partialPatches/"
									rm "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_$(expr ${patchNumber} - 1).patch"
								fi
							fi
							printf "\nFound %s remaining error(s) in %s\n" "$numberOfErrors" "$bnTheFile"
						fi

						#if [ "${oldAmountOfErrors}" != "${initAmountOfErrors}" ]; then
						#	mineSound
						#fi

						printf "Attempting to generate patch\n"

						"${thepwd}/getMethodsFromLog3.sh" "${thepwd}/fixes/structure/${fixBasicPath}/extractedSources/${bnTheFile}.classErrors.log" "${thepwd}/fixes/structure/${fixBasicPath}/extractedSources" "${thepwd}/sources/structure/${fixBasicPath}/Decompiled" "${thepwd}" >"${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_${patchNumber}.patch"
						patch -p0 < "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches/${bnTheFile}_${patchNumber}.patch"

						printf "Attempting recompile after applying patch\n"
						javac ${filesToCompile} ${theClassPath} -d "${PWD}/build" 1>/dev/null 2>"${thepwd}/fixes/structure/${fixBasicPath}/extractedSources/${bnTheFile}.classErrors.log"

						patchNumber="$(expr $patchNumber + 1)"
						oldAmountOfErrors="${numberOfErrors}"

					done
	
					cd "${thepwd}/fixes/structure/${fixBasicPath}"

					#delete generated patches dir if empty
					if [ -d "$( find "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches" -type f | wc -l )" ]; then
						if [ "$( find "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches" -type f | wc -l )" = 0 ]; then
							rmdir "${thepwd}/fixes/structure/${fixBasicPath}/generatedPatches"
						fi
					fi

					#clean up java files
					cd "${thepwd}/fileListsAndDeps/${basicPath}"
					IFS="$(printf "\n")"
					while read line2; do
						if [ -f "${thepwd}/fixes/structure/${line2}" ]; then
							rm "${thepwd}/fixes/structure/${line2}"
						fi
					done < "${bnTheFile}"
					IFS="$oldIFS"

				##delete this fi
				##else
				##	printf "More than %s errors ... not attempting to fix\n\n" "${tryFixUnderErrors}"
				##fi

				fi

			cd "${thepwd}/fileListsAndDeps"
		fi
}

if ! [ -f getMethodsFromSources ]; then
gcc getMethodsFromSources.c -o getMethodsFromSources
fi

if ! [ -f getMethodsFromSources ]; then
printf "You need the program to get the methods.\n"
exit
fi

thepwd="$PWD"
if ! [ -d "${PWD}/fixes" ]; then
mkdir fixes
fi
if ! [ -d "${PWD}/classpath" ]; then
mkdir classpath
fi
if ! [ -d "${PWD}/buildlog" ]; then
mkdir buildlog
fi
cd fileListsAndDeps
goagain="1"
#Cycle 1 compiles 'vanilla' (source code availiable). That said, it generates patches using decompiled sources.
while [ "${goagain}" -gt "0" ]; do
	oldNumber="$(find "${thepwd}/buildlog" -maxdepth 1 -type f -name "*.built" | wc -l)"
	printf "==Cycle 1.%s Starting!==\n\n" "${goagain}"

	find . -maxdepth 4 -type f -name "*_vanilla.fileList" | shuf | while read line; do
		doStuff "$thepwd" "1.1.${goagain}" "$tryFixUnderErrors" "$line" "vanilla"
	done

	newNumber="$(find "${thepwd}/buildlog" -maxdepth 1 -type f -name "*.built" | wc -l)"

	#if we have compiled something, try recompiling the tree
	if [ "${oldNumber}" = "${newNumber}" ]; then
		goagain=0
	else
		goagain="$(expr ${goagain} + 1)"
	fi
done

goagain="1"
#Cycle 2 compiles decompiled code, where sources weren't availiable
#It then attempts to go over the vanilla sources again
while [ "${goagain}" -gt "0" ]; do
	oldNumber="$(find "${thepwd}/buildlog" -maxdepth 1 -type f -name "*.built" | wc -l)"
	printf "==Cycle 2.%s Starting!==\n\n" "${goagain}"

	find . -maxdepth 4 -type f -name "*_decompiled.fileList" | shuf | while read line; do
		doStuff "$thepwd" "2.1.${goagain}" "$tryFixUnderErrors" "$line" "decompiled"
	done

	find . -maxdepth 4 -type f -name "*_vanilla.fileList" | shuf | while read line; do
		doStuff "$thepwd" "2.2.${goagain}" "$tryFixUnderErrors" "$line" "vanilla"
	done

	newNumber="$(find "${thepwd}/buildlog" -maxdepth 1 -type f -name "*.built" | wc -l)"

	#if we have compiled something, try recompiling the tree
	if [ "${oldNumber}" = "${newNumber}" ]; then
		goagain=0
	else
		goagain="$(expr ${goagain} + 1)"
	fi
done

goagain="1"
#Cycle 3 compiles decompiled source code, where sources were availiable
#It then attempts to go over the decompiled code, where sources weren't availiable, again
#It then attempts to go over the vanilla code
while [ "${goagain}" -gt "0" ]; do
	oldNumber="$(find "${thepwd}/buildlog" -maxdepth 1 -type f -name "*.built" | wc -l)"
	printf "==Cycle 3.%s Starting!==\n\n" "${goagain}"

	find . -maxdepth 4 -type f -name "*_decompiled.secondary.fileList" | shuf | while read line; do
		doStuff "$thepwd" "3.1.${goagain}" "$tryFixUnderErrors" "$line" "decompiledSecondary"
	done

	find . -maxdepth 4 -type f -name "*_decompiled.fileList" | shuf | while read line; do
		doStuff "$thepwd" "3.2.${goagain}" "$tryFixUnderErrors" "$line" "decompiled"
	done

	find . -maxdepth 4 -type f -name "*_vanilla.fileList" | shuf | while read line; do
		doStuff "$thepwd" "3.3.${goagain}" "$tryFixUnderErrors" "$line" "vanilla"
	done

	newNumber="$(find "${thepwd}/buildlog" -maxdepth 1 -type f -name "*.built" | wc -l)"

	#if we have compiled something, try recompiling the tree
	if [ "${oldNumber}" = "${newNumber}" ]; then
		goagain=0
	else
		goagain="$(expr ${goagain} + 1)"
	fi
done