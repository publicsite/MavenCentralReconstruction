#!/bin/sh
echo "Experiment to show method without public or static prefixed."
echo "Compiling method without public or static prefix ..."
javac -g HelloWorld.java
echo "As you can see, it compiles fine."
echo
echo "Experiment to show class without public or static prefixed."
echo echo "Compiling class without public or static prefix ..."
javac -g HelloWorld1.java
echo "As you can see, it also compiles fine."
echo
echo "Experiment to show method without static prefix."
javac -g HelloWorld2.java
echo "As you can see, if calling method is not static, this fails."
echo
echo "Experiment to show class without static prefix."
javac -g HelloWorld3.java
echo "As you can see, this succeeds."
echo "Experiment to show class and method without static prefix."
javac -g HelloWorld4.java
echo "As you can see, this also succeeds."
echo "Experiment to show method without brackets."
javac -g HelloWorld5.java
echo "As you can see, this fails."
echo "Experiment to show single line; with a method declaration; without a newline seperator."
javac -g HelloWorld6.java
echo "As you can see, this fails."
echo "Experiment to show single line; with a class declaration; without a newline seperator."
javac -g HelloWorld7.java
echo "As you can see, this fails."
echo "Experiment to see if a asterix is required on the lines in-between multi-line comments."
javac -g HelloWorld8.java
echo "As you can see, this compiles."
java HelloWorld
echo "And doesn't print the lines in-between."
echo "Experiment to see multi line comment on a single line."
javac -g HelloWorld9.java
echo "As you can see, this is fine."
echo "Experiment to see multi line comment on a single line, preceeding line's code."
javac -g HelloWorld10.java
echo "As you can see, this is fine."