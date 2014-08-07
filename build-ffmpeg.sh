#!/bin/sh
#
#   this script has been optimized to decrease the size by compiling the necessary formats only
#		video codecs: h264 (enable h263)
#		audio codecs: AAC (enable mp3)
# 		
# 	to download the latest ffmpeg project use: git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg

# directories
SOURCE="ffmpeg"
FAT="universal"
VERSION="2.2"

ARGS=`echo "$@" | sed "s@minimal@@"`
ARCHS="arm64 armv7s armv7 x86_64 i386"
COMPILE="y"
LIPO="y" 

if [[ $# == 0 || $ARGS =~ .*-h|--help* ]]; then
  echo "\
Usage: `basename $0` [minimal|entire] [arm64|armv7s|armv7|x86_64|i386] [lipo] \n\
   common:\n\
       `basename $0` minimal - build optimized libraries with all necessary stuff and h264 codec \n\
       `basename $0` minimal arm64 armv7s armv7 - build minimal configuration for device architectures only \n\
   miscellaneous: \n\
       `basename $0` universal - build configuration with all codecs \n\
       `basename $0` lipo - join created libraries only for architectures into one fat library"
  exit 0
fi

if [ "$ARGS" ]
then	
	if [[ "$@" =~ .*lipo* ]]
	then
		ARGS=`echo $ARGS | sed "s@lipo@@"`
		echo "skip compile"	
		# skip compile
		COMPILE=
	fi
	if [[ $ARCHS =~ .$`echo $ARGS`$ ]]
	then
		# skip lipo
		LIPO=
	fi
	ARCHS=$ARGS
fi
echo $ARCHS

DEPLOYMENT_TARGET="6.0"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

# absolute path to x264 library
#X264=`pwd`/fat_x264

DEVELOPER=`xcode-select -print-path`

# universal library
CONFIGURE_FLAGS="--enable-cross-compile --disable-debug --disable-programs \
                 --disable-doc --enable-pic"

# optimized library
if [[ "$@" =~ .*minimal* ]]
then
CONFIGURE_FLAGS="--enable-cross-compile \
	--disable-everything \
	--disable-logging \
	--disable-network \
	--disable-encoders  \
	--disable-decoders \
	--disable-muxers \
	--disable-demuxers \
	--disable-protocols \
	--disable-devices \
	--disable-ffmpeg \
	--disable-ffplay \
	--disable-ffprobe \
	--disable-ffserver \
	--disable-avdevice \
	--disable-avfilter \
	--disable-iconv \
	--disable-bzlib \
	--disable-mmx \
	--disable-mmxext \
	--disable-amd3dnow \
	--disable-amd3dnowext \
	--disable-sse \
	--disable-sse2 \
	--disable-sse3 \
	--disable-sse4 \
	--disable-avx \
	--disable-fma4 \
	--disable-swresample \
	--disable-postproc \
	--disable-bsfs \
	--disable-filters \
	--disable-asm \
	--disable-yasm \
	--disable-debug \
	--disable-doc \
	--disable-armv5te \
	--disable-armv6 \
	--disable-armv6t2 \
	--enable-protocol=file \
	--enable-avformat \
	--enable-avcodec \
	--enable-swscale \
	--enable-demuxer=aac \
	--enable-demuxer=mov \
	--enable-demuxer=h264 \
	--enable-decoder=aac \
	--enable-decoder=h264 \
	--enable-decoder=mpeg4 \
	--enable-encoder=aac \
	--enable-encoder=mpeg4 \
	--enable-parser=aac \
	--enable-parser=h264 \
	--enable-pic"
	echo 'minimalistic library configured'	
fi

if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

if [ "$COMPILE" ]
then
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
			ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl --progress-bar -3L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $SOURCE-$VERSION ]
	then
		echo 'FFmpeg source not found. Trying to download...'
		curl --progress-bar http://www.ffmpeg.org/releases/$SOURCE-$VERSION.tar.bz2 | tar xj \
			|| exit 1
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
		FF_ARCH="arm"
		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
		else
		    PLATFORM="iPhoneOS"
		    CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET"
		    if [ "$ARCH" = "arm64" ]
		    then
			    FF_ARCH="aarch64"
		        EXPORT="GASPP_FIX_XCODE5=1"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="$DEVELOPER/usr/bin/xcrun -sdk $XCRUN_SDK clang"
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
		if [ "$X264" ]
		then
			CFLAGS="$CFLAGS -I$X264/include"
			LDFLAGS="$LDFLAGS -L$X264/lib"
		fi
		
		$CWD/$SOURCE-$VERSION/configure \
		    --target-os=darwin \
		    --arch=$FF_ARCH \
		    --cc="$CC" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-cxxflags="$CXXFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" \
		|| exit 1

		make install -j3 --silent $EXPORT || exit 1
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	for ARCH in $ARCHS
	do
		echo "creating universal binaries..."
		mkdir -p $FAT/lib
		set - $ARCHS
		CWD=`pwd`
	
		cd $THIN/$ARCH/lib
		for LIB in *.a
		do
			cd $CWD
			lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
		done

		cd $CWD
		cp -rf $THIN/$ARCH/include $FAT
	done
fi

rm -rf $SCRATCH
echo "universal binaries can be found in '$FAT' folder"
echo 'library size: ' + `du -sh $FAT`
echo 'Build done, enjoy your custom FFMPEG library'
open $FAT