#!/bin/sh

usage(){
	printf "./getSources.sh <groupId> <artifactId> <version>\n\nTry and recursively download ALL source dependencies, and their dependencies ... for a package on Maven Central.\n\n"
	printf "getSources.sh requires git and subversion \n\nIf it can't find a git or subversion repository for a package, it will download the sources.jar, which is unfortunately usually incomplete\n\n"
	printf "The idea of this program is to try and rescue, (yes ... rescue) some software [but in practice] probably that's easier said than done.\n\n"
}

if [ "$#" != 3 ]; then
usage
exit
fi

if [ -f "sources/catalogue.txt" ]; then
rm "sources/catalogue.txt"
fi

touch "sources/catalogue.txt"

./sourceGetter6.sh "$1" "$2" "$3"