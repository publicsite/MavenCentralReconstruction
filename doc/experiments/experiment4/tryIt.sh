#!/bin/sh
busybox sh ../getMethodsFromLog.sh outLog.txt HelloWorld.java HelloWorld2.java > try.patch
cp HelloWorld.java HelloWorld.java.bak
patch HelloWorld.java < try.patch
