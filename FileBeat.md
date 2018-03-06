
# FileBeat (Golang)

## Repos

> ElasticSearch.md

## Install

yum install -y filebeat

## Config

vim /etc/filebeat/filebeat.yml

## Service (CentOS 7.x)

 	systemctl status filebeat
	systemctl start filebeat
	
	systemctl enable filebeat
	
	ps -ef | grep filebeat
	

## Accuen Filebeat Config

### Accuen Web01

 - 设定hostname为accuen-web01
 - 配置filebeat：elk / filebeat / accuen-web01.yml

### Accuen web

 - 添加一个新的关键字 “log_type”，log_type:public_net_nginx_log
 
 
## Saas Filebeat Config

### Saas Web01

 - 设定hostname为saas-web01
 - 配置filebeat：elk / filebeat / saas-web01.yml


     