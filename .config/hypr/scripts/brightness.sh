#!/bin/sh

max=`cat /sys/class/backlight/intel_backlight/max_brightness`
val=`cat /sys/class/backlight/intel_backlight/brightness`
dir=$1

ten_percent=$(($max/10))

unset new_brightness
if [ "$dir" == "+" ] ; then
  echo 'old'
  new_brightness=$(($val+$ten_percent))
  if [ $new_brightness -gt $max ] ; then
    new_brightness=$max
  fi
elif [ "$dir" == "-" ] ; then
  echo 'sent'
  new_brightness=$(($val-$ten_percent))
  if [ $new_brightness -lt 0 ] ; then
    new_brightness=0
  fi
fi

echo $new_brightness > /sys/class/backlight/intel_backlight/brightness
