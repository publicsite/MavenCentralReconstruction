#!/bin/sh
#A program to produce a patch, updating broken methods in Java sources, given a working source file and a non-working source file, and a javac error log
#arg1 javac stderr log file
#arg2 java source file (non-working)
#arg3 java binary source file (working; this can be decompiled from a .class file)

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
if [ "$declarationA" != "$declarationB" ]; then
printf "BBB: %s< %s<<\n" "$testA" "$testB"
return
fi
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
					if [ "$testOne" != "" ] && [ "$testTwo" != "" ]; then
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

		if [ -f "${3}/${javaFile}" ]; then

			methodsFromDecompiledSources="$("$4/getMethodsFromSources" "${3}/${javaFile}")"
			for decompiledRange in $methodsFromDecompiledSources; do
				found=0

				for decompiledExistingRange in $decompiledRanges; do
					if [ "$decompiledRange" = "$decompiledExistingRange" ]; then
						found=1
						break
					fi 
				done

				if [ "$found" = 0 ]; then
IFS='
'
					if [ "$(checkMatchFunction "$(printf "%s" "$range" | rev | cut -f 3- | rev)" "$(printf "%s" "$decompiledRange" | rev | cut -f 2- | rev)")" = "" ]; then
						printf "%s %s.old\n" '---' "${javaFile}"
						printf "%s %s\n" '+++' "${javaFile}"

						replaceCompiled="$(printf "%s" "$range" | rev | cut -f 2 | rev)"
						withDecompiled="$(printf "%s" "$decompiledRange" | rev | cut -f 1 | rev)"
						reg="$(expr "$(printf "%s" "$withDecompiled" | cut -d "," -f 2)" - "$(printf "%s" "$withDecompiled" | cut -d "," -f 1)")"
						rA="$(printf "%s" "$replaceCompiled" | cut -d "," -f 1)"
						rB="$(expr ${rA} + $reg)"
						rC="$(printf "%s" "$replaceCompiled" | cut -d "," -f 2)"
						printf "%s,%sc%s,%s\n" "$rA" "$rC" "$rA" "$rB"
						toGoThrough="$(sed -n "${rA},${rC}p" "${2}/${javaFile}")"
						printf "%s\n" "$toGoThrough" | while read patchLine; do
							printf "< %s\n" "$patchLine"
						done
						printf "%s\n" "---"
						rA="$(printf "%s" "$withDecompiled" | cut -d "," -f 1)"
						rB="$(expr $rA + $reg)"


						toGoThrough="$(sed -n "${rA},${rB}p" "${3}/${javaFile}")"
						printf "%s\n" "$toGoThrough" | while read patchLine; do
							printf "> %s\n" "$patchLine"
						done
					fi
				fi
			done
		fi

ranges="${range}
${ranges}"

	fi
done