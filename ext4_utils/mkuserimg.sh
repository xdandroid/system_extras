#!/bin/bash
#
# To call this script, make sure make_ext4fs is somewhere in PATH

PATH="out/host/${HOST_OS}-${HOST_ARCH}/bin:${PATH}:/sbin:/usr/sbin"

function usage() {
cat<<EOT
Usage:
mkuserimg.sh SRC_DIR OUTPUT_FILE EXT_VARIANT MOUNT_POINT SIZE
EOT
}

echo "in mkuserimg.sh PATH=$PATH"

if [ $# -ne 4 -a $# -ne 5 ]; then
  usage
  exit 1
fi

SRC_DIR=$1
if [ ! -d $SRC_DIR ]; then
  echo "Can not find directory $SRC_DIR!"
  exit 2
fi

OUTPUT_FILE=$2
EXT_VARIANT=$3
MOUNT_POINT=$4
SIZE=$5

case $EXT_VARIANT in
  ext2)
    num_blocks=`du -sk $SRC_DIR | tail -n1 | awk '{print $1;}'`

    if [ $num_blocks -lt 20480 ]
    then
        extra_blocks=3072
    else
        extra_blocks=20480
    fi

    num_blocks=`expr $num_blocks + $extra_blocks`
    num_inodes=`find $SRC_DIR | wc -l` ; num_inodes=`expr $num_inodes + 500`

    echo genext2fs -a -d $SRC_DIR -b $num_blocks -N $num_inodes -m 0 $OUTPUT_FILE
    genext2fs -a -d $SRC_DIR -b $num_blocks -N $num_inodes -m 0 $OUTPUT_FILE
    echo tune2fs -L $MOUNT_POINT $OUTPUT_FILE
    tune2fs -L $MOUNT_POINT $OUTPUT_FILE
    echo tune2fs -C 1 $OUTPUT_FILE
    tune2fs -C 1 $OUTPUT_FILE
    echo e2fsck -fy $OUTPUT_FILE
    e2fsck -fy $OUTPUT_FILE
    if [ $? -gt 1 ] ; then
        exit 4
    fi
    ;;
  ext4)
    if [ -z $MOUNT_POINT ]; then
      echo "Mount point is required"
      exit 2
    fi

    if [ -z $SIZE ]; then
        SIZE=128M
    fi

    echo "make_ext4fs -l $SIZE -a $MOUNT_POINT $OUTPUT_FILE $SRC_DIR"
    make_ext4fs -s -l $SIZE -a $MOUNT_POINT $OUTPUT_FILE $SRC_DIR
    if [ $? -ne 0 ]; then
      exit 4
    fi
    ;;
  *) echo "Only ext4 is supported!"; exit 3 ;;
esac
