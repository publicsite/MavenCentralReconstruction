#!/bin/sh

isNumeric(){
case $1 in
    ''|*[!0-9]*) echo bad ;;
    *) echo good ;;
esac
}

thepwd="$PWD"

			apackage="$(echo "$1" | cut -d '/' -f 3-)"

			directories=""

			if [ -d "sources/structure/$apackage/extractedSources" ] && [ -d "sources/structure/$apackage/DecompiledCFR" ]; then

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

					theClassPath=" -cp ${theClassPath}"
				else
					theClassPath=" -cp ${theClassPath}"
				fi

				theClassPath="$(printf "%s" "$theClassPath" | cut -c 2-)"

				for sourcejavafile in $(find sources/structure/${apackage}/extractedSources -name "*.java"); do
					if [ -f "buildlog/$apackage/fromSource/$(basename "${sourcejavafile%.java}").failed" ]; then
						if ! [ -f "buildlog/$apackage/hybrids/$(basename "${sourcejavafile%.java}").success" ]; then
							diditbuild=0

							if [ -d "sources/structure/${apackage}/DecompiledCFR" ]; then 
								decompiledjavafile="$(find sources/structure/${apackage}/DecompiledCFR -name $(basename ${sourcejavafile}) | head -n 1)"
								if [ "$decompiledjavafile" != "" ]; then

									echo "Attempting to make a hybrid for ${sourcejavafile} using CFR"

									mkdir -p buildlog/$apackage/hybrids
									mkdir -p classes/$apackage/hybrids

									cp -a "buildlog/$apackage/fromSource/$(basename "${sourcejavafile%.java}").failed" buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed

									cp -a "${sourcejavafile}" "hybrids/${apackage}/"


									numberOfErrors="-1"
									oldAmountOfErrors=999999
									while [ "$oldAmountOfErrors" != "$numberOfErrors" ]; do
										mkdir -p hybrids/${apackage}

										./generateHybridFile.sh "buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed" "hybrids/${apackage}/$(basename ${sourcejavafile})" "$decompiledjavafile" "$thepwd"
										javac ${theClassPath} -d "classes/$apackage/hybrids" -sourcepath "$directories" hybrids/${apackage}/$(basename ${sourcejavafile}) 2>buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed
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
											diditbuild=1
	
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

							if [ "$diditbuild" != "1" ]; then
								rm hybrids/${apackage}/$(basename ${sourcejavafile})
								if [ -d "sources/structure/${apackage}/DecompiledProcyon" ]; then 
									decompiledjavafile="$(find sources/structure/${apackage}/DecompiledProcyon -name $(basename ${sourcejavafile}) | head -n 1)"
									if [ "$decompiledjavafile" != "" ]; then

										echo "Attempting to make a hybrid for ${sourcejavafile} using Procyon"

										mkdir -p buildlog/$apackage/hybrids
										mkdir -p classes/$apackage/hybrids

										cp -a "buildlog/$apackage/fromSource/$(basename "${sourcejavafile%.java}").failed" buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed

										cp -a "${sourcejavafile}" "hybrids/${apackage}/"


										numberOfErrors="-1"
										oldAmountOfErrors=999999
										while [ "$oldAmountOfErrors" != "$numberOfErrors" ]; do
											mkdir -p hybrids/${apackage}

											./generateHybridFile.sh "buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed" "hybrids/${apackage}/$(basename ${sourcejavafile})" "$decompiledjavafile" "$thepwd"
											javac ${theClassPath} -d "classes/$apackage/hybrids" -sourcepath "$directories" hybrids/${apackage}/$(basename ${sourcejavafile}) 2>buildlog/${apackage}/hybrids/$(basename "${sourcejavafile%.java}").failed
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
												diditbuild=1
		
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

							if [ "$diditbuild" != "1" ]; then
								rm hybrids/${apackage}/$(basename ${sourcejavafile})
							fi
						fi
					fi
				done
			fi
