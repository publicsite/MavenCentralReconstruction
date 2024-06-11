#!/bin/sh

#returns licence identifier if license is osi or fsf approved
#returns empty string is license is not approved


if [ "$1" = "PublicDomain" ]; then
	echo "PublicDomain"
elif [ "$1" = "Apache License, version 2.0" ]; then
	echo "Apache License, version 2.0"
elif [ "$1" = "Apache License, version 1.0" ]; then
	echo "Apache License, version 1.0"
elif [ "$1" = "Apache License, Version 2.0" ]; then
	echo "Apache License, Version 2.0"
elif [ "$1" = "Apache License, Version 1.0" ]; then
	echo "Apache License, Version 2.0"
elif [ "$1" = "Apache 2.0 License" ]; then
	echo "Apache 2.0 License"
elif [ "$1" = "Apache 1.0 License" ]; then
	echo "Apache 1.0 License"
elif [ "$1" = "The Apache License, Version 2.0" ]; then
	echo "The Apache License, Version 2.0"
elif [ "$1" = "The Apache License, Version 1.0" ]; then
	echo "The Apache License, Version 1.0"
elif [ "$1" = "The Apache Software License, Version 2.0" ]; then
	echo "The Apache Software License, Version 2.0"
elif [ "$1" = "The Apache Software License, Version 1.0" ]; then
	echo "The Apache Software License, Version 1.0"
elif [ "$1" = "Eclipse Public License v2.0" ]; then
	echo "Eclipse Public License v2.0"
elif [ "$1" = "Eclipse Public License v1.0" ]; then
	echo "Eclipse Public License v1.0"
elif [ "$1" = "Eclipse Public License 1.0" ]; then
	echo "Eclipse Public License 1.0"
elif [ "$1" = "Eclipse Public License 2.0" ]; then
	echo "Eclipse Public License 1.0"
elif [ "$1" = "Common Public License Version 1.0" ]; then
	echo "Common Public License Version 1.0"
elif [ "$1" = "Common Public License - v 1.0" ]; then
	echo "Common Public License - v 1.0"
elif [ "$1" = "LGPL-2.1-or-later" ]; then
	echo "LGPL-2.1-or-later"
elif [ "$1" = "GNU Lesser Public License" ]; then
	echo "GNU Lesser Public License"
elif [ "$1" = "BSD License 3" ]; then
	echo "BSD License 3"
else
	#see if licence name matchess
	firsttry="$(cat licenses.json | jq '. | {licenses}[] | .[] | select((.isFsfLibre==true) or (.isOsiApproved==true)) | .name' | tr -d '"' | grep "^${1}$")"
	if [ "$firsttry" = "" ]; then
		#see if licence id matches
		cat licenses.json | jq '. | {licenses}[] | .[] | select((.isFsfLibre==true) or (.isOsiApproved==true)) | .licenseId' | tr -d '"' | grep "^${1}$"
	else
		echo "$firsttry"
	fi
fi