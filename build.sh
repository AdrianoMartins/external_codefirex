#!/bin/bash

# What we're building with
[ -z "$BINUTILS" ] && BINUTILS=2.23
[ -z "$CLOOG" ] && CLOOG=0.18.0
[ -z "$PPL" ] && PPL=1.0
[ -z "$GCC" ] && GCC=4.9
[ -z "$GDB" ] && GDB=linaro-7.6-2013.05
[ -z "$GMP" ] && GMP=5.1.2
[ -z "$MPFR" ] && MPFR=3.1.2
[ -z "$MPC" ] && MPC=1.0.1

# Installation location
# Note: we're only building arm-linux-androideabi currently
#
# TODO: support more triplets
DEST=$ANDROID_BUILD_TOP/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-$TARGET_GCC_VERSION

# Parallel build flag passed to make
[ -z "$SMP" ] && SMP="-j`getconf _NPROCESSORS_ONLN`"

cpu_variant="$TARGET_CPU_VARIANT"
krait_variant=krait

# Set locales to avoid python warnings
# or errors depending on configuration
export LC_ALL=C

# Set our local paths
DIR="$ANDROID_BUILD_TOP/external/codefirex"
SRC="$DIR/src"

# Apply our squashed AOSP ports patch on gcc trunk
cd $SRC/gcc/gcc-$GCC
patch -p1 < "$DIR/gcc-4.9-android.patch"
cd $DIR

mkdir -p $OUT/toolchain_build
cd $OUT/toolchain_build

# Configure the build for arm-linux-androideabi
# with all additional arguments.
# Also set --with-tune for TARGET_CPU_VARIANT
if [ "$cpu_variant" = "$krait" ]; then
    $SRC/build/configure \
            --prefix="$DEST" \
            --with-mpc-version="$MPC" \
            --with-gdb-version="$GDB" \
            --with-cloog-version="$CLOOG" \
            --with-ppl-version="$PPL" \
            --with-mpfr-version="$MPFR" \
            --with-gmp-version="$GMP" \
            --with-binutils-version="$BINUTILS" \
            --with-gold-version="$BINUTILS" \
            --with-gcc-version="$GCC" \
            --with-sysroot=/ \
            --with-tune=cortex-a9 \
            --target=arm-linux-androideabi \
            --enable-graphite=yes \
            --enable-gold=yes \
            --enable-plugins \
            --disable-libsanitizer
else
    $SRC/build/configure \
            --prefix="$DEST" \
            --with-mpc-version="$MPC" \
            --with-gdb-version="$GDB" \
            --with-cloog-version="$CLOOG" \
            --with-ppl-version="$PPL" \
            --with-mpfr-version="$MPFR" \
            --with-gmp-version="$GMP" \
            --with-binutils-version="$BINUTILS" \
            --with-gold-version="$BINUTILS" \
            --with-gcc-version="$GCC" \
            --with-sysroot=/ \
            --with-tune="$TARGET_CPU_VARIANT" \
            --target=arm-linux-androideabi \
            --enable-graphite=yes \
            --enable-gold=yes \
            --enable-plugins \
            --disable-libsanitizer
fi

# We must use our $PATH from before the addition of
# Android paths in setpaths(). First backup the new
# $PATH with Android path additions.
export NEWPATH=$PATH

# Set our backed up $PATH as $PATH as well as adding
# $DEST
export PATH=$OLDPATH$DEST

# Make and install the toolchain to the proper path
make $SMP
make install

#We need to copy the necessary makefiles for the
# Android build system now.
cp $DIR/Makefiles/Android.mk $DEST/Android.mk
cp $DIR/Makefiles/toolchain.mk $DEST/toolchain.mk
cp $DIR/Makefiles/lib32-Android.mk $DEST/lib32/Android.mk

echo ""
echo "=========================================================="
echo "Toolchain build successful."
echo "The toolchain can be found in $DEST."
echo "Now building Android with cfX-Toolchain."
echo "=========================================================="
echo ""
echo "=========================================================="
echo "The toolchain was built with the following:"
echo "=========================================================="
echo "Binutils=\"$BINUTILS\""
echo "Cloog=\"$CLOOG\""
echo "PPL=\"$PPL\""
echo "GCC=\"$GCC\""
echo "GDB=\"$GDB\""
echo "GMP=\"$GMP\""
echo "MPFR=\"$MPFR\""
echo "MPC=\"$MPC\""
echo "=========================================================="
echo ""
echo "=========================================================="
echo "A few notes:"
echo "=========================================================="
echo "1) If you do not want to build the toolchain inline in the"
echo "future, run \"choosecombo\" instead of lunch."
echo "Select \"release\" from the build type menu instead of"
echo "\"development\""
echo ""
echo "2) We use $OUT for toolchain building due to some"
echo "build configurations using multiple drives or partitions."
echo ""
echo "3) We have the entire toolchain_build folder in a"
echo "cleanspec, so there's no need to delete it ourselves."
echo "This means if you do not make clean, no new toolchain is"
echo "built (or fully built)."
echo ""
echo "4) The toolchain build uses your *HOST* sysroot."
echo "If you don't know what this means don't worry."
echo "If you do know what this means, we did it this way"
echo "to rid your build system of unnecessary symlinks"
echo "=========================================================="

# HACK: reset gcc back to it's unpatched state
cd $SRC/gcc/gcc-$GCC
git add .
git reset --hard --quiet

# Restore Android Build System set $PATH
export PATH=$NEWPATH

# Go back to android build top to continue the build
cd $ANDROID_BUILD_TOP

exit 0
