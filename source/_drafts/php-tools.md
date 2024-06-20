---
layout: "post"
title: "PHP相关框架"
date: "2022-11-18 19:10"
categories: arch
---

## laravel

### 简介

- [laravel](https://laravel.com/)
    - 为 Web 开源框架，采用了 MVC 的架构模式
    - [laravel中文教程](https://learnku.com/laravel/wikis)
    - laravel依赖了[symfony](https://symfony.com/)框架(如Artisan命令)，[中文教程](http://symfony.p2hp.com/)
- [laravel-admin后端管理框架](https://laravel-admin.org/)
- `Dcat Admin`基于laravel-admin进行开发
    - [中文文档](https://learnku.com/docs/dcat-admin/2.x)
- 包名为`Illuminate\*`，静态方法对应工具类一般在`Illuminate\Support\Facades`目录
    - 如导入日志工具类`use Illuminate\Support\Facades\Log;`，然后使用`Log::debug('日志会记录在/storage/logs/laravel.log');`，日志相关配置可参考：https://learnku.com/laravel/wikis/25652
- Artisan 命令：https://learnku.com/laravel/wikis/25711
    - `php artisan list` 其实执行的是项目根目录artisan文件(为php文件，省略了后缀)
    - 基于symfony实现

### 路由

- RESTful接口: https://blog.csdn.net/qq_44718170/article/details/108105573
- 路由使用

```php
// RESTful接口
Route::namespace('Api')->group(function () {
    // 调用/api/create-order
    Route::match(['get', 'post'], '/create-order', 'EpayController@createOrder');
});
```
- 获取请求参数

```php
$request->all(); // 获取所有参数
$request->input('key'); // 获取某个参数
```

### 数据查询

```php
// class Order extends Illuminate\Database\Eloquent\Model;
$order = Order::query()
            ->with(['goods']) // 关联查询
            ->where('order_sn', $orderSN)
            ->first(); // 如果没有返回null

$users = DB::table('users')
            ->where('sex', 1)
            ->where('name', 'like', '%john%')
            ->get();
```

### 服务

```php
// 方法中可使用如下方式获取服务对象，类似SpringU
app('Service\OrderService')
```

- Laravel中定时任务使用：https://blog.csdn.net/cookcyq__/article/details/123142516
    - Laravel 提供了 redis、database、sync、等队列容器供我们存储，默认是 database ，表示将这些任务放到数据库里面
    - `php artisan make:job SendEmailJob` 创建任务，此命令会在 App\Jobs\下生成 SendEmailJob.php 文件，逻辑处理在`handle`方法中
    - `php artisan queue:table`和`php artisan migrate`会自动在 App/database/migrations/ 下创建数据库脚本文件
    - 往队列中添加任务
        - `SendEmailJob::dispatch($order->email);` 调用继承的dispatch方法，参数为SendEmailJob的构造函数所需参数
    - `php artisan queue:work` 启动任务处理进程(会一直监听是否有任务)
        - 如果执行失败会尝试再次触发，在`failed_jobs`表中可查看执行失败的任务
    - 在 Laravel 中，队列 Job 的处理会被缓存起来，以提高处理速度，**如果修改了代码需要重启任务队列** `php artisan queue:restart`

### Blade模板

-  [Laravel Blade 模板](https://learnku.com/docs/laravel/9.x/blade/12216)
    - 上下文的顶级变量可直接通过$进行取值；如果需要通过变量取另外一个变量值，可利用内置变量`$__data`，及`{{ $__date[$key] }}`，**可通过`@dd($__data)`打印整个上下文信息**
```php
// 打印整个上下文
@dd($__data)

// 默认情况下，Blade {{ }} 语句将被 PHP 的 htmlspecialchars 函数自动转义以防范 XSS 攻击。如果不想您的数据被转义，那么您可使用如下的语法
{!!  !!}
```

### 日志

```php
try {
    // 代码逻辑
    Log::info('日志');
} catch (\Exception $e) {
    Log::error($e->getMessage());
    Log::error('创建订单出错: ' . $e->getMessage() . '. 堆栈: ' . $e->getTraceAsString()); // 推荐，换行打印堆栈
}
```

## swoole高并发扩展

- https://www.swoole.com/

## xunruicms

- 安装

```bash
# http://localhost/test.php

# 设置读写权限: http://help.xunruicms.com/380.html
chmod 777 -R cache
chmod 777 -R public/uploadfile
chmod 777 -R config

# 需支持后台管理界面编辑模板时需要
chmod 777 -R template
chmod 777 -R public/static
# 上传会员头像时需要
chmod 777 -R public/api/member

# php_zip模块安装，参考[php-zip模块安装](/_posts/lang/php.md#php-zip模块安装)
```
- 开发期间(如在管理后台安装插件)

```bash
chmod 777 -R dayrui/App

# 安装时可先查看插件的文件结构，从而设置对应目录权限。如官方内容系统插件，还需设置以下目录
'''
chmod 777 -R dayrui/Fcms
chmod 777 -R dayrui/My
chmod 777 -R public/mobile
'''

# 安装完成(线上环境还原目录权限)
chmod 755 -R dayrui/App
```



