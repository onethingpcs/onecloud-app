#!/bin/sh

#LOG_LEVEL=0--no log output from amadec; LOG_LEVEL=1--output amadec log
export LOG_LEVEL=0
export CURLLOG_LEVEL=0
export DASHLOG_LEVEL=0
#audio formats to decode use arm decoder
export media_arm_audio_decoder=ape,flac,dts,ac3,eac3,wma,wmapro,mp3,aac,vorbis,raac,cook,amr,pcm,adpcm
#third party lib modules to use
export media_libplayer_modules=libcurl_mod.so,libdash_mod.so
