#!/bin/sh
oldAmountOfErrors="999999"

patchNumber="0"

while true; do
javac "$1" 2>classErrors.log
numberOfErrors="$(tail -n 1 classErrors.log | cut -d " " -f 1)"

if [ "${numberOfErrors}" = "" ]; then
	printf "\nAll errors fixed in %s\n" "$1"
	break
elif [ ${numberOfErrors} -ge ${oldAmountOfErrors} ]; then
	printf "The last patch didn't help, so no more patches can be generated for %s\n" "$1"
	break
else
	printf "\nFound %s remaining error(s) in %s\n" "$numberOfErrors" "<nameOfClass>"
fi
patchNumber="$(expr $patchNumber + 1)"
printf "Attempting to generate patch\n"
./getMethodsFromLog2.sh "classErrors.log" "$2" "$3" >$(basename "$1")_${patchNumber}.patch
patch -p0 < $(basename "$1")_${patchNumber}.patch

oldAmountOfErrors="${numberOfErrors}"

done

rm classErrors.log