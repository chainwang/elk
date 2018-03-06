#!/bin/bash
# -------------------------------------------------------------------------------
#脚本名字:      clear_es_date.sh
#功能：         清除elk指定天之数据
#使用方法：     sh clear_es_date.sh es_host es_index es_save_days
#		es_host: es主机ip
#		es_index:es删除数据的索引
#		es_save_days:需要保留数据时间20
#时间：         2017/08/01
#作者           Casent
# -------------------------------------------------------------------------------
#整体控制，如果有错误就会立刻停止，防止错误扩大。
set -e

#对输入的参数进行判断。
if [ "$#"  -ne  3 ];then
        echo   "[ parameter error  ]"
        echo "sh $0  es_host es_index es_save_data "
        exit 1
fi

_es_host=$1
_es_index=$2
_es_save_data=$3
#创建一个文件存储上一次删除日志的时间

if [  ! -f "/data/scripts/bengin.txt" ];then
mkdir -p /data/scripts/
echo "20170701" > /data/scripts/bengin.txt
fi

_es_bengin_data=`cat /data/scripts/bengin.txt`
_es_bengin_second=`date -d "$_es_bengin_data" +%s` 
_save_days=` date -d "${_es_save_data} day ago" +%Y%m%d`
_save_second=`date -d "$_save_days" +%s`

if [ "$_save_second" -le  "$_es_bengin_second" ];then
	echo "clear success"
	exit 0
fi

echo "$_save_days" > /data/scripts/bengin.txt

while true
do
	let "_es_save_data+=1"
	_save_days=` date -d "${_es_save_data} day ago" +%Y%m%d`
	_save_second=`date -d "$_save_days" +%s`

	curl -u elastic:elastic@marketin.cn  -XDELETE "http://${_es_host}:9200/'${_es_index}'-'${_last_data}'*"
#	curl  -XDELETE "http://${_es_host}:9200/'$_es_index'-'${_last_data}'"
	if [ "$_save_second" -le  "$_es_bengin_second" ];then
	       echo "clear success"
               exit 0	
	fi
done
	

