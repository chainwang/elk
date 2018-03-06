#	简介
	
filebeat采集完数据发送给logstash，在数据量特别大的时候就需要占用一些带宽，为了解决这个问题我们可以将filebeat采集的数据进行一些过滤，filebeat里面有自带的过滤方法。

这些过滤方法同样适用于其他插件


#	使用方法

官网上提供了两种过滤方法，一种是简单处理，系统自带的。另一种是自定义处理，自己编写事件。

##	简单处理

我们可以在filebeat配置文件里面的“filebeat.prospectors”部分添加一些系统选项，选项包括 “include_lines”，“exclude_lines”和 “exclude_files”。


>“include_lines”：包含哪些关键字的行就显示（输出）

eg:包含有“ERROR”，以“WARN”开头的行都要输出出来


```
...
filebeat.prospectors:
- input_type: log
  paths:
    - /data/java/log/*.log
  lude_lines:["ERROR","^WARN"] 
...
```

>	"exclude_lines”：排除含有哪些关键字的行

eg::包含有“ERROR”，以“WARN”开头的行都要输出出来，不显示带有“INFO”关键字的行。

```
...
filebeat.prospectors:
- input_type: log
  paths:
    - /data/java/log/*.log
  lude_lines:["ERROR","^WARN"]
  exclude_lines:["INFO"]
...
```

注意：如果一行及有显示关键字又有不显示关键字，系统会偏向显示。


>	"exclude_files" :排除文件

eg:排除监控目录下面的"test.log"

```
...
filebeat.prospectors:
- input_type: log
  paths:
    - /data/java/log/*.log
  exclude_files:["test.log"]
...
```

这些选项中都是可以采用正则表达式去匹配关键字

##	自定义处理

自定义处理一般是用在beats的监控插件。

自定义处理就是定义时间，满足我的条件就放行，如果有多个事件是串联执行

event -> processor 1 -> event1 -> processor 2 -> event2 ...

事件处理也是在配置文件中定义

>	定义方法:

```
...
filebeat.prospectors:
- input_type: log
  paths:
    - /data/java/log/*.log
  exclude_files:["test.log"]
...  


processors:
 - <processor_name>:
     when:
        <condition>
     <parameters>
 - <processor_name>:
     when:
        <condition>
     <parameters>
...
```

“processors:”：定义处理事件的关键字。

“when:”“when”和<condition>是一起的，如果有就判断，没有就执行下面。

”- <processor_name>:“：处理事件系统函数，系统定义的有5种：

add_cloud_metadata（添加云主机，不支持中国的云机器）
decode_json_fields（把含有json的字符串转化成对象输出）
drop_event（满足什么条件就删除）
drop_fields（满足什么条件删除字段）
include_fields（满足条件输出字段）

“<condition>”：条件，可选的参数有：

equals（等于）
contains（包含）
regexp（正则匹配）
range（范围）
or
and
not

 ”<parameters>“：参数，一般指的是监控数据的值。
 
 
 详情见官网：
 [https://www.elastic.co/guide/en/beats/filebeat/5.4/configuration-processors.html](https://www.elastic.co/guide/en/beats/filebeat/5.4/configuration-processors.html)
 



eg:定义一个删除“DBU”开头的行

```
processors:
 - drop_event:
     when:
        regexp:
           message: "^DBG"

```
##	添加关键值

我们可以在配置文件里面添加一些其他标志性关键字来区分日志来源

我们定义一个字段“service”赋值为test01

```
filebeat.prospectors:
- input_type: log
  paths:
    - /var/log/*.log
    
document_type: syslog
  fields:
    service: test01
  fields_under_root: true
```

“document_type”：文档类型

“fields_under_root: true”：如果此选项设置为true，则自定义字段将作为顶级字段存储在输出文档中，而不是分组在 fields子字典内。


##	Java异常多行处理成一行

实现方式

```
filebeat.prospectors:

- input_type: log

  paths:
    - /data/log/java/*.log
#  tail_files: true #以文件末尾开始读取数据
  multiline:
    pattern: ^\d{4}
    match: after
    negate: true


```
只要是以“tab键”开头的就算是上一行

##	logstash过滤错误，发送邮件

安装插件

	cd /usr/share/logstash/

	./bin/logstash-plugin  install logstash-output-email

添加配置

vim /etc/logstash/conf.d/logstash.conf

<pre>
output {
...
if "ERROR" in [message]  {
    email {
                        to => "1603546228@qq.com"
                        address => "smtp.163.com"
                        port => 25
                        use_tls => true
                        via => "smtp"
                        username => "13554368217@163.com"
                        password => "Cheng123456"
                        from => "13554368217@163.com"
                        subject => "错误日志提醒: %{host}-%{env} "
                        body => "主机: %{host} \n日志: %{env} \n内容:%{message} "
    }
  }

}
</pre>


如果使用sendmail，需要把via参数内容换成“sendmail”

via => "sendmail"

<pre>

 if "ERROR" in [message] {
   email{
        to => "cat@marketin.cn"
        address => "localhost"
        port => 25
        use_tls => true
        via => "sendmail"
        username => "mdoor"
        password => "9x15SKxBZB"
        from => "mdoor@mail.cat.marketin.cn"
        subject => "[ERROR] : %{host}-%{env} "
        body => "主机: %{host} \n日志: %{env} \n \t %{message}"
    }
   }

</pre>

##	filebeat配置文件拆分

filebeat.yml里面添加多个日志文件，可能内容比较多，我们可以将其拆分开，分成不同的文件

实现方式

先在"filebeat.yml"主配置文件里面第一行添加“filebeat.config_dir: /etc/filebeat/conf.d”

<pre>
filebeat.config_dir: /etc/filebeat/conf.d
filebeat.prospectors:

- input_type: log

  paths:
    - /data/log/java/aaa.log
...
</pre>

再创建拆分的子配置文件

	mkdir /etc/filebeat/conf.d

	vim /etc/filebeat/conf.d/test01.yml

<pre>
filebeat.prospectors:

- input_type: log

  paths:
    - /data/log/java/test01.log

...
</pre>



#	参考资料

官方文档：

[https://www.elastic.co/guide/en/beats/filebeat/5.4/filtering-and-enhancing-data.html](https://www.elastic.co/guide/en/beats/filebeat/5.4/filtering-and-enhancing-data.html)

第三方网站：

[http://m.blog.csdn.net/qq_21835703/article/details/53584173](http://m.blog.csdn.net/qq_21835703/article/details/53584173)
