#!/bin/sh
#A program to produce a patch, updating broken methods in Java sources, given a working source file and a non-working source file, and a javac error log
#arg1 javac stderr log file
#arg2 java source file (non-working)
#arg3 java binary source file (working; this can be decompiled from a .class file)

OLD_UMASK="$(umask)"
umask 0022

printIfNumeric(){
read isnumber
case $isnumber in
    ''|*[0-9]*) printf "%s\n" ${isnumber} ;;
esac
}

paramCheck(){
old_ifs="$IFS"
IFS=','
for param in "$1"; do
	if [ "$(printf "%s" "$param" | sed "s#\s##g" | cut -c 1-5)" = "final" ]; then
		printf "%s" "$param" | rev | cut -d " " -f 2- | rev | sed "s#\s##g" | cut -c 6-
	else
		printf "%s" "$param" | rev | cut -d " " -f 2- | rev | sed "s#\s##g"
	fi
done
}

checkMatchFunction(){
allParamsA="$(printf "%s" "${1}" | cut -d "(" -f 2 | cut -d ")" -f 1)"
allParamsB="$(printf "%s" "${2}" | cut -d "(" -f 2 | cut -d ")" -f 1)"
declarationA="$(printf "%s" "${1}" | cut -d "(" -f 1 | sed "s#\s##g" )"
declarationB="$(printf "%s" "${2}" | cut -d "(" -f 1 | sed "s#\s##g" )"
testA="$(paramCheck "$allParamsA" | tr -d '\n' )"
testB="$(paramCheck "$allParamsB" | tr -d '\n' )"
if [ "$testA" != "$testB" ]; then
printf "AAA: %s< %s<<\n" "$testA" "$testB"
return
fi
#if [ "$declarationA" != "$declarationB" ]; then
#printf "BBB: %s< %s<<\n" "$testA" "$testB"
#return
#fi
}

##replaced with C program
#getMethodsFromSources()
#{
#lineNumber=1;
#bracketIndex="0"
#cat "$1" | while read line; do
#if [ "$(printf "%s" "$line" | grep "^\s*//.*")" = "" ]; then
#	if [ "$(printf "%s" "$line" | grep "^.*{")" != "" ]; then
#		if [ "$bracketIndex" = "1" ]; then
#			printf "%s\t%s," "$line" "$lineNumber"
#		fi
#	bracketIndex="$(expr $bracketIndex + $(printf "%s" "$line" | grep -o \{ | wc -w) - $(printf "%s" "$line" | grep -o \} | wc -w))"
#	elif [ "$(printf "%s" "$line" | grep "^.*}")" != "" ]; then
#	#echo $bracketIndex
#		if [ "$bracketIndex" = "2" ]; then
#			printf "%s\n" "$lineNumber"
#		fi
#	bracketIndex="$(expr $bracketIndex + $(printf "%s" "$line" | grep -o \{ | wc -w) - $(printf "%s" "$line" | grep -o \} | wc -w))"
#	fi
#fi
#	lineNumber="$(expr $lineNumber + 1)"
#done
#}

getRangesWithDuplicates(){

files=""
IFS='
'
	for aFile in $(grep "^.*\.java:[0-9]*:[0-9]*" "$1" | cut -d ":" -f 1); do
		found="0"

		for checkFile in $files; do
			if [ "$checkFile" = "$aFile" ]; then
				found=1
				break
			fi
		done

		if [ "$found" = "0" ]; then
			for line in $("${2}/getMethodsFromSources" "${aFile}"); do

				grep "^.*${aFile}:[0-9]*:[0-9]*" "$1" | cut -d ":" -f 2 | printIfNumeric | while read lineNumber; do
					testOne="$(printf "%s" "$line" | rev | cut -f 1 | rev | cut -d "," -f 1 | printIfNumeric)"
					testTwo="$(printf "%s" "$line" | rev | cut -f 1 | rev | cut -d "," -f 2 | printIfNumeric)"
					if [ "$testOne" != "" ] && [ "$testTwo" != "" ] && [ "$lineNumber" != "" ]; then
						if [ "$lineNumber" -ge "$testOne" ] && [ "$lineNumber" -le "$testTwo" ]; then
							printf "%s\t%s\n" "$line" "$aFile"
						fi
					fi
				done
			done


files="${files}
${aFile}"

		fi
	done
}
thepwd="$PWD"

ranges=""
IFS='
'
for range in $(getRangesWithDuplicates "$1" "$4"); do

	found=0
	for existingRange in $ranges; do

		if [ "$range" = "$existingRange" ]; then
			found=1
			break
		fi 
	done
	if [ "$found" = 0 ]; then

		javaFile="$(printf "%s" "$range" | rev | cut -f 1 | rev)"

		if [ -f "${javaFile}" ]; then
			methodsFromDecompiledSources="$("$4/getMethodsFromSources" "${3}")"
			for decompiledRange in $methodsFromDecompiledSources; do
				found=0

				for decompiledExistingRange in $decompiledRanges; do
					if [ "$decompiledRange" = "$decompiledExistingRange" ]; then
						found=1
						break
					fi 
				done

				if [ "$found" = 0 ]; then
#echo "$(printf "%s" "$range" | rev | cut -f 3- | rev)"
#echo "$(printf "%s" "$decompiledRange" | rev | cut -f 2- | rev)"
#checkMatchFunction "$(printf "%s" "$range" | rev | cut -f 3- | rev)" "$(printf "%s" "$decompiledRange" | rev | cut -f 2- | rev)"
IFS='
'
					if [ "$(checkMatchFunction "$(printf "%s" "$range" | rev | cut -f 3- | rev)" "$(printf "%s" "$decompiledRange" | rev | cut -f 2- | rev)" )" = "" ]; then
						if ! [ -f "buildlog/$(echo "${javaFile}" | cut -d '/' -f 3-5)/hybrids/$(basename ${javaFile%.java}).success" ]; then 
							replaceCompiled="$(printf "%s" "$range" | rev | cut -f 2 | rev)"

							withDecompiled="$(printf "%s" "$decompiledRange" | rev | cut -f 1 | rev)"
							reg="$(expr "$(printf "%s" "$withDecompiled" | cut -d "," -f 2)" - "$(printf "%s" "$withDecompiled" | cut -d "," -f 1)")"
							rA="$(printf "%s" "$replaceCompiled" | cut -d "," -f 1)"
							rB="$(expr ${rA} + $reg)"
							rC="$(printf "%s" "$replaceCompiled" | cut -d "," -f 2)"
							#printf "%s,%sc%s,%s\n" "$rA" "$rC" "$rA" "$rB"
							toGoThrough="$(sed -n "${rA},${rC}p" "${javaFile}")"

							rA="$(expr $rA - 1)"
							outpath="$(echo hybrids/$(echo "${javaFile}" | cut -d '/' -f 3-5))"
							outpath="${outpath}/$(basename ${javaFile})"

							head -n $rA "${javaFile}" > "${outpath}"

							tailend="$(cat "${javaFile}" | wc -l)"

							regB="$(expr $rA + $reg)"
							regB="$(expr $regB + 2)"

							tailend="$(expr $tailend - $regB)"

							rA="$(printf "%s" "$withDecompiled" | cut -d "," -f 1)"
							rB="$(expr $rA + $reg)"
							rB="$(expr $rB + 1)"
	
							toGoThrough="$(cat ${3} | sed -n "${rA},${rB}p")"
							echo "$toGoThrough" >> "${outpath}"
							tail -n $tailend "${javaFile}" >> "${outpath}"
							#echo $toGoThrough
						fi




					fi
				fi
			done
		fi

ranges="${range}
${ranges}"

	fi
done

umask "${OLD_UMASK}"
