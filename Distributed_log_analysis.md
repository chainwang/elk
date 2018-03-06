#   简介

Fluentd 和 Elasticsearch都可以做分布式日志，fluentd需要一个数据库进行收集再读取，负载就比较高，Elasticsearch直接将所有的数据收集，再展通过kibana示出来，负载低，速度快。elk还加入了beats插件，不但可以分析日志还可以分析流量、监控服务等。

-	Elasticsearch是个开源分布式搜索引擎，它的特点有：分布式，零配置，自动发现，索引自动分片，索引副本机制，restful风格接口，多数据源，自动搜索负载等。

-	Logstash是一个开源的用于收集,分析和存储日志的工具。
-	Kibana 也是一个开源和免费的工具，Kibana可以为 Logstash 和 ElasticSearch 提供的日志分析友好的 Web 界面，可以汇总、分析和搜索重要数据日志。

-	Beats是elasticsearch公司开源的一款采集系统监控数据的代理agent，是在被监控服务器上以客户端形式运行的数据收集器的统称，可以直接把数据发送给Elasticsearch或者通过Logstash发送给Elasticsearch，然后进行后续的数据分析活动。

>Beats主要有下面三个组件:

1.	Packetbeat：是一个网络数据包分析器，用于监控、收集网络流量信息，Packetbeat嗅探服务器之间的流量，解析应用层协议，并关联到消息的处理，其支 持ICMP (v4 and v6)、DNS、HTTP、Mysql、PostgreSQL、Redis、MongoDB、Memcache等协议；

2.	Filebeat：用于监控、收集服务器日志文件，其已取代 logstash forwarder；

3.	Metricbeat：可定期获取外部系统的监控指标信息，其可以监控、收集Apache、HAProxy、MongoDB、MySQL、Nginx、PostgreSQL、Redis、System、Zookeeper等服务







#   软件环境  

*    服务器环境：centos7.3   
*    JDK:1.8 
*    Elasticsearch：5.4.*
*    Logstash：5.4 *
*    Kibana：5.4.*
*    Filebeat
*    Packetbeat
*    Metricbeat

#	验证服务器环境

*	server：192.168.254.130

	需要装的服务有：JDK:1.8 ，Elasticsearch：5.4.*，Logstash：5.4 *，Kibana：5.4.*
    
*	note1：192.168.254.135

	需要装的服务有：JDK:1.8 ，Logstash：5.4 *

*	note2：192.168.254.136

分析日志只需要安装这些服务就可以，如果需要监控就可以加上beats插件



# 环境安装：

##	日志服务器环境安装

###	jdk安装：
    
下载jdk-8u121-linux-x64.rpm包，下载地址：

[http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)


	rpm -ivh jdk-8u121-linux-x64.rpm
    
*   Elasticsearch、Logstash、Kibana、Filebeat、Packetbeat、Metricbeat安装 
   
###	配置yum源，安装elk

	


	rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch	  

	vim /etc/yum.repos.d/elasticsearch.repo   
<pre>    
[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
 </pre>

>   yum安装Elasticsearch、Logstash、Kibana、Filebeat、Packetbeat、Metricbeat  

	yum install  -y  elasticsearch logstash kibana filebeat packetbeat metricbeat   

###	 修改配置文件 
   
####	   Elasticsearch配置   

Elasticsearch基本上不用怎么修改，如果修改端口可以在/etc/elasticsearch/elasticsearch.yml里面修改。

####	   Logstash配置    

       vim /etc/logstash/conf.d/logstash.conf

<pre>
input {
    beats {
        port => "5043"
    }
}
 filter {
    grok {
        match => { "message" => "%{COMBINEDAPACHELOG}"}
    }
    geoip {
        source => "192.168.254.131"
    }
}
output {
    elasticsearch {
        hosts => [ "192.168.254.130:9200" ]
    }
}
</pre>

注释：
-	input:	输入方式有多种，我们一般用的是这两种：一种是安装beats插件，如上。还有一种是按照文件读取

<pre>
input {
    file {
        path => "/data/tomcat/logs/*.log"
        start_position => "beginning"
    }
}
</pre>

-	filter:将日志数据进行整理过滤，里面有好多关键字：

1.	grok：
目前是logstash中把非标准化的日志数据转换成标准化并且可搜索数据最好的方式。Logstash默认提供了能分析包括java堆栈日志、apache日志在内的120种形式。[更多格式](https://github.com/logstash-plugins/logstash-patterns-core/tree/master/patterns)

如没有特别的需求的话，使用默认的apache日志形式就能达到想要的效果，如下。

<pre>
grok{       
    match => {"message" => ["%{COMBINEDAPACHELOG}"]}        
}
</pre>

但如果想要监控更多的信息，比如url上的参数，那么默认的表达式将没办法满足我们的需求，这时我们就需要自己动手去编写一些符合我们业务需要的表达式，并告诉logstash以某种期望的方式进行数据转换。

首先，在logstash的根目录下创建一个patterns文件夹，这个文件夹默认是没有的。

其次，在patterns文件夹中创建文件test_pattern（这里为了方便所以没有按照pattern的功能对文件进行命名，在实际应用中最好按照功能来对文件命名）。在test_pattern文件中可以按照“名称 正则表达式”这样的格式自定义一些正则表达式，以便在grok中进行使用。

最后，在使用的时候一定要把pattern_dir这个参数带上，否则logstash无法识别你自定义的这些正则表达

<pre>
grok {
    patterns_dir => ["/home/keepgostudio/download/logstash-5.2.0/patterns"]
    match => {
        "message" => ["%{PARAMS_APACHELOG}", "%{NO_PARAMS_APACHELOG}"]
    }
    remove_field => ["host", "timestamp", "httpversion", "@version"]
}
</pre>

2.	kv：

将数据源转换成键值对，并创建相对的field。比如传入“a=111&b=2222&c=3333”，输出的时候，a，b，c会被创建成三个field，这样做的好处是，当需要查询某一个参数的时候可直接查询，而不是把一个字符串搜索出来再做解析。

<pre>
kv {
    source => "field_name"
    field_split => "&?"
}
</pre>

3.	geoip:

这个从字面上就能看出他的功能，根据ip查出相应的地理信息，比如城市，省份，国家，经纬度等。这个ip信息是在logstash中的一个数据源中进行搜索查找，而不是进行网络搜索。

<pre>
geoip {
    source => "field_name"
    fields => ["country_name", "region_name", "city_name", "latitude", "longitude"]
    target => "location"
}
</pre>

4.	drop:

drop可以跳过某些不想统计的日志信息，当某条日志信息符合if规则时，该条信息则不会在out中出现，logstash将直接进行下一条日志的解析。

<pre>

if [field_name] == "value" {
    drop {}
}

</pre>

-	output:

logstash输出到elasticsearch的ip及端口






####		Kibana配置

	vim /etc/kibana/kibana.yml 

<pre>
...

server.host: "192.168.254.134"

...
</pre>
 
 ##	被监控（tomcat）服务器环境
 
 ###	jdk安装：
    
下载jdk-8u121-linux-x64.rpm包，下载地址：

[http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)


	rpm -ivh jdk-8u121-linux-x64.rpm
    
*   Elasticsearch、Logstash安装 
   
###	配置yum源，安装elk

	


	rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch	  

	vim /etc/yum.repos.d/elasticsearch.repo   
<pre>    
[elasticsearch-5.x]
name=Elasticsearch repository for 5.x packages
baseurl=https://artifacts.elastic.co/packages/5.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
 </pre>

>   yum安装Elasticsearch、Logstash

	yum install  -y  elasticsearch logstash

###	 修改配置文件 
   
####	   Elasticsearch配置   


修改以下这些

	vim	/etc/elasticsearch/elasticsearch.yml
 
```
...
# ---------------------------------- Cluster -----------------------------------
#
# Use a descriptive name for your cluster:
#
cluster.name: tomcat_001					## 集群的名字
#
# ------------------------------------ Node ------------------------------------
#
# Use a descriptive name for the node:
#
node.name: linux-node2						## 节点名字
#
# Add custom attributes to the node:
#
#node.attr.rack: r1
#
# ----------------------------------- Paths ------------------------------------
#
# Path to directory where to store the data (separate multiple locations by comma):
#
path.data: /data/es-data/				##为了防止文件过大，把收集的数据放到其他地方
#
# Path to log files:
#
path.logs: /data/log/elasticsearch/		##日志文件
#
# ----------------------------------- Memory -----------------------------------
#
# Lock the memory on startup:
#
bootstrap.memory_lock: false		##是否可以使用swap内存

# ---------------------------------- Network -----------------------------------
#
# Set the bind address to a specific IP (IPv4 or IPv6):
#
network.host: 0.0.0.0					##对外侦听的ip
#
# Set a custom port for HTTP:
#
http.port: 9200								##对外侦听的端口
#
# For more information, consult the network module documentation.
#
# --------------------------------- Discovery ----------------------------------
#
# Pass an initial list of hosts to perform discovery when new node is started:
# The default list of hosts is ["127.0.0.1", "[::1]"]
#
discovery.zen.ping.unicast.hosts: ["192.168.254.134", "192.168.254.130"]		##发现集群的ip集合
#
# Prevent the "split brain" by configuring the majority of nodes (total number of master-eligible nodes / 2 + 1):
#
discovery.zen.minimum_master_nodes: 2	##至少有两个及以上的节点才能有master

...
    
```


####	   Logstash配置    

       vim /etc/logstash/conf.d/logstash.conf

<pre>
input {
    beats {
        port => "5043"
    }
}
 filter {
    grok {
        match => { "message" => "%{COMBINEDAPACHELOG}"}
    }
    geoip {
        source => "192.168.254.131"
    }
}
output {
    elasticsearch {
        hosts => [ "192.168.254.130:9200" ]
    }
}
</pre>

注释：
-	input:	输入方式有多种，我们一般用的是这两种：一种是安装beats插件，如上。还有一种是按照文件读取

<pre>
input {
    file {
        path => "/data/tomcat/logs/*.log"
        start_position => "beginning"
    }
}
</pre>

####	Beats插件配置 

>	配置filebeat

	vim /etc/filebeat/filebeat.yml
    
修改日志位置，对服务器elasticsearch和logstash的ip和端口

<pre>
...
filebeat.prospectors:
- input_type: log
 paths:
  - /data/tomcat/logs/*.log    
#==================== Outputs =====================
#------------- Elasticsearch output ---------------
output.elasticsearch:
 # Array of hosts to connect to.
  hosts: ["192.168.254.130:9200"]
#---------------- Logstash output -----------------
output.logstash:
 # The Logstash hosts
 hosts: ["192.168.254.130:5043"] 
 ...
</pre>

>	 packetbeat配置

	# vim /etc/packetbeat/packetbeat.yml 

修改输出位置，对应到服务器elasticsearch和logstash的ip和端口

<pre>
...
========================= Outputs =========================
------------------- Elasticsearch output ------------------
output.elasticsearch:
  hosts: ["192.168.254.130:9200"]
--------------------- Logstash output ---------------------
output.logstash:
  hosts: ["192.168.254.130:5043"]               
...
</pre>


>	metricbeat配置

	vim /etc/metricbeat/metricbeat.yml    

修改输出位置，对应到服务器elasticsearch和logstash的ip和端口
<pre>
...
------------------- Elasticsearch output ------------------
output.elasticsearch:
  hosts: ["192.168.254.130:9200"]
--------------------- Logstash output ---------------------
output.logstash:
  hosts: ["192.168.254.130:5043"]
...
</pre>

软件环境已经全部安装好了，现在是启动并验证

>	启动elasticsearch 

	systemctl start elasticsearch 
    
>	加入开机启动项

	systemctl enable elasticsearch	

>	查看是否启动成功

	systemctl status elasticsearch 
 
如果有下面内容就是启动成功

<pre>
● elasticsearch.service - Elasticsearch
   Loaded: loaded (/usr/lib/systemd/system/elasticsearch.service; enabled; vendor preset: disabled)
   Active: active (running) since 二 2017-06-13 15:18:18 CST; 2h 39min ago
     Docs: http://www.elastic.co
 Main PID: 33053 (java)
   CGroup: /system.slice/elasticsearch.service
           └─33053 /bin/java -Xms2g -Xmx2g -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupa...

6月 13 15:18:18 localhost.localdomain systemd[1]: Starting Elasticsearch...
6月 13 15:18:18 localhost.localdomain systemd[1]: Started Elasticsearch.
</pre>

如果启动失败，执行下面操作

	vi /etc/elasticsearch/jvm.options
<pre>
...
 -Xms4g                    //启用如下两项   
 -Xmx4g 
 
 ##-Xms2g                     //关闭如下两项 
 ##-Xmx2g    
...
</pre>

>	其他的服务同样这样启动

	systemctl start logstash
	systemctl start kibana
    systemctl start filebeat
    systemctl start packetbeat
    systemctl start metricbeat
    
>	加入开启启动

	systemctl enable logstash
	systemctl enable kibana
    systemctl enable filebeat
    systemctl enable packetbeat
    systemctl enable metricbeat
	
>	查看状态

	systemctl status logstash
	systemctl status kibana
    systemctl status filebeat
    systemctl status packetbeat
    systemctl status metricbeat

如果全部是active (running)，就说明是安装成功了。




#   ELK基础配置：

*   打开http://serverIP:5601

*   创建索

>   配置filebeat的索引

只需输入filebeat-* 

![Alt text](image/analysis_log_1.jpg)

>	配置logstash的索引

紧接上一步，然后点击“+”,再点击“Crete”按钮创建logstash索引  

>	配置packetbeat的索引


紧接上一步，然后点击“+”,建索引页面输入“packetbeat-*”，之后kibana会自动更新，在“Time-fieldname”下面的三个选项中选择“@timestamp”，最后点击“Create”创建。

>	配置metricbeat的索引

索引页面输入“metricbeat-*”，之后kibana会自动更新，在“Time-field name”下面的选项中选择“@timestamp”，最后点击“Create”创建。

>   关于ELK Stack的一些查询语句: 

在日志服务器上面执行

①查询filebeat

	curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty'
    
②查询packetbeat

	curl -XGET 'http://localhost:9200/packetbeat-*/_search?pretty'

③查询metricbeat

	curl -XGET 'http://localhost:9200/metricbeat-*/_search?pretty'
    
④查询集群健康度

	curl 'localhost:9200/_cat/health?v'
    
⑤查看节点列表

	curl 'localhost:9200/_cat/nodes?v'

⑥列出所有索引

	curl 'localhost:9200/_cat/indices?v'
