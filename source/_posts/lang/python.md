---
layout: "post"
title: "python"
date: "2017-04-28 11:39"
categories: [lang]
tags: [python]
---

## python简介

- python有两个版本python2(最新的为python2.7)和python3，两个大版本同时在维护
- Linux下默认有python环境

## python基础(易混淆/常用)

### 基本语法

#### 变量
    
- 命名同java(区分大小写) 
- 变量无需声明类型：如`name='smalle'，name=123`
- `print(name)` 打印变量(python2语法为`print name`)
- `del name` 变量销毁
- `id(a), id(b), id(c)` 查看a、b、c三个变量的内存地址(0-255的数字python会做优化：`a=1、b=a、c=1`此时内存地址一致)

#### 数据类型

- 数据类型
    - 数字类型：整型(布尔bool、长整型L、标准整型int)、浮点型(floot)、序列(字符串str、元组tuple、列表list)、映像类型(字典dict)、集合(可变set、不可变集合frozenset)
    - `a = True`(注意`True/False`首字母大写)
    - `type(a)` 查看a的数据类型
    - `a = '10'; int(a);` 强转成整形(floot、bool、str同理)
- 列表

```python
list = ["smalle", "aezocn", 18, "smalle", "hello"] # 定义数组
print(list) # 打印["smalle", "aezocn", 18, "smalle", "hello"]
print len(list) # 返回list的大小

list[0] # ['smalle']
list[0:3] # ['smalle', 'aezocn', 18]（索引左闭右开）。同 print(list[:3])，省略则为0
list[1:-2] # ['aezocn', 18]，-1为hello，-2为smalle，不包含-2
list[-3:-1] # [18, 'smalle']

# 操作列表的方法
list.remove('smalle') # 移除'smalle'，一次只能删除一个元素，且从左往右开始删除
list.append('world') # 往最后添加一个元素
list.insert(2, 'index2') # 在索引为2处添加元素
list.pop() # 删除list最后一个元素
list.pop(1) # 删除索引为1的元素

list.count('smalle') # 获取集合中smalle的个数
list.index('smalle') # 获取'smalle'第一次出现的下标 

list.sort() # 从小到大排序
list.reverse() # 将此列表反转（不会进行排序）
```

- 字典

```python
map = {'name': 'smalle', "age": 18} # 定义
print(map) # {'name': 'smalle', "age": 18}
map['name'] # smalle

# 循环
for key in map:
    print(key, map[key])

for key, value in map.items():
    print(key, value)
```

- 元组：和列表很类似(元组定义了之后值不能改变)

```python
my_tuple = ('1', 2, 'smalle') # ('1',)
print type(my_tuple) # <type 'tuple'>
print my_tuple.index('smalle') # 2。获取smalle的索引

# 如果元组里面只有一个元素，数据类型为此元素的数据类型
my_tuple = ('1') # '1'
print type(my_tuple) # <type 'str'>
```

#### 运算

- `2**32` 幂：为2的32次方
- `10 % 3` 取余
- `10 / 3 = 3; 10 // 3 = 3` ???

#### 编程风格

- 使用缩进进行语句层级控制，不像java等语言的`{}`
- 每一行代表一个语句，语句结尾以分号`;`结束，也可省略此分号
- 单引号/双引号效果一样，都可表示字符串；三个单引号/双引号可表示多行
    - `name = 'smalle'; age = 18; print 'name: %s, age: %s' % (name, age);` 引号中的变量替换(如果只有一个变量可以省略括号，如果是数值也可以换成`%d`，`%.2f`表示浮点型保存两位小数)
- `#` 注释
- `,`或`+`为字符串连接符

### 流程控制

```python
# if语句
if name == 'smalle':
    print "hi"
elif age > 18:
    print "old"
else:
    print "error"

# while循环
while count > 3:
    # ...
    break
else:
    print "此else语句可选"

# for循环
for i in range(10): # range返回一个列表: [0, 1, ..., 9]; range(0, 10, 2)返回0-10(不包含是10)，且步长为2的数据：[0, 2, 4, 6, 8]
    print i

```


### 其他

```python
# 1
print id(a) # 返回变量a的地址
print type(a) # 返回变量a的类型
print len(a) # 获取变量a的长度
print "smalle ".strip() # 去除空格
print "10".isdigit() == True # 判断是为整数
print ord('1') # 返回ascii码，此时为49

# 2
name = raw_input("please input name:") # 获取输入源（获取数据默认都是字符串）
print 'name:', name # 打印 "name: smalle"

# 3
import random # 导入random模块
num = random.randrange(10) # 获取0-9的随机整数(不包含10)
```

## 模块

1. 模块安装
    - 可在`/Scripts`和`/Lib/site-packages`中查看可执行文件和模块源码
2. 常用模块
    - `pip` 可用于安装管理python其他模块
        - 安装（windows默认已经安装）
            - 将`https://bootstrap.pypa.io/get-pip.py`中的内容保存到本地`get-pip.py`文件中
            - 上传`get-pip.py`至服务器，并设置为可执行
            - `python get-pip.py` 安装
            - 检查是否安装成功：`pip list` 可查看已经被管理的模块
        - 常见问题
            - 安装成功后，使用`pip list`仍然报错。windows执行`where pip`查看那些目录有pip程序，如strawberry(perl语言相关)目录也存在pip.exe，一种方法是将strawberry卸载
    - `ConfigParser` 配置文件读取(该模块ConfigParser在Python3中，已更名为configparser)
        - `pip install ConfigParser`
        - 介绍：http://www.cnblogs.com/snifferhu/p/4368904.html
    - `MySQLdb` mysql操作库
        - `pip install MySQL-python`
            > 报错`win8下 pip安装mysql报错_mysql.c(42) : fatal error C1083: Cannot open include file: ‘config-win.h’: No such file or director`。解决办法：安装[MySQL-python-1.2.5.win32-py2.7.exe](https://pypi.python.org/pypi/MySQL-python/1.2.5)（就相当于pip安装）
            
        - 工具类：http://www.cnblogs.com/snifferhu/p/4369184.html
    - `pymongo` MongoDB操作库 [^2]
        - `pip install pymongo`
    - `fabric` 主要在python自动化运维中使用(能自动登录其他服务器进行各种操作)
        - `pip install fabric` 安装
        - 常见问题
            - 报错`fatal error: Python.h: No such file or directory`
                - 安装`yum install python-devel` 安装python-devel(或者`yum install python-devel3`)
            - 报错` fatal error: ffi.h: No such file or directory`
                - `yum install libffi libffi-devel` 安装libffi libffi-devel
    - `scrapy` 主要用在python爬虫。可以css的形式方便的获取html的节点数据
        - `pip install scrapy` 安装
        - 文档：[0.24-Zh](http://scrapy-chs.readthedocs.io/zh_CN/0.24/index.html)、[latest-En](https://doc.scrapy.org/en/latest/index.html)


---
[^1]: [MySQLdb安装报错](http://blog.csdn.net/bijiaoshenqi/article/details/44758055)
[^2]: [Python连接MongoDB操作](http://www.yiibai.com/mongodb/mongodb_python.html)