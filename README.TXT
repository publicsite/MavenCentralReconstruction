This directory and the files within, are copyright:

Copyright (C) J05HYYY

The licence is: GPL v3

See LICENCE.TXT for details.

__________________

To get dependencies ...

sudo apt-get install git default-jdk procyon-decompiler java-wrappers pexec
__________________

To use ...

#cd to the directory containing the tree


#to download the sources
./callGetSources.sh <groupId> <artifactId> <version>

	#this will create the sources/structure heiracy and download sources recursively. it will also download bin jars and automatically decompile them.


#to build classes
./compile3.sh

	#this will compile the sources, if that fails it will compile a hybrid of the sources and it's decompiled version, if that fails, it will compile the decompiled version.

	#build logs are placed in buildlogs dir
	#classes are placed in the classes dir
	#hybrids are made in the hybrids dir

#to package cleansed source jars
./packageSourceJars4.sh

	#this will package the cleansed source jars in the outCleansedJars/jars dir

#to package cleansed bin jars
./packageBinJars4.sh

	#this will package the cleaned bin jars in the outCleansedJars/jars dir
___________________

MavenCentralReconstruction now has very limited support for build.gradle

If you don't want to use callGetSources.sh , you can always create the tree, and put the sources in

root_of_MavenCentralReconstruction/sources/structure/<groupId>/<artifactId>/<version>/extractedSources
___________________

To donate:

https://www.paypal.com/donate/?hosted_button_id=SZABYRV48SAXW
