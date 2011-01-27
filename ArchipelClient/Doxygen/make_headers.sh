#!/bin/sh
#
# NOTE: The working directory should be the main capp directory when this script is run

if [ -d /tmp/tempDoc.doc ]; then
    rm -rf /tmp/tempDoc.doc
fi

echo "Copying source files..."
cp -r . /tmp/tempDoc.doc
cp -r ../README.markdown /tmp/tempDoc.doc/
cp -r ../LICENSE /tmp/tempDoc.doc/
rm -rf /tmp/tempDoc.doc/.git
rm -rf /tmp/tempDoc.doc/Build
rm -rf /tmp/tempDoc.doc/Libraries

echo "Processing source files..."
find /tmp/tempDoc.doc -name "*.j" -exec sed -e '/@import.*/ d' -i '' {} \;

exec Doxygen/make_headers
