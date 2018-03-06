#	原理图

![image](image/analysis_log_2.jpg)

filebeat负责收集数据，并将数据推送到logstash或者elasticearch。

logstash负责将收集的数据进行处理，处理包括截取和过滤等。

elasticearch负责数据存储，是elk的存储设备，要考虑其文件数据容量问题。处理过期数据通过9200端口访问处理，通过脚本进行定期删除过期数据，脚本已经提交到git。

kibana负责将数据收集展示到web界面。

##      端口介绍

###     Elasticsearch

>    Elasticsearch有两个端口

9200：收集数据，数据来源有logstash、beats插件等。

9300：发送数据，将数据发送给kibana、grafana等。

###     Kibana

>    Kibana有一个端口

5601：web页面访问端口。

###     Logstash

>    logstash有两个端口

5044：收集数据，数据来源是beats。

9600：数据访问API接口。



#	各部分详解

##	filebeat

filebeat是beats的一个插件，主要用于监控、收集服务器日志文件，

