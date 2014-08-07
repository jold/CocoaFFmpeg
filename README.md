# FFmpeg iOS build script

Pre-compiled light-weight FFmpeg libraries for iOS. Build your own with attached build script.

Tested with:

* FFmpeg 2.2 release
* Xcode 5.1
* https://github.com/libav/gas-preprocessor (for arm64)
* yasm 1.2.0

## Usage

build-ffmpeg.sh [minimal|entire] [arm64|armv7s|armv7|x86_64|i386] [lipo] 

#### common:

build optimized libraries with all necessary stuff and h264 codec 
```
./build-ffmpeg.sh minimal
```
build minimal configuration for device architectures only 
```
./build-ffmpeg.sh minimal arm64 armv7s armv7
```

#### miscellaneous:
build configuration with all codecs 
```
./build-ffmpeg.sh universal
```
join created libraries only for architectures into one fat library
```
./build-ffmpeg.sh lipo
```

## Download

You can download a binary for FFmpeg 2.2 release at https://downloads.sourceforge.net/project/ffmpeg-ios/ffmpeg-ios-sf.tar.bz2

## External libraries

You should link with

* libz.dylib
* libbz2.dylib
* libiconv.dylib

## Influences

* https://github.com/jold/CocoaRTMP
* https://github.com/bbcallen/ijkplayer/blob/fc70895c64cbbd20f32f1d81d2d48609ed13f597/ios/tools/do-compile-ffmpeg.sh#L7
* https://github.com/chrisballinger/FFmpeg-iOS