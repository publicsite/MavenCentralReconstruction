#!/bin/sh
echo "===SUMMARY==="
echo

a=$(find buildlog -mindepth 4 -maxdepth 4 -type d -name fromSource -exec find {} -name "*.failed" \; | wc -l)
b=$(find buildlog -mindepth 4 -maxdepth 4 -type d -name fromSource -exec find {} -name "*.success" \; | wc -l)
echo "$a failed to be built from sources."
echo "$b succeded to be built from sources."
if [ "$a" = "0" ]; then
	c=0
else
	c="$(echo "scale=2; ($b / ($a + $b)) * 100" | bc -l)"
fi
echo "($c percent)"
echo

g=$(find buildlog -mindepth 4 -maxdepth 4 -type d -name hybrids -exec find {} -name "*.failed" \; | wc -l)
d=$(find buildlog -mindepth 4 -maxdepth 4 -type d -name hybrids -exec find {} -name "*.success" \; | wc -l)
echo "$a failed hybrids."
echo "$d successful hybrids."
if [ "$g" = "0" ]; then
	c=0
else
	c="$(echo "scale=2; ($d / ($g + $d)) * 100" | bc -l)"
fi
echo "($c percent)"
echo

g="$(find buildlog -mindepth 4 -maxdepth 4 -type d -name decompiledOnly -exec find {} -name "*.failed" \; | wc -l)"
e="$(find buildlog -mindepth 4 -maxdepth 4 -type d -name decompiledOnly -exec find {} -name "*.success" \; | wc -l)"
echo "$g failed decompiled reproductions."
echo "$e successful decompiled reproductions."
if [ "$g" = "0" ]; then
	c=0
else
	c="$(echo "scale=2; ($e / ($g + $e)) * 100" | bc -l)"
fi
echo "($c percent)"
echo

#f="$(echo "scale=2; $b + $d + $e" | bc -l)"
#h="$(echo "scale=2; ($(find sources/structure/ -maxdepth 4 -mindepth 4 -type d -exec find {} -name "*.java" -type f \; | wc -l) - $a) - $g" | bc -l)"
#echo "$f combined successful decompiled reproductions"
#echo "out of $h total reproductions"
#i="$(echo "scale=2; ( $f / $h ) * 100" | bc -l)"
#echo "($i percent)"