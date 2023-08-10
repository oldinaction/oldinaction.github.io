---
layout: "post"
title: "php"
date: "2017-08-20 11:39"
categories: [lang]
tags: [php]
---

## PHP简介

- [官网](http://www.php.net/)、[官方文档](http://php.net/manual/zh/)

## 安装

### PHP及主要模块安装

- windows安装php：http://php.net/downloads.php
    - 可下载`xampp`或`lnmp`集成包(包含apache/mysql/php等服务)
- mac安装参考[mac.md#php](/_posts/linux/mac.md#PHP)
- linux下安装分为(可同时安装php和php-fpm等模块)
    - **yum-config-manager**
    - **dnf**
    - yum install -y php74-* (remi镜像)
    - yum install php71w-* (webtatic镜像)
- **yum-config-manager镜像方式**

```bash
# 参考 https://www.cnblogs.com/laterzh2022/p/16272581.html

# 添加EPEL和REMI存储库
yum install epel-release
# 访问 http://rpms.remirepo.net/enterprise/ 查看 remi 源
# CentOS 7最新版(如7.9可以为remi-release-7.9.rpm)
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
# CentOS 8.4
yum install http://rpms.remirepo.net/enterprise/remi-release-8.4.rpm
yum -y install yum-utils # 用于执行 yum-config-manager  
yum repolist all | grep php

# 安装PHP相关模块
# 对于centos 8.4，此时会执行出错，也找不到remi-php73，可通过yum install php73-php-fpm解决，但是更推荐dfn方式
yum-config-manager --enable remi-php74
yum install -y php php-cli php-fpm php-mysqlnd php-zip php-devel php-gd php-mcrypt php-mbstring php-curl php-xml php-pear php-bcmath php-json php-redis

php -v
systemctl enable php-fpm && systemctl start php-fpm && systemctl status php-fpm # 可查看php-fpm.conf配置文件位置

# 查看php.ini文件位置. 或者 php --ini 查看配置文件位置
php -i | grep php.ini
# 查看启用的模块
php --modules

# 卸载
yum remove php*
# @remi-*组下的一般都是相关的
yum list installed | grep php
```
- **dfn镜像方式**

```bash
# 对于 CentOS 8.4
yum install epel-release
# yum install https://rpms.remirepo.net/enterprise/remi-release-8.rpm # 会报错，此时必须>=8.7
yum install http://rpms.remirepo.net/enterprise/remi-release-8.4.rpm
# yum repolist all | grep php # 会找不到包，但是dnf可以
dnf module list php
# 启用7.3
dnf module enable php:remi-7.3 -y
# 安装(报错的话继续往下看)
    # php扩展包安装。下载地址：https://centos.pkgs.org/
    # 扩展中的php-devel(php-zip依赖此包)安装报了错：- nothing provides libedit-devel(x86-64) needed by php-devel-7.3.33-1.el8.re，前往上面网站找到了dnf的安装方式
    # 安装PHP扩展如果报错则通过一下方式安装，如 libedit-devel
        # 此时可能提示`Error: Unknown repo: 'powertools'`，需执行
        # yum install -y dnf-plugins-core
        # dnf config-manager --set-enabled PowerTools (或powertools)
    # dnf --enablerepo=PowerTools install libedit-devel
yum install php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-xml php-redis php-curl php-pear php-gd php-imagick php-mysqli php-openssl php-fpm php-zip

# 也可继续安装扩展，如安装扩展bcmath(composer安装项目依赖时可能提示的是缺少ext-bcmath)
yum install php-bcmath

# 默认配置文件为 /etc/php-fpm.conf 和 /etc/php-fpm.d/www.conf；sock文件为 /run/php-fpm/www.sock
systemctl enable php-fpm && systemctl start php-fpm && systemctl status php-fpm
```

- (弃用)`yum install php74-*`

```bash
# CentOS 8.4
yum install epel-release
yum install http://rpms.remirepo.net/enterprise/remi-release-8.4.rpm
yum search php74
yum install -y php74-php-gd php74-php-pdo php74-php-mbstring php74-php-cli php74-php-fpm php74-php-mysqlnd php74-php-xml
ln /usr/bin/php74 /usr/bin/php # 创建硬链接
# 也可使用 php -v
php74 -v
# 默认sock文件为 /var/opt/remi/php74/run/php-fpm/www.sock
systemctl enable php74-php-fpm && systemctl start php74-php-fpm && systemctl status php74-php-fpm

# 卸载
yum remove php74*
```
- (弃用)`yum install php71w-*`

```bash
# 需要安装epel-release
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm

# 安装 php7.1 fpm(无需单独安装php)
# 同理其他版本为 yum -y install php70w-fpm
# 其他php模块同理，如redis模块 yum -y install php71w-pecl-redis
# php71w-mysql
yum -y install php71w-fpm
# 配置文件目录
# /etc/php-fpm.conf         # php-fpm主配置
# /etc/php-fpm.d/www.conf   # web服务配置
# /etc/php.ini              # php配置

# 启动
systemctl enable php-fpm
systemctl restart php-fpm
systemctl status php-fpm

# 卸载
yum list installed | grep php
# 卸载mysql相关包，其他模块同理
yum remove php71w-mysql.x86_64
```

### composer包管理工具安装

- Windows安装: https://getcomposer.org/download/
- Linux安装

```bash
## mac下安装(此处php为本地php命令，会安装到当前php版本对应目录；如果是x86模式的php版本，可指定php全路径)
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod a+x /usr/local/bin/composer
composer # 查看命令帮助
# 设置镜像。查看配置信息`~/.composer/config.json`
composer config -g repo.packagist composer https://packagist.phpcomposer.com
```

- 使用

```bash
# 在项目 composer.json 所在目录运行，进行依赖包安装；一般依赖包会安装到项目根目录的vendor目录
composer install
```

### php模块安装

- `php -m` 查看安装的扩展
- PEAR和PECL
    - PEAR 是“PHP Extension and Application Repository”的缩写，即PHP扩展和应用仓库
    - PECL 是“PHP Extension Community Library”的缩写，即PHP 扩展库
    - PECL 可以看作PEAR 的一个组成部分，不同的是PEAR的所有扩展都是用纯粹的PHP代码编写的，而PECL是使用C 语言开发的，通常用于补充一些用PHP难以完成的底层功能
- [PECL包下载](https://pecl.php.net/packages.php)
    - windows可下载DLL文件直接安装
    - linux等平台需要下载tgz自行编译安装

#### php-zip模块

- mac php73 安装 php-zip 失败; mac x86 php80 也安装失败

```bash
# 如下载到 /opt/php-lib 目录
wget http://pecl.php.net/get/zip-1.13.5.tgz
tar -zvxf zip-1.13.5.tgz
cd zip-1.13.5
# 执行php相关命令,类似解压缩. whereis phpize (一般和php同目录)
/usr/bin/phpize
# whereis php-config
./configure --with-php-config=/usr/bin/php-config
# php 安装 zip 扩展 报pcre错误，参考：https://blog.csdn.net/lu4506527/article/details/109537116
make && make install
# 修改配置，重启 php-fpm
vi /etc/php.ini
'''
zlib.output_compression = On
extension=/usr/lib64/php/modules/zip.so
'''
# 重启环境php-fpm
```

#### php-redis模块

```bash
## 基于windows 访问包地址下载DLL
http://pecl.php.net/package/redis
# 如下载 5.3.7 - DLL - 7.4 Thread Safe (TS) x64，会得到一个压缩包
# 解压后将 php_redis.dll 放到 %PHP_HOME%/ext 目录
# 修改 php.ini，在 Dynamic Extensions 增加配置；并重启php服务
extension=php_redis.dll
```

### PHP环境组合

- 一般包含LAMP(Linux Apache Mysql PHP)和LNMP(Linux Nginx Mysql PHP)
- 相关文件
    - `.htaccess` 是lamp文件，是伪静态环境配置文件
    - `.user.ini` 是lnmp文件，里面放的是网站的文件夹路径地址，目的是防止跨目录访问和文件跨目录读取。一般内容为`open_basedir=/项目路径/:/tmp/:/proc/`

### 项目调试

- 安装php Xdebug模块并设置
    - `php.exe -m` 查看是否安装Xdebug(`[Zend Modules]`中含有`Xdebug`)
    - 无对应配置则需进行安装
    - 安装成功后，修改`php.ini`，启用模块

        ```ini
        [xdebug]
        zend_extension=D:\software\xampp\php\ext\php_xdebug.dll
        xdebug.remote_enable=1
        ```
- 还需安装Chrome插件`Xdebug Helper for Chrome`用于调试
    - 激活Xdebug的调试器：安装好后，在打开网页时，点击插件中的Debug按钮启动
- 启动项目参考[PhpStorm进行开发](#PhpStorm进行开发)

### 配合nginx使用 

- nginx配置

```bash
server {
	listen 80;
	listen 443 ssl http2;
	listen [::]:443 ssl http2;
	listen [::]:80;
	server_name shengqitech.aezo.cn;
	index index.php index.html;
	root /wwwroot/www/shengqitech.aezo.cn;
	
	ssl_certificate         /wwwroot/data/ssl/shengqitech.aezo.cn.pem;
	ssl_certificate_key     /wwwroot/data/ssl/shengqitech.aezo.cn.key;
	
	access_log  /wwwroot/log/nginx/shengqitech.aezo.cn.log;
	error_log   /wwwroot/log/nginx/shengqitech.aezo.cn.error.log;
	
    gzip on;
    gzip_types text/plain application/x-javascript application/javascript text/javascript text/css application/xml text/xml;
    gzip_static on;

    # worldpress
	location / {
		try_files $uri $uri/ /index.php?$args;
	}
	rewrite /wp-admin$ $scheme://$host$uri/ permanent;
	
	
    ## php-fpm常用配置
    # php文件转给fastcgi处理。linux安装了php后需要额外安装如`php-fpm`来解析(windows安装了php，里面自带php-cgi.exe)
    # 如果访问 http://127.0.0.1/test/index.php?name=abc 此时会到 /wwwroot/www/shengqitech.aezo.cn 目录寻找 test/index.php 文件（location的正则仅匹配路径，不考虑url中的参数）
    # 在根目录创建`index.php`，加入`<?php echo phpinfo(); ?>`可打印php版本信息
    set $project_root "/wwwroot/www/shengqitech.aezo.cn"; # 自定义变量，可选
    location ~ \.php$ {
        # 不存在访问资源是返回404，如果存在还是返回`File not found.`则说明配置有问题(如nginx,php-fpm用户读取文件权限问题)
        try_files      $uri = 404;
        root           $project_root;
        fastcgi_pass   127.0.0.1:19000;
        # fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock; # 需修改 /etc/php-fpm.d/www.conf 配置，参考下文
        fastcgi_index  index.php;
        # 此处要使用`$document_root`否则报错File not found.`/`no input file specified`
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
    # 如果上述index.php中含有一个静态文件，此时需要加上对应静态文件的解析
    location ~ ^/my-php-static/ {
        root $project_root;
    }
	
	#禁止访问的文件或目录
	location ~ ^/(\.user.ini|\.htaccess|\.git|\.svn|\.project|LICENSE|README.md) {
		return 404;
	}
	# 缓存
	location ~ .*\.(js|css)?$ {
		expires      12h;
		error_log /dev/null;
		access_log off;
	}
	location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$ {
		expires      30d;
		error_log /dev/null;
		access_log off;
	}
}

server {
    listen 80;
	root /project/test/public;

    ## lnmp thinkphp nginx不支持pathinfo解决方法
    # http://127.0.0.1:8080/myphp1/index.php、http://127.0.0.1:8080/myphp2/index.php 都可进入相应目录
    location ~ \.php($|/) {
        # 配置PHP支持PATH_INFO进行URL重写
        set $script $uri;
        set $path_info "";
        if ($uri ~ "^(.+?\.php)(/.+)$") {
            set $script $1;
            set $path_info $2;
        }
        try_files $uri =404;
        root           /project/test/public; # public目录(一般根目录下有一个public和thinkphp目录)
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi.conf;
        fastcgi_param script_FILENAME $document_root$script;
        fastcgi_param script_NAME $script;
        fastcgi_param PATH_INFO $path_info;
    }
    # ThinkPHP Rewrite(伪静态). 参考宝塔面板
    location / {
        if (!-e $request_filename){
            rewrite ^/(.*)$ /index.php/$1 last;
            # rewrite ^(.*)$ /index.php?s=$1 last; break; # 效果一样
        }
    }
}
```
- linux + nginx + fastcgi运行php程序
    - nginx配置同上
    - nginx本身不能处理PHP，它只是个web服务器，当接收到请求后，如果是php请求，则发给php解释器处理，并把结果返回给客户端。nginx一般是把请求发fastcgi管理进程处理，fascgi管理进程选择cgi子进程处理结果并返回被nginx。而使用php-fpm则可以使nginx支持PHP
    - 需要安装`php-fpm`来实现fastcgi，按照参考上文
    - `systemctl start php-fpm` 默认监听`9000`端口
        - 编辑`/etc/php-fpm.d/www.conf`中的`listen = 127.0.0.1:9000`可修改监听端口；也可将此listen改为 `listen = unix:/var/run/php-fpm/php-fpm.sock`，从而nginx配置改为`fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;`来进行转发
- windows + nginx + fastcgi运行php程序(php5.3版本之后已经有了`php-cgi.exe`的可执行程序，经测试本地开发就很容易挂)
    - 快捷操作脚本(需提前启动，监听在19000端口上)

        ```bat
        :: 启动脚本 start_php_cgi.bat(直接执行php-cgi.exe默认监听端口是9000)。此处使用`RunHiddenConsole.exe`需要加入到PATH，下载地址`http://redmine.lighttpd.net/attachments/download/660/RunHiddenConsole.zip`
        @echo off
        echo Starting PHP FastCGI...
        RunHiddenConsole.exe d:\software\xampp\php\php-cgi.exe -b 127.0.0.1:19000 -c d:\software\xampp\php\php.ini

        :: 停止脚本 stop_php_cgi.bat
        @echo off
        echo Stopping nginx...
        taskkill /F /IM nginx.exe > nul
        ```
- 常见问题
    - nginx 502，日志显示Permission denied，权限问题
        - 参考下文`File not found.`
        - 如果项目目录为`/project/test/public`则需要`/project`/`project/test`/`/project/test/public`均有执行权限(目录一般有执行权限，但是如果把文件放在/root目录则不行，root目录默认无执行权限，因此建议放到如/wwwroot/www等目录)。参考: https://serverfault.com/questions/170192/nginx-php-fpm-permission-denied-error-13-in-nginx-log-configuration-mista
        - 此时访问php文件仍然有问题，必须设置php-fpm的sock文件所属`chown www:www www.sock`
            - 但是每次重启php-fmp又需要重新设置
    - 浏览器访问返回`File not found.` 此为php-fpm返回的错误，一般为nginx,php-fpm用户读取文件权限问题，具体如下
        - nginx.conf中一般设置`user www www;`(此时www用户必须要有权限读取到对应项目目录，项目父目录无所谓)
        - /etc/php-fpm.d/www.conf中一般设置`user = www`和`group = www`(此处www用户同nginx需要有权限访问到对应项目目录，一般设置成和nginx一样的用户)；默认为apache(且不能设置为root)
    - 浏览器返回`Access denied.` 此为php-fpm返回的错误
        - 首先需要确保上述权限设置正确
        - 然后检查项目目录下`.user.ini`，里面放的是网站的文件夹路径地址，目的是防止跨目录访问和文件跨目录读取。一般配置为`open_basedir=/项目路径/:/tmp/:/proc/`有时候迁移项目时路径变化了则需要修改此项目路径
    - nginx报错`"/var/lib/nginx/tmp/fastcgi/xxx failed" (13: Permission denied)`
        - 执行`chown -R www /var/lib/nginx`(一般和nginx启动用户一致)
    - php报错`open(/var/lib/php/session/sess_...) failed: Permission denied (13)`
        - 一般php项目需要写文件的目录及其子目录设置成1733即可(如日志目录)
        - 执行`sudo chmod 1733 /var/lib/php/session` 参考: https://blog.csdn.net/wm9028/article/details/86571527

## PHP基本语法

> 未特殊说明，都是基于 php7

- [PHP命名规范](https://www.w3cschool.cn/phpkfbmgf/ofhbji.html)

### 基本及关键字

- [PHP中冒号、endif、endwhile、endfor这些都是什么](https://www.cnblogs.com/janoyu/archive/2010/05/04/sourcejoy_com_php_other_syntax.html)

```php
# 是调用类中的静态方法或者常量,属性的符号
::
# 是调用类中的成员方法,属性的符号
->
# 定义为Trait类(类似抽象类，但是可以被多继承)
trait MyTrait {}
# use关键字在一个类中引入Trait类后，相当于require或include了一段代码进来，不同之处在于use的Trait类与当前类是可以看做同一个类的，**即当前类可以用$this关键字调用Trait类的方法**。(此处的"当前类"指引入trait类的类)
use

## 打印日志到页面
echo $str;
print_r($arr);
var_dump($arr);
Log::info($arr . 'Laravel打印到日志文件');
```

### interface/abstract/trait

- trait [^2]
    - use关键字在一个类中引入Trait类(类似抽象类，但是可以被多继承)后，相当于require或include了一段代码进来，不同之处在于use的Trait类与当前类是可以看做同一个类的，**即当前类可以用$this关键字调用Trait类的方法**。(此处的"当前类"指引入trait类的类)
    - 当前类可以`use`多个trait类，trait类允许有实现代码，但是本身不能实例化
    - 同名方法调用优先级：**当前使用类 > Trait类 > 继承的基类**
    - trait类定义一个属性后，当前类就不能定义同样名称的属性，否则会产生 fatal error。**可通过在trait类中定义属性和属性的get方法，并在当前类中进行覆盖**
    - 继承的方式，如果基类是private修饰控制的，则子类是无法调用的。但是Trait不一样，因为它类似于Require到当前类中了，所以不管是public、protected或private都是可以直接使用的
    - 多个Trait类的冲突控制

        ```php
        // 法一：insteadof关键字
        use A, B {
            B::a insteadof A; // a方法冲突时使用B类的a方法而不使用A类的a方法
            A::b insteadof B; // b方法冲突时使用A类的b方法而不使用B类的b方法
        }

        // 法二：as关键字
        use A, B {
            B::a as c; // 声明B类的a方法为c，作用于该类
            A::b as d; // 声明A类的b方法为d，作用于该类
        }
        ```
- 示例

```php
// 抽象类（需要`extends`）
abstract class MyAbstractClass
{
    // 抽象方法，子类必须定义这些方法
    abstract protected function getValue1();
    abstract public function getValue2($param1);

    // 普通方法（非抽象方法）
    public function getValue0()
    {
        return "aezocn";
    }
}

// 接口（需要`implements`）
interface MyInterface
{
    // 接口常量，不能被覆盖
    const MyConstant = 'constant value';
    function getValue3(); // 默认是public的
}

// trait（可以 `use` 多个，允许有实现代码，但是本身不能实例化）
trait MyTrait
{
    // 抽象方法（use 这个 trait 的类必须要定义这个方法）
    abstract function getValue4();

    // 可以具有方法，静态方法，属性等
    function getValue5()
    {
        return "aezocn";
    }
}
```

#### 反射相关

```php
$ref = new \ReflectionClass($classname);
// 获取类基本信息
echo $ref->getName();
echo $ref->getFileName();
// 获取类属性信息
$properties = $ref->getProperties();
// 获取方法信息
$methods = $ref->getMethods();
// 获取接口信息
$interfaces = $ref->getInterfaces();
foreach($interfaces as $interface){
    echo $interface->getName();
}
// 获取此对象的某个Trait
$ref->getTraits()['sq\controller\CurdControllerTrait']; // 返回ReflectionClass对象
```

### 全局变量

- `$_GET` 包含GET参数，下同。如`$_GET['name']`获取name参数值
- `$_POST` 包含POST参数
- `$_REQUEST` 包含GET/POST参数，相对较慢
- `$_SESSION`
- `$_SERVER` 
    - 包含Header参数。注意：header的key会自动转为大写，且key只能包含字母、数字、中划线(-)。且中划线(-)被自动转为下划线(_)。设置一个header的key为`user-name`，通过`$_SERVER['HTTP_USER_NAME']`来获取
    - `$_SERVER['REQUEST_URI']` 获取请求路径

### 数据类型

#### 字符串

```php
// 分割字符串
$arr = explode(',', 'first,second,third');

// strpos 判断字符串开头，查找第一次遇到到的下标
// stripos 查找时忽略大小写，strrpos 查找最后一次(right)遇到的下标，strripos 最后一次忽略大小写
strpos('Hello World', 'Hello') === 0 // true
// 取前缀/后缀
substr('666-888', strpos('666-888', '-') + 1); // 888
substr('666-888', 0, strpos('666-888', '-')); // 666
```

#### array/map

- 在php中map类型可以认为是array类型互通

```php
## 创建/编辑/删除 array/map
$arr = array(); // 定义空数组
// 基于数组索引创建
$arr = ['hello', 'world'];
$arr[0]; // hello
$arr = ['first' => 'hello', 'second' => 'world'];
$arr['first']; // hello
// compact 创建一个包含变量与其值的数组
$meta_status = 'error';
$meta_message = '执行失败';
compact('meta_status', 'meta_message');
// 往数组中添加元素
$arr[] = 'add1'
array_push($arr, 'add2', 'add3');
// 删除某个元素
unset($arr['first']);

## 数组信息获取
// 长度获取
count($arr)

## 循环
$num = count($arr);
for($i = 0; $i < count($arr); $i++) {
    echo $arr[$i]."<br />";
}
foreach ($array as $value) {
  // code to be executed;
}

## 获取array的keys
// 语法：array_keys($array, $value，$strict); $value为获取指定值的索引；$strict在获取$value时是否使用严格模式(类型和数值都需要相等)，默认是false不使用
$a = array("a"=>"Horse","b"=>"Cat","c"=>"Dog");
print_r(array_keys($a)); // Array ( [0] => a [1] => b [2] => c ) 
$a = array(10,20,30,"10"); 
print_r(array_keys($a, 10)); //  Array ( [0] => 0 [1] => 3 ) 
print_r(array_keys($a, 10, true)); // Array ( [0] => 3)

## 判断
in_array("hello", $a); // false. 判断包含
is_array($a); // true. 判断变量是否是数组

## 相关函数
// 向数组的尾部添加元素
array_push(array,value1,value2...);
// 合并两个数组/对象
$merge = array_merge($arr1, $arr2);
// 过滤数组，去掉值为空的数据. PHP7.4支持箭头函数
$newObj = array_filter($obj, function($value, $key) {
    return ($value !== '' && $value !== null);
}, ARRAY_FILTER_USE_BOTH); // 0:默认,传递值 | 1:ARRAY_FILTER_USE_BOTH | 2:ARRAY_FILTER_USE_KEY
$newObj = array_filter($obj, fn($value, $key) => ($value !== '' && $value !== null));
// 按照key对原对象进行排序
ksort($array);
```

#### json

- 参考: https://www.runoob.com/php/php-json.html

```php
// 数组转json字符串 => 默认将索引数组转成js数组，将关联数组转成js对象
$json_str = json_encode($arr);
$json_str = json_encode($arr, JSON_UNESCAPED_UNICODE); // 防止中文被编码

// json字符串转对象/数组
// true表示返回的是array，通过属性取值；如果属性不存在也会报错，可使用 empty($json['key']) 先判断一下
$json = json_decode($json_str, true);
// 返回的是stdClass, 通过->取值; 如果字符串不是json格式不会报错，而是返回null，如果取值的属性不存在会报错
$json = json_decode($json_str);
if(isset($json -> username)) {
    // 判断 $json 对象中是否有username属性. 不判断直接使用，如果不存在此属性时会报错
    // ($json -> username == null)、(is_null(($json -> username))) 都会报错。特别当$json可能为空时
}

// 防止返回null，仍然需要判断属性是否为空
public function getJsonSafe(string $str) {
    if(empty($str)) {
        return json_decode('{}', true);
    }
    $json = json_decode($str, true);
    return empty($json) ? json_decode('{}', true) : $json;
}
```

#### 数据类型转换

```php
// 拷贝对象
$newMap = array_merge([], $oldMapOrArray);
```
#### 空值判断
    
```php
// 判断stdClass是否有某个属性，具体参考数组
$json = json_decode($json_str); // 格式化json字符串为对象。返回的是stdClass
if(isset($json -> username)) {
    // 判断 $json 对象中是否有username属性.
    // ($json -> username == null)、(is_null(($json -> username))) 都会报错。特别当$json可能为空时
}

// 判断数组是否有某个索引
if(isset($_POST['id'])) {}

// empty判断空
empty(null | '' | 0); // true

// 此时传入空，调用方法就报错；需要加?才能传空
public function setOrder(Order $order) {}
public function setOrder(?Order $order) {}
```

### 流程控制

- for循环
    - 支持break 和 continue，包括 while、do while、for 和 foreach 循环

```php
for ($i=0; $i < 10; $i++) {
    if($i == 3) {
        break;
    } else {
        continue;
    }
    echo $i;
}

foreach ($keys as $key) {}
foreach($obj as $key => $value) {}
```

### 面向对象

```php
// 判断对象类型
if ($dog instanceof \Animal\MyAnimal && $dog instanceof MyDog) {}
```

### 文件

```php
// 移动文件
$res = is_dir(dirname($dst)) || mkdir(dirname($dst), 0644, true); // 先用mkdir()函数确保 $dst 文件相关的目录存在
return $res && rename($src, $dst); // 然后移动
```

## php.ini配置

- 查看php配置

```php
<!-- index.php -->
<?php
phpinfo();
```

- 配置

```ini
[PHP]
# 允许上传的文件大小, 可设置如1G
upload_max_filesize = 2M
# 允许post提交的数据大小(一般此参数也会影响文件上传的大小)
post_max_size = 8M


[MySQLi]
# mysql.sock默认路径为以下，如果不一样则需要修改，否则mysql会连接不上
mysqli.default_socket = /var/lib/mysql/mysql.sock
```

## 框架

- [wordpress](/_posts/lang/php/wordpress.md)
- [ThinkPHP](/_posts/lang/php/thinkphp.md)
- [其他框架参考](/_posts/lang/php/php-tools.md)

## 易错点

- `$_POST`接受数据 [^1]
    - Coentent-Type仅在取值为`application/x-www-data-urlencoded`和`multipart/form-data`两种情况下，PHP才会将http请求数据包中相应的数据填入全局变量`$_POST`。(jquery会默认转换请求头)
    - Coentent-Type为`application/json`时，可以使用`$input = file_get_contents('php://input')`接受数据，再通过`json_decode($input, TRUE)`转换成json对象
    - 微信小程序wx.request的header设置成`application/x-www-data-urlencoded`时`$_POST`也接受失败(基础库版本1.5.0，仅供个人参考)，使用file_get_contents('php://input')可以获取成功

## 案例

### POST接口

> https://www.jb51.net/article/51974.htm

```php
function requestPost($url = '', $post_data = array()) {
    if (empty($url) || empty($post_data)) {
        return false;
    }
    
    $postUrl = $url;
    $curlPost = $post_data;
    // $curlPost = 'id=35289';
    // $curlPost = json_encode(array(
    //     'id'=> '35289',
    //     'username'=> 'smalle'
    // ));

    $ch = curl_init(); // 初始化curl
    curl_setopt($ch, CURLOPT_URL, $postUrl);
    curl_setopt($ch, CURLOPT_HEADER, false);
    // curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-Type : application/json'));
    // curl_setopt($ch, CURLOPT_HTTPHEADER, getAuthHeaders());
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);  // 执行结果是否被返回，1是返回，0是不返回
    curl_setopt($ch, CURLOPT_POST, count($curlPost)); // 1: post提交方式
    curl_setopt($ch, CURLOPT_POSTFIELDS, $curlPost);
    $data = curl_exec($ch); // 运行curl
    curl_close($ch);
    // print_r($data);
    // $data = json_decode($data, true);

    return $data;
}

//生成http头信息的方法
function getAuthHeaders(){
    //appid需要提前申请
    $appid = '';
    $time = time();
    //appkey需要提前申请
    $appkey = '';
    //这里签名我们采用以下三者的md5
    $sign = md5($appid . '&' . $appkey '&' . $time);
    return array(
        'Content-Type : application/json',
        'charset : '.'utf-8',
        // 我们同时把appid，TimeStamp，签名发送给服务端，请求其通过appid查询appkey鉴权md5签名的正确与否
        'X-Auth-Appid : ' . $appid,
        'X-Auth-TimeStamp : ' . $time,
        'x-Auth-Sign : ' . $sign
    );
}
```

#### 微信公众号开发

```php
<?php
//定义 TOKEN(要与开发者中心配置的TOKEN一致)
define("TOKEN", "smallelife");
//实例化对象
$wechatObj = new wechatCallbackapiTest();
//调用函数
if (isset($_GET['echostr'])) {
	$wechatObj->valid();
}else{
	$wechatObj->responseMsg();
}
 
class wechatCallbackapiTest {
	public function valid(){
		$echoStr = $_GET["echostr"];
		
		if($this->checkSignature()) {
			echo $echoStr;
			exit;
		}
	}
 
	public function responseMsg() {
 
		// $postStr = $GLOBALS["HTTP_RAW_POST_DATA"]; // 虚拟机可能禁止register_globals导致无法获取body数据
		$postStr = file_get_contents("php://input");
 
		if (!empty($postStr)){
				libxml_disable_entity_loader(true);//安全防护
				$postObj = simplexml_load_string($postStr, 'SimpleXMLElement', LIBXML_NOCDATA);
				$fromUsername = $postObj->FromUserName;
				$toUsername = $postObj->ToUserName;
				$keyword = trim($postObj->Content);
				$time = time();
				$textTpl = "<xml>
							<ToUserName><![CDATA[%s]]></ToUserName>
							<FromUserName><![CDATA[%s]]></FromUserName>
							<CreateTime>%s</CreateTime>
							<MsgType><![CDATA[%s]]></MsgType>
							<Content><![CDATA[%s]]></Content>
							<FuncFlag>0</FuncFlag>
							</xml>";             
				if(!empty( $keyword )) {
					$msgType = "text";
					//用户给公众号发消息后，公众号被动(自动)回复的消息内容
					$contentStr = "欢迎来到微信公众平台开发世界!";
					$resultStr = sprintf($textTpl, $fromUsername, $toUsername, $time, $msgType, $contentStr);
					echo $resultStr;
				}else{
					echo "Input something...";
				}
 
		}else {
			echo "";
			exit;
		}
	}
		
	private function checkSignature() {
		if (!defined("TOKEN")) {
			throw new Exception('TOKEN is not defined!');
		}
		
		$signature = $_GET["signature"];
		$timestamp = $_GET["timestamp"];
		$nonce = $_GET["nonce"];
		$token = TOKEN;
		$tmpArr = array($token, $timestamp, $nonce);
		sort($tmpArr, SORT_STRING);
		$tmpStr = implode( $tmpArr );
		$tmpStr = sha1( $tmpStr );
		
		if( $tmpStr == $signature ){
			return true;
		}else{
			return false;
		}
	}
}
 
?>
```

## PhpStorm进行开发

- PhpStorm配置。参考[http://blog.aezo.cn/2016/09/17/extend/idea/](/_posts/extend/idea.md#IDEA开发PHP程序)
- 参考[项目调试](#项目调试)
- **PHP Build-in Web Server** 进行调试(无需外部apahce，无需启动xampp)
    - 保证xdebug和chrome插件配置成功
    - 项目配置 - 新建PHP Build-in Web Server
    - Host填内网地址/localhost，端口随便填，如果需要通过花生壳映射则端口建议443(否则部分重定向会带上原始端口)
    - Document Root填项目web目录(如Thinkphp的public，Wordpress的项目根目录，其实就是nginx的root目录)
    - 配置好后直接启动即可
- PHP Web Page 进行调试(需配合外部apahce，如xampp)
    - 使用前需配置php可执行程序路径(Languages - PHP). 如果使用xampp，则可使用xampp中配置的xdebug
    - 进行debug时，创建一个`PHP Web Page`启动配置，此时host和port需要填Apache服务器的host和port(PhpStorm中的启动配置并不会启动服务器，因此需要另外启动Apache等服务器)
        - Run Debug - PHP Web Page - 新建Server(localhost:8110, Xdebug) - Start Url(/test/index.php) - 启动Debug - 访问 http://localhost:8110/test/index.php
    - PHPStorm使用Xdebug进行调试时，没打断点也一直进入到代码第一行：去掉勾选Run - Break at first line in PHP Scripts
    - PHPStorm需要启动Debug监听：`Run - Start Listening for PHP Debug Connection`

## xampp

- 支持Windows、Linux、Mac，类似软件如`WampServer`、`lamp`、`lnmp`
- xampp是将 Apache + MariaDB + PHP + Perl、tomcat、FileZila等软件打包打一起
- 安装[xampp](https://jaist.dl.sourceforge.net/project/xampp/XAMPP%20Windows/7.3.10/xampp-windows-x64-7.3.10-1-VC15-installer.exe)
- 修改 xampp Apache 端口(此时访问`http://localhost:8110/`访问的是目录`D:\software\xampp\htdocs`)
    - 修改apache配置的`httpd.conf`文件中`80`端口为`8110`
    - 修改apache配置的`extra/httpd-ssl.conf`文件中`443`为`8443`
    - 配置端口(Config - Services and Port Settings)为`8110`
- 设置xampp Apache虚拟机(此时访问`http://localhost:8111/`访问的是目录`D:\phpwork`，且同时可访问8110)
    
    ```bash
    ## httpd.conf
    Listen 8110
    Listen 0.0.0.0:8111 # 增加虚拟机监听端口

    <Directory />
        #AllowOverride none
        #Require all denied # 拒绝所有请求
        AllowOverride all # 所有都重定向
        Allow from all
    </Directory>

    ## extra/httpd-vhosts.conf 增加虚拟机
    <VirtualHost *:8111>
        ServerName localhost
        DocumentRoot D:/phpwork
    </VirtualHost>

    ## 重启apache
    ```

## lnmp

- 类似xampp，专注于linux环境
- https://lnmp.org/

## 其他

### php测试

- 使用`apache`自带的`bin/ab.exe`工具
    - `ab.exe-n 10000 -c 100 http://localhost/index.php` 表示100个人访问该地址10000次
        - 如果并发调到500，则会提示`apr_socket_connect()` 原因是因为apache在windows下默认的最大并发访问量为150。我们可以设置conf\extra下的httpd-mpm.conf文件来修改它的最大并发数





---

参考文章

[^1]: http://blog.csdn.net/qw_xingzhe/article/details/59693782 (微信小程序$_POST无法接受参数)
[^2]: https://blog.csdn.net/dream_successor/article/details/78481265
