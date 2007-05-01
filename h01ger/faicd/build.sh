#!/bin/sh
#
# (c) 2006 Holger Levsen <debian@layer-acht.org>
# Licended under GPL2
#
#
# build script for faicd
#
##############################################################################

#
# only build in ~/faicd
#
cd
BUILD_DIR="faicd"
if [ ! -d $BUILD_DIR ] ; then
	echo "`pwd`$BUILD_DIR doesn't exist, aborting."
	echo
	echo "cd && svn co svn://svn.debian.org/svn/fai/people/h01ger/faicd ./faicd"
	exit 1
fi

PUBLISH_DIR="/www/webserver/faicd.debian.net/htdocs/"
LOCKFILE="/var/lock/failive-build"
LOGFILE=`mktemp`
TODAY="`date +%Y%m%d%H%M`"

#
# check lockfile
#
if [ -f "$LOCKFILE" ] ; then
	echo $LOCKFILE exists, aborting
	exit 1
fi
touch $LOCKFILE

#
# cleanup & prepare
#
cd $BUILD_DIR 
sudo rm debian-live -rf > /dev/null
[ $? ] || echo "problems removing old build"
# display diffs from current local version to version in repository
svn diff --revision HEAD
# update to version in repository
svn up

#
# build
#
nice sudo /usr/bin/make-live --hook live-include-dir/hook --config make-live.conf > $LOGFILE 2>&1

#
# publish
# 
if [ -f debian-live/binary.iso ] ; then
  cp debian-live/binary.iso $PUBLISH_DIR/faicd-${TODAY}.iso
  md5sum $PUBLISH_DIR/faicd-${TODAY}.iso > $PUBLISH_DIR/faicd-${TODAY}.md5sum
  echo
  echo successfully build live-cd, download at http://faicd.debian.net/faicd-${TODAY}.iso
  echo
else 
  echo "#########################################################"
  echo 
  echo "An error occured, .iso was not created :-("
  echo 
  echo "30 last lines of the make-live output:"
  echo
  tail -30 $LOGFILE
fi 
cp $LOGFILE $PUBLISH_DIR/faicd-${TODAY}.log
chmod 644 $PUBLISH_DIR/faicd-${TODAY}.log
rm $LOGFILE

#
# cleanup lockfile
#
rm $LOCKFILE

#
# cleanup old images and logs
#
cd $PUBLISH_DIR
#find . -mtime +1 -name "faicd-*.???" !  -name "fai*-*00.???" -exec rm -f {} \;
#find . -mtime +2 -name "faicd-*.???" !  -name "fai*-1600.???" -exec rm -f {} \;
find . -mtime +14 -name "faicd-*.???" -exec rm -f {} \;

#
# re-create warning README
#
cat > $PUBLISH_DIR/README.html << 'EOF'
<html>
<head></head>
<body>
<p><b>WARNING:</p><p></b>Booting this FAI live-cd will ERASE YOUR HARDDISK!!</p>
</body>
</html>
EOF

