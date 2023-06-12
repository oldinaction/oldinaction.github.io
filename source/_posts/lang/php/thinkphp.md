---
layout: "post"
title: "ThinkPHP"
date: "2017-08-20 11:39"
categories: [lang]
tags: [php]
---

## ThinkPHP

> 未特殊说明，都是基于 ThinkPHP v5.0.24 进行记录

- [TP5 Doc](https://www.kancloud.cn/manual/thinkphp5/118003)、[TP3.2 Doc](https://www.kancloud.cn/manual/thinkphp/1773)

## 入门常见问题

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

## Model

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
