#!/bin/sh

old_state=1
outputmode=$(cat /sys/class/display/mode)
hpdstate=$(cat /sys/class/amhdmitx/amhdmitx0/hpd_state)
old_state=$hpdstate

# outputmode=720p60hz
#if [ "$hpdstate" = "1" ]; then
#	if [ "$outputmode" = "480cvbs" -o "$outputmode" = "576cvbs" ] ; then
#    outputmode=720p60hz
#  fi
#else
#	if [ "$outputmode" != "480cvbs" -a "$outputmode" != "576cvbs" ] ; then
#    outputmode=576cvbs
#  fi
#fi

echo $outputmode > /sys/class/display/mode

echo 0 > /sys/class/ppmgr/ppscaler
echo 0 > /sys/class/graphics/fb0/free_scale
echo 1 > /sys/class/graphics/fb0/freescale_mode


	case $outputmode in

		480*)
		echo 0 0 1279 719 > /sys/class/graphics/fb0/free_scale_axis
		echo 0 0 1279 719 > /sys/class/graphics/fb0/window_axis 
		;;

		576*)
		echo 0 0 1279 719 > /sys/class/graphics/fb0/free_scale_axis
		echo 0 0 1279 719 > /sys/class/graphics/fb0/window_axis
		;;

		720*)
		echo 0 0 1279 719 > /sys/class/graphics/fb0/free_scale_axis
		echo 0 0 1279 719 > /sys/class/graphics/fb0/window_axis
		;;

		1080*)
		echo 0 0 1919 1079 > /sys/class/graphics/fb0/free_scale_axis
		echo 0 0 1919 1079 > /sys/class/graphics/fb0/window_axis
		;;

		4k2k*)
		echo 0 0 1919 1079 > /sys/class/graphics/fb0/free_scale_axis
		echo 0 0 1919 1079 > /sys/class/graphics/fb0/window_axis
		;;
 
		*)
		#outputmode= 720p60hz
		echo 720p60hz > /sys/class/display/mode  
		echo 0 0 1279 719 > /sys/class/graphics/fb0/free_scale_axis
		echo 0 0 1279 719 > /sys/class/graphics/fb0/window_axis

esac

echo 0x10001 > /sys/class/graphics/fb0/free_scale

