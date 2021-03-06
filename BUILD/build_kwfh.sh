#!/bin/bash

# Set current directory to script directory.
Dir=$(cd "$(dirname "$0")" && pwd)
cd $Dir

# Init vars
VERSION=""

function finalCleanUp(){
    if [ -d "$Dir/tmp" ]; then
        echo "Cleaning temporary dirs"
        rm -rf $Dir/tmp
    fi
}

# Create folder where we move our created deb packages
if [ ! -d "$Dir/debs" ]; then 
mkdir $Dir/debs
fi

# Get kwaterfoxhelper version
if [ ! -d "$Dir/tmp/version/latest_version.txt" ]; then 
    mkdir -p $Dir/tmp/version
    wget -O $Dir/tmp/version/latest_version.txt https://github.com/hawkeye116477/kwaterfoxhelper/raw/master/latest_version.txt
fi

if [ -f "$Dir/tmp/version/latest_version.txt" ]; then
    VERSION=$(<$Dir/tmp/version/latest_version.txt)
else
    echo "Unable to get current helper version!"
    exit 1    
fi

# Generate template directories
if [ ! -d "$Dir/tmp/kwaterfoxhelper-$VERSION" ]; then 
    mkdir -p $Dir/tmp/kwaterfoxhelper-$VERSION
fi

# Copy deb templates
if [ -d "$Dir/kwaterfoxhelper/debian" ]; then
	cp -r $Dir/kwaterfoxhelper/debian/ $Dir/tmp/kwaterfoxhelper-$VERSION/
else
    echo "Unable to locate deb templates!"
    exit 1 
fi

# Download latest kwaterfoxhelper
cd $Dir/tmp
wget https://github.com/hawkeye116477/kwaterfoxhelper/archive/v5.0.1.6.tar.gz
tar zxvf v$VERSION.tar.gz

# Generate change log template
CHANGELOGDIR=$Dir/tmp/kwaterfoxhelper-$VERSION/debian/changelog
if grep -q -E "__VERSION__|__CHANGELOG__|__TIMESTAMP__" "$CHANGELOGDIR" ; then
    sed -i "s|__VERSION__|$VERSION|" "$CHANGELOGDIR"
    DATE=$(date --rfc-2822)
    sed -i "s|__TIMESTAMP__|$DATE|" "$CHANGELOGDIR"

else
    echo "An error occured when trying to generate $CHANGELOGDIR information!"
    exit 1  
fi

# Make sure correct permissions are set
chmod 755 $Dir/tmp/kwaterfoxhelper-$VERSION/debian/rules

# Build .deb package
notify-send "Building deb packages!"
cd $Dir/tmp/kwaterfoxhelper-$VERSION
debuild -us -uc

if [ -f $Dir/tmp/kwaterfoxhelper_*_amd64.deb ]; then
    mv $Dir/tmp/*.deb $Dir/debs
else
    echo "Unable to move deb packages the file maybe missing or had errors during creation!"
   exit 1
fi


notify-send "Deb package for APT repository complete!"
finalCleanUp
