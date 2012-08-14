#########################
#Copyright notice
#
#(c) by Rico Dittrich <ricod1996@googlemail.com>
#All rights reserved
#
#This script is part of the Andrinux project. The Andrinux project is
#free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 2 of the License, or
#(at your option) any later version.
#
#The GNU General Public License can be found at
#http://www.gnu.org/copyleft/gpl.html.
#
#This script is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
#This copyright notice MUST APPEAR in all copies of the script!
#########################

#Setting the main values which are OS-specific. Try to not change them.
os=ubu-one
if [ "$os" == "deb-sque" ]
then
	script="boot-sque"
	dir="debian"
elif [ "$os" == "deb-whee" ]
then
	script="boot-one"
	dir="debian"
elif [ "$os" == "ubu-one" ]
then
	script="boot-one"
	dir="ubuntu"
elif [ "$os" == "ubu-nat" ]
then
	script="boot-nat"
	dir="ubuntu"
elif [ "$os" == "fed14" ]
then
	script="boot-f14"
	dir="fedora"
elif [ "$os" == "fed15" ]
then
	script="boot-f15"
	dir="fedora"
elif [ "$os" == "slack" ]
then
	script="boot-slack"
	dir="slackware"
fi

#Setting the other values. You shouldn't change them anymore...
mp=/data/local/mnt/${os}
img=${EXTERNAL_STORAGE}/andrinux/${dir}/${os}.img
null=/dev/null
loop=255

looppath=/dev/block/loop$loop 

#Getting device path for /system
system=`cat /proc/mounts|grep "/system"|cut -d" " -f1`

echo "I: Copying the script..."
#Remounting system with rw-option
mount -o remount,rw $system /system 

#Copying the script.
cp $script /system/bin/ > $null 2>&1 
echo "I: Setting permissions..."
chmod 777 /system/bin/$script > $null 2>&1

#Checking whether the script got copied right.
if [ ! -f /system/bin/$script ]
then
	echo "E: An error occurred while copying the script. Please contact me with basic informations like device, ROM, ..."
	echo "I: Exiting now..."
	exit
fi

echo "I: Little update, 2 corrected files. Installed fastly. ;)"

#Removing old loop device to avoid errors.
if [ -f $looppath ]
then
	rm $looppath 2>$null >&1 
fi

#Setting up mountpoint directories.
if [ ! -d /data/local/mnt ]
then
	mkdir /data/local/mnt 2>$null >&1
fi

if [ ! -d $mp ]
then
	mkdir $mp >$null 2>&1
fi

#Creating new loop device.
mknod -m 777 $looppath b 7 $loop > $null 2>&1
echo "I: Setting up img-file and mounting..."

#Attaching the img to the loop device.
losetup $looppath $img > $null 2>&1


#Mounting the loop device.
mount -t ext2 $looppath $mp > $null 2>&1 

#Checking whether the device got
#successfully mounted.
#If not, we try out one more time.
#Then we give up.
if [ $(mount|grep -c $looppath) = "0" ]
then
	echo "E: Mounting failed! Trying it one more time..."
	mount $looppath $mp 2>$null >&1
	if [ $(mount|grep -c $looppath) = "0" ]
	then
		echo "E: Couldn't mount the image! Giving up..."
	echo "I: Please contact me with basic informations like device, ROM, ... Thanks"
		exit
	fi
fi 

#Copying the scripts for VNC and checking whether they got copied right

cp xstart $mp/bin/ > $null 2>&1 

if [ ! -f $mp/bin/xstart ]
then
	echo "E: An error occurred while copying the xstart. Please contact me with basic informations like device, ROM, ..."
	echo "I: You can live without it but also without X."
fi 

cp xexit $mp/bin/ > $null 2>&1

if [ ! -f $mp/bin/xexit ]
then
	echo "E: An error occurred while copying the xexit. Please contact me with basic informations like device, ROM, ..."
	echo "I: You can live without it but also without X."
fi 

#Making the scripts for VNC executable.
chmod 777 $mp/bin/xstart > $null 2>&1 
chmod 777 $mp/bin/xexit > $null 2>&1 
chroot $mp /bin/ln -s /sdcard/ /root/Desktop/SD-Card > $null 2>&1

#Preparing the Easter egg. ;)
chroot $mp /bin/ln /bin/xstart /bin/xstart.sh > $null 2>&1
chroot $mp /bin/ln /bin/xexit /bin/xexit.sh > $null 2>&1 

#Creating link to SD-Card on desktop if it's not existing.
if [ ! -d $mp/root/Desktop/SD-Card ]
then
	echo "E: An error occurred while creating the shortcut for SD-Card on desktop."
	echo "I: Please contact me with basic informations like device, ROM, ..."
	echo "I: You can live without, then you can use it by accessing /sdcard."
fi 

#Saving changes to img.
sync

#Unmounting loop device.
umount -lfr $mp > $null 2>&1

#Checking for successful unmount.
if [ $(mount|grep -c $looppath) != "0" ]
then
	echo "E: Unmounting failed! Trying it one more time..."
	sleep 5
	umount -lfr $mp 2> $null 
	if [ $(mount|grep -c $looppath) != "0" ]
	then
		echo "E: Couldn't unmount the image! Giving up..."
	fi
fi 

#Detaching the img from the loop device.
losetup -d $looppath 2>$null >&1

echo "I: Done! Boot by typing $script"
