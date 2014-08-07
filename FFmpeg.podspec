Pod::Spec.new do |s|
  s.name         = "CocoaFFmpeg"
  s.version      = "2.2"
  s.license      = { :type => 'LGPLv2.1+', :file => 'COPYING.LGPLv2.1' }
  
  s.summary      = "Pre-compiled light-weight FFmpeg libraries for iOS. Build your own with attached build script."
  s.description      = <<-DESC
  						Optimized to decrease the size by compiling the necessary formats only
							video codecs: h264 (enable h263)
							audio codecs: AAC (enable mp3)
						FFmpeg - A complete, cross-platform solution to record, convert and stream audio and video.
						https://www.ffmpeg.org/
                       DESC

  s.homepage     = "https://github.com/jold/CocoaFFmpeg"
  s.author       = { "Daniel Jankovic" => "dj@digital-life.cz" } 
  s.source       = { :git => "https://github.com/jold/CocoaFFmpeg.git", :tag => "2.2" }
  
  s.ios.deployment_target = '6.0'
  s.requires_arc = false
  s.platform     = :ios
  s.default_subspec = 'precompiled'

  s.subspec 'precompiled' do |ss|
    ss.source_files        = 'universal/include/**/*.h'
    ss.public_header_files = 'universal/include/**/*.h'
    ss.header_mappings_dir = 'universal/include'
    ss.vendored_libraries  = 'universal/lib/*.a'
    ss.libraries = 'avcodec', 'avformat', 'avutil', 'swscale', 'z', 'bz2'
  end

end
