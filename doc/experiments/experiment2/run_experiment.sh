#!/bin/sh
echo "Write javac log of a broken class, containing a broken method"
javac -g HelloWorld.java 2>outLog.txt
