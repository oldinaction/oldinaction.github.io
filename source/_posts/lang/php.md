---
layout: "post"
title: "php"
date: "2017-08-20 11:39"
categories: [lang]
tags: [php]
---

## php简介

- [官网](http://www.php.net/)、[官方文档](http://php.net/manual/zh/)

### 安装

- 可下载`xampp`集成包(包含apache/mysql/php等服务)
- php安装
    - windows：http://php.net/downloads.php
    - linux：`yum install -y php`

### 配合nginx使用 

- windows + nginx + fastcgi运行php程序(php5.3版本之后已经有了`php-cgi.exe`的可执行程序，经测试本地开发就很容易挂)
    - nginx配置

        ```bash
        # php文件转给fastcgi处理。linux安装了php后需要额外安装如`php-fpm`来解析(windows安装了php，里面自带php-cgi.exe)
        # 如果访问 http://127.0.0.1:8080/myphp/index.php 此时会到 /project/phphome/myphp 目录寻找/访问 index.php 文件
        location ~ \.php$ {
            # 不存在访问资源是返回404，如果存在还是返回`File not found.`则说明配置有问题
            try_files      $uri = 404;
            root           /project/phphome/myphp;
            fastcgi_pass   127.0.0.1:19000;
            fastcgi_index  index.php;
            # 此处要使用`$document_root`否则报错File not found.`/`no input file specified`
            fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
            include        fastcgi_params;
        }
        # 如果上述index.php中含有一个静态文件，此时需要加上对应静态文件的解析
        location ~ /myphp/ {
            root /project/phphome/myphp;
        }
        ```
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
- linux + nginx + fastcgi运行php程序
    - nginx配置同上
    - 需要安装`php-fpm`来实现fastcgi：`systemctl status php-fpm`

## PHP基本语法

> 未特殊说明，都是基于 php7

### interface/abstract/trait

- trait [^2]
    - use关键字在一个类中引入Trait类后，相当于require或include了一段代码进来，不同之处在于use的Trait类与当前类是可以看做同一个类的，**即当前类可以用$this关键字调用Trait类的方法**。(此处的"当前类"指引入trait类的类)
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

- 反射相关

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

### 数据类型

#### array/map

- 在php中map类型可以认为是array类型互通

```php
## 创建array/map
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
// 删除元素
unset($arr['first']);
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
array_push(array,value1,value2...); // 向数组的尾部添加元素
array_filter($arr, function($v, $k) { return $k == 'b'; }); // 数组过滤
```

#### json

```php
// http://www.ruanyifeng.com/blog/2011/01/json_in_php.html
// 数组转json字符串
$json_str = json_ecnode($arr, true);

// json字符串转对象
$json = json_decode($json_str); // 格式化json字符串为对象。返回的是stdClass
if(isset($json -> username)) {
    // 判断 $json 对象中是否有username属性. ($json -> username == null)、(is_null(($json -> username))) 都会报错。特别当$json可能为空时
}
```

#### 全局变量

- `$_GET` 包含GET参数，下同。如`$_GET['name']`获取name参数值
- `$_POST` 包含POST参数
- `$_REQUEST` 包含GET/POST参数，相对较慢
- `$_SESSION`
- `$_SERVER` 
    - 包含Header参数。注意：header的key会自动转为大写，且key只能包含字母、数字、中划线(-)。且中划线(-)被自动转为下划线(_)。设置一个header的key为`user-name`，通过`$_SERVER['HTTP_USER_NAME']`来获取
    - `$_SERVER['REQUEST_URI']` 获取请求路径

### 文件

```php
// 移动文件
$res = is_dir(dirname($dst)) || mkdir(dirname($dst), 0644, true); // 先用mkdir()函数确保 $dst 文件相关的目录存在
return $res && rename($src, $dst); // 然后移动
```

## ThinkPHP

> 未特殊说明，都是基于 ThinkPHP v5.0.24 进行记录

- [TP5 Doc](https://www.kancloud.cn/manual/thinkphp5/118003)、[TP3.2 Doc](https://www.kancloud.cn/manual/thinkphp/1773)

### 入门常见问题

- 入口文件默认是 `/public/index.php`，如果修改该成 `index.php` 可参考：https://www.kancloud.cn/manual/thinkphp5/125729
- 控制器及子目录访问
    - 访问`http://localhost/myproject/index.php`，由于thinkphp设置了默认模块/控制器/方法，因此等同于访问 `http://localhost/myproject/index.php/index/index/index.html`。访问的是`application/index/controller/Index.php`文件的`index`方法。原则`index.php/模块名/控制器/方法名`(默认不区分大小写)
    - 访问`http://localhost/myproject/index.php/wap/login.index/test.html`实际是访问的`application/wap/controller/login/Index.php`文件的`index`方法。此时`wap`为模块名，在`wap/controller`有文件`login/Index.php`为控制器(路径为login.index，注意Index.php中的命名空间`namespace app\wap\controller\login;`)，访问的此文件中的test方法
- 控制器的方法中，`return`只能返回字符串，如果需要返回对象或数组需要使用`return json($obj)`
- 获取参数

    ```php
    $request = Request::instance();
    $method = $request->method(); // 获取上传方式
    $request->param(); // 获取所有参数，最全
    $get = $request->get(); // 获取get上传的内容
    $post = $request->post(); // 获取post上传的内容
    $request->file('file'); // 获取文件
    ```

### Model

```php
$pk = $model->getPk(); // 获取pk字段名
$fileds = $model->getQuery()->getTableInfo('', 'fields'); // 获取所有字段

// 判断是否更新成功(当未获取到数据会返回false)。如果使用`$model->update($data, ['id'=>1]);`未获取到数据也返回成功
$result = User::get('id=1')->save($data);
echo $result !== false ? 'success' : 'false';

$Model = new \Think\Model() // 实例化一个model对象 没有对应任何数据表
$result = $Model->query("select u.* from user u left join room r on u.room_id = r.id where r.id = 1");
```

- 事物: 事物操作相关代码在`use think\db\Connection;`中

```php
// 启动事务
Db::startTrans();
try{
    Db::table('think_user')->find(1);
    Db::table('think_user')->delete(1);
    // 提交事务
    Db::commit();    
} catch (\Exception $e) {
    // 回滚事务
    Db::rollback();
}
```

## 易错点

- `$_POST`接受数据 [^1]
    - Coentent-Type仅在取值为`application/x-www-data-urlencoded`和`multipart/form-data`两种情况下，PHP才会将http请求数据包中相应的数据填入全局变量`$_POST`。(jquery会默认转换请求头)
    - Coentent-Type为`application/json`时，可以使用`$input = file_get_contents('php://input')`接受数据，再通过`json_decode($input, TRUE)`转换成json对象
    - 微信小程序wx.request的header设置成`application/x-www-data-urlencoded`时`$_POST`也接受失败(基础库版本1.5.0，仅供个人参考)，使用file_get_contents('php://input')可以获取成功
- 空值判断
    
    ```php
    // 判断stdClass是否有某个属性
    $json = json_decode($json_str); // 格式化json字符串为对象。返回的是stdClass
    if(isset($json -> username)) {
        // 判断 $json 对象中是否有username属性.
        // ($json -> username == null)、(is_null(($json -> username))) 都会报错。特别当$json可能为空时
    }

    // 判断数组是否有某个索引
    if(isset($_POST['id'])) {}
    ```

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

## xampp + PhpStorm

- xampp是将php、perl、apache、mysql、tomcat、FileZila等软件打包打一起
    - 安装[xampp](https://jaist.dl.sourceforge.net/project/xampp/XAMPP%20Windows/7.3.10/xampp-windows-x64-7.3.10-1-VC15-installer.exe)
    - 也支持linux
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
    - 设置Xdebug
        - `php.exe -m` 查看是否安装Xdebug(`[Zend Modules]`中含有`Xdebug`)
        - 修改`php.ini`，加入

            ```ini
            [xdebug]
            zend_extension=D:\software\xampp\php\ext\php_xdebug.dll
            xdebug.remote_enable=1
            ```
- Chrome插件`Xdebug Helper for Chrome`
    - 激活Xdebug的调试器
    - 安装好后点击插件中的Debug按钮启动
- PhpStorm 配置。参考[http://blog.aezo.cn/2016/09/17/extend/idea/](/_posts/extend/idea.md#IDEA开发PHP程序)
    - 使用前需配置php可执行程序路径(Languages - PHP). 如果使用xampp，则可使用xampp中配置的xdebug
    - 进行debug时，创建一个`PHP Web Page`启动配置，此时host和port需要填Apache服务器的host和port(PhpStorm中的启动配置并不会启动服务器，因此需要另外启动Apache等服务器)
        - Run Debug - PHP Web Page - 新建Server(localhost:8110, Xdebug) - Start Url(/test/index.php) - 启动Debug - 访问 http://localhost:8110/test/index.php
    - PHPStorm使用Xdebug进行调试时，没打断点也一直进入到代码第一行：去掉勾选Run - Break at first line in PHP Scripts
    - PHPStorm需要启动Debug监听：`Run - Start Listening for PHP Debug Connection`

## lnmp 类似xampp，专注于linux环境

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
