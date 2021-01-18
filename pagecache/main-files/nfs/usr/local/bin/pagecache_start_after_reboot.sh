#!/bin/bash
set -e

# план:
# прочитать пременные
# проверить несмонтирована ли оверлей уже
# потушить nfs-server
# смонтировать
# запустить nfs-server

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"

## прочитать переменные
# 	по идее должны считаться вот такие переменные
#    L1="/dev/mapper/vg02-lvol0"
#    root_folder="/mnt/overlay1"
#
#    U1="/dev/mapper/vg02-lvol1"
#    lowerdir="/mnt/overlay1/lower"
#
#    upperdir="/mnt/overlay1/upper/upper"
#    workdir="/mnt/overlay1/upper/workdir"
#    mergedir="/mnt/overlay1/merged"


 settings_folder="/etc/pagecache"
 settings_file="$settings_folder/settings.ini"

    file_path=$settings_file
    if [[ ! -f $settings_file ]]
    then
	echo "error! settings file is absent"; exit 1
    else
        source $settings_file
    fi




##  проверка что оверлей несмонтирован
if  [[ ($(df -h | grep "$mergedir" | wc -l)  !=  0 ) ]]
then
    echo "error! overlay is already mounted"; exit 1
fi

## потушить nfs-server
service nfs-server stop



## монтируем
# 	монтируем upper
if  [[ ($(df -h | grep "$root_folder/upper" | wc -l)  ==  0 ) ]]
then
mount -o noatime,data=ordered $L1 $root_folder/upper
chown nobody.nogroup $root_folder/upper
# создаем в нем подпапки $upperdir  $workdir
upperdir=$root_folder/upper/upper
workdir=$root_folder/upper/workdir
mkdir $upperdir $workdir
fi


# 	монтируем lower
mnt_point=$lowerdir
if  [[ ($(df -h | grep "$mnt_point" | wc -l)  ==  0 ) ]]
then
mount -o noatime,data=ordered $U1 $mnt_point
chown nobody.nogroup $mnt_point
     # если нет папки то создаем ее
    if [[ ! -d $mnt_point/upper ]]
    then
        mkdir $mnt_point/upper
	chown nobody.nogroup $mnt_point/upper
    fi
mount -o noatime,data=ordered --bind $mnt_point/upper $mnt_point
chown nobody.nogroup $mnt_point
fi


# 	монтируем overlay
mount -t overlay -o index=on,redirect_dir=nofollow,nfs_export=on,noatime,lowerdir=$lowerdir,upperdir=$upperdir,workdir=$workdir  none $mergedir
#chmod 777 $mergedir
#chown nobody.nogroup $mergedir

## запустить nfs-server
#service nfs-server start



