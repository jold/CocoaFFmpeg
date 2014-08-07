#!/bin/sh
#
# this script has been optimized to decrease the size by compiling only the necessary formats
#		video codecs: h263 and h264 
#		audio codecs: mp4 and AAC
#
# author: 	Daniel Jankovic
# web: 		www.digital-life.cz
# 			
#	check out our iOS / OS-X RTMP library to broadcast live video, playback or make a videochat application  
#	http://www.digital-life.cz/members-area_en   
#
# usage: 
#		build all architectures and create one universal fat file: 		./build-ffmpeg.sh
# 		build specific architecture only: 								./build-ffmpeg.sh armv7
# 		join lib files of all platforms into the universal fat file:	./build-ffmpeg.sh lipo
# 		
# 	for more information visit: https://github.com/kewlbear/FFmpeg-iOS-build-script
# 	this is optimized source: https://github.com/kewlbear/FFmpeg-iOS-build-script/blob/master/build-ffmpeg.sh
# 	to download the latest ffmpeg project use: git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg

# directories
SOURCE="ffmpeg"
FAT="universal"
VERSION="2.2"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

# absolute path to x264 library
#X264=`pwd`/fat_x264

# absolute path to SPEEX library
SPEEX=`pwd`/speex

CONFIGURE_FLAGS="--enable-cross-compile \
	--disable-everything \
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
	--enable-demuxer=mp3 \
	--enable-demuxer=aac \
	--enable-demuxer=mov \
	--enable-demuxer=h263 \
	--enable-demuxer=h264 \
	--enable-decoder=mp3 \
	--enable-decoder=aac \
	--enable-decoder=h263 \
	--enable-decoder=h264 \
	--enable-decoder=mpeg4 \
	--enable-encoder=aac \
	--enable-encoder=h263 \
	--enable-encoder=mpeg4 \
	--enable-parser=aac \
	--enable-parser=h264 \
	--enable-pic"

if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264"
fi

if [ "$SPEEX" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libspeex"
fi


# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

ARCHS="arm64 armv7s armv7 x86_64 i386"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="6.0"

if [ "$*" ]
then
	if [ "$*" = "lipo" ]
	then
		# skip compile
		COMPILE=
	else
		ARCHS="$*"
		if [ $# -eq 1 ]
		then
			# skip lipo
			LIPO=
		fi
	fi
fi

if [ "$COMPILE" ]
then
	CWD=`pwd`
	for ARCH in $ARCHS
	do
		echo "building $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
		else
		    PLATFORM="iPhoneOS"
		    CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET"
		    if [ "$ARCH" = "arm64" ]
		    then
		        EXPORT="GASPP_FIX_XCODE5=1"
		    fi
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
		if [ "$X264" ]
		then
			CFLAGS="$CFLAGS -I$X264/include"
			LDFLAGS="$LDFLAGS -L$X264/lib"
		fi
		if [ "$SPEEX" ]
		then
			CFLAGS="$CFLAGS -I$SPEEX/include"
			LDFLAGS="$LDFLAGS -L$SPEEX/lib"
		fi

		$CWD/$SOURCE/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-cxxflags="$CXXFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH"

		make -j3 install $EXPORT
		cd $CWD
	done
fi

if [ "$LIPO" ]
then
	echo "building universal binaries..."
	mkdir -p $FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
fi

#rm -rf `$THIN` `$SCRATCH`