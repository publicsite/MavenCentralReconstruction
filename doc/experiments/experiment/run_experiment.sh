#!/bin/sh
echo "Demo/Experiment to see if decompiled sources has private method names..."
echo
javac HelloWorld.java
procyon HelloWorld.class
echo ""
echo "... As you can see, the correct method name is printed."