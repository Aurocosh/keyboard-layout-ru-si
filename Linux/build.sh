#!/bin/bash
set -e

VERSION=2.0.0-1
PACKAGE_DIR="kl-ru-si-$VERSION"

chmod 755 $PACKAGE_DIR/DEBIAN/{postinst,prerm}
chmod 644 $PACKAGE_DIR/DEBIAN/control
dpkg-deb --build $PACKAGE_DIR
