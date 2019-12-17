---
layout: "post"
title: "Python"
date: "2017-04-28 11:39"
categories: [lang]
tags: [python]
---

## python简介

- python有两个版本python2(最新的为python2.7)和python3，两个大版本同时在维护
- Linux下默认有python2环境，python3安装参考[《CentOS服务器使用说明#python3安装》](/_posts/linux/CentOS服务器使用说明.md)
- [python3-cookbook中文文档](https://python3-cookbook.readthedocs.io/zh_CN/latest/index.html)
- 一般服务会自带pip，没有可进行安装

```bash
sudo yum -y install epel-release
sudo yum -y install python-pip
```

## python2和python3的语法区别

```python
## print打印
print name # 2
print(name) # 3

## 捕获异常
# 2
try
    # ...
except Exception, e:
    # ...
# 3
try
    # ...
except Exception as e:
    # ...

```

## python基础(易混淆/常用)

### 基本语法

#### 符号/关键字

- `# xxx`、`"""xxx"""`、`'''xxx'''` 均可进行注释
- 使用缩进进行语句层级控制，不像java等语言的`{}`
- 每一行代表一个语句，语句结尾以分号`;`结束，也可省略此分号
- 单引号('')/双引号("")效果一样，都可表示字符串；三个单引号('''''')/双引号("""""")可表示多行
    - `name = 'smalle'; age = 18; print 'name: %s, age: %s' % (name, age);` 引号中的变量替换(如果只有一个变量可以省略括号，如果是数值也可以换成`%d`，`%.2f`表示浮点型保存两位小数)
- `,`或`+`为字符串连接符

#### 编程风格

- 在python中 `None`, `False`, `空字符串""`, `0`, `空列表[]`, `空字典{}`, `空元组()`都相当于`False`

#### 变量
    
- 命名同java(区分大小写)
- 变量无需声明类型：如`name='smalle'，name=123`
- `print(name)` 打印变量(python2语法为`print name`)
    - `print(name, password)` 打印多个变量，中间默认用空格分割
- `del name` 变量销毁
- `id(a), id(b), id(c)` 查看a、b、c三个变量的内存地址(0-255的数字python会做优化：`a=1、b=a、c=1`此时内存地址一致)

#### 运算

```py
# 幂：为2的32次方
2**32
# 取余
10 % 3  # 1
# 除法
10 / 3  # 3.3333333333333335
10 // 3  # 3

# 类似三元运算。如果a>b则t=a，否则t=b
t = a if a>b else b
```

### 数据类型

- 数据类型
    - 数字类型：整型(布尔bool、长整型L、标准整型int)、浮点型(floot)、序列(字符串str、元组tuple、列表list)、映像类型(字典dict)、集合(可变set、不可变集合frozenset)
    - `a = True`(注意`True/False`首字母大写)
    - `type(a)` 查看a的数据类型
    - `a = '10'; int(a);` 强转成整形(floot、bool、str同理)

#### 字符串

```py
print('变量值为：{}'.format(my_var))

# 字符串与变量连接
search_url = f'https://www.baidu.com?wd={my_search_str}'
search_url = 'https://www.baidu.com?wd=' + my_search_str

# 字符不能直接和其他类型拼接
step=1
print("step="+str(step+1))  # 需要通过str进行转换才可拼接
```

#### 列表

```python
list = ["smalle", "aezocn", 18, "smalle", "hello"] # 定义数组
list2 = [user.username for user in users]  # 基于运算创建数据
print(list) # 打印["smalle", "aezocn", 18, "smalle", "hello"]
print(len(list)) # 返回list的大小

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

# 循环(元组同理)
for item in list:
    print(itme)
```

#### 元组

- 和列表很类似(**区别在于元组定义了之后值不能改变**)

```python
my_tuple = ('1', 2, 'smalle') # ('1',)
print(type(my_tuple)) # <type 'tuple'>
print(my_tuple.index('smalle')) # 2。获取smalle的索引

# 如果元组里面只有一个元素，数据类型为此元素的数据类型
my_tuple = ('1') # '1'
print(type(my_tuple)) # <type 'str'>
```

#### 字典

```python
map = {'name': 'smalle', "age": 18} # 定义
print(map) # {'name': 'smalle', "age": 18}
map['name'] # smalle。取值，字典取值不能通过.获取
map['sex'] = 1 # 新增key

# 函数
len(map)  # 计算元素个数
map.get('name', b'') # 取值，map.get(key, default=None)。返回指定键的值，如果值不在字典中返回default值
map.pop('name', '-NA-')  # 删除元素。删除字典给定键 key 所对应的值，返回值为被删除的值，如果给的键不存在，否则返回默认值-NA-(可选，否则不存在对应key则会报错)
'name' in map # 判断key是否存在。返回 True/False
dict1.update(dict2)  # 把字典dict2的键/值对更新(合并)到dict1里

# 循环
for key in map:
    print(key, map[key])

# 同理有 map.keys()、map.values()
for key, value in map.items():
    print(key, value)

## 防止取值报错的两种方式
if a.get('age'):
    print a['age']
if 'age' in a.keys(): # a.has_key('age')
    print a['age']
```

#### JSON转换

```py
import json

## 字符串转为JSON
str = '''
[{"name":"Smalle"}]
'''
data = json.loads(str)
print(data[0]['name']) # Smalle 无此字段时会报 KeyError 错误

## 对象转JSON字符串
str = json.dumps(data)  # data为字典类型
print(str) # [{"name": "Smalle"}]

## 保存到json格式文件
with open('data.json', 'w', encoding='utf-8') as file:
    file.write(json.dumps(data, indent=2, ensure_ascii=False)) # indent=2按照缩进格式，ensure_ascii=False可以消除json包含中文的乱码问题
```

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

### 函数

- 函数传递参数的方式有两种：位置参数(positional argument，包含默认参数)、关键词参数(keyword argument)
- `*args` 和 `**kwargs`：主要将不定数量的参数传递给一个函数。两者都是python中的可变参数
    - `*args`表示任何多个无名参数，它本质是一个tuple
    - `**kwargs`表示关键字参数，它本质上是一个dict
    - 如果同时使用`*args`和*`*kwargs`时，必须`*args`参数列要在`**kwargs`前。调用如`MyObj(**{name: 'smalle'})`为kwargs的传入
    - 其实并不是必须写成`*args`和`**kwargs`，**`*`和`**`才是必须的**。也可以写成`*ar`和`**k`。而写成`*args`和`**kwargs`只是一个通俗的命名约定
- 访问级别(python中无public、protected、private等关键字)
    - `public` 方法和属性命名不以下划线开头
    - `protected` 方法和属性命名以下划线(`_`)开头
    - `private` 方法和属性命名以双下划线(`__`)开头
        - 访问私有方法或属性：`myobj._MyObj__func()`，如果使用`myobj.__func()`则不行

### 面向对象

- 经典类、新式类
    - Python 2.x中默认都是经典类，只有显式继承了object才是新式类
    - Python 3.x中默认都是新式类，不必显式的继承object
- python支持多继承
    - 经典类采用深度优先搜索属性/方法
    - 新式类采用广度优先搜索属性/方法
- 类定义

```py
class Employee:
    '所有员工的基类'
    empCount = 0  # 是一个类变量，它的值将在这个类的所有实例之间共享。可以在内部类或外部类使用 Employee.empCount 访问

    # __init__()方法是一种特殊的方法，为类的构造函数，当创建了这个类的实例时就会调用该方法
    def __init__(self, name):
        self.name = name
        Employee.empCount += 1

    # self 代表类的实例，self 在定义类的方法时是必须的(且是第一个参数)，调用时可不必传入此参数
    def displayCount(self):
        print "Total Employee %d" % Employee.empCount

    def displayEmployee(self):
        print "Name : ", self.name
    
    def prt(self):
        print(self)
        print(self.__class__)

if __name__ == "__main__":
    e = Employee("smalle")  # 实例化对象
    '''打印结果
    <__main__.Employee instance at 0x10d066878>
    __main__.Employee
    '''
    t.prt()  # 调用对象方法
```

### 流/文件 [^3]

- 创建临时文件和文件夹相关库[tempfile](#tempfile)

```py
## 获取控制台输入
i = input('请确认是否继续操作？[y/n]:')
    if (i != 'n'):
        return
```

#### 文件

- 文件描述符
    - `r` 读取模式
    - `w` 写入。如果文件存在则直接覆盖掉
    - `a` 追加
    - `t` 文本模式
    - `b` 二进制模式
    - `x` 模式在文件写入时，如果文件存在就报错。多个模式可使用如 `wb` 或 `w+b`
- 读写文件

```py
## 读取文件
# 一次读取
with open('file.txt', 'r') as f:
    print(f.read())
# 逐行读取
with open("file.txt") as lines:
    for line in lines:
        print(line)

## 写入文件
# w方式写入时的'\n'会在被系统自动替换为'\r\n'，wb则不会(如果本身是'\r\n'则写入仍然是'\r\n')；r方式读时，文件中的'\r\n'会被系统替换为'\n'
f = open('d:/test.sh', 'wb')
f.write(str.encode("utf-8"))  # 防止中文乱码
f.close()  # 此时文件才会真正被写入到磁盘

# 推荐方式
import os
if not os.path.exists('somefile'):
    with open('somefile', 'wt') as f:
        f.write('Hello\n')
    else:
        print('File already exists!')
```
- 文件路径处理、文件是否存在判断(os.path)

```py
import os

## 路径处理
path = '/home/smalle/temp/dir/test.txt'
os.path.basename(path)  # 'test.txt' 获取文件名
os.path.dirname(path)  # '/home/smalle/temp/dir' 获取路径名
os.path.join('tmp', 'data', os.path.basename(path))  # 'tmp/data/test.txt'

path = '~/test/hello.txt'
os.path.expanduser(path)  # '/home/smalle/test/hello.txt' 添加用户家目录
os.path.splitext(path)  # ('~/test/hello', '.txt') 分割文件名和扩展

## 路径信息获取
os.path.exists('/etc/passwd')  # True
os.path.exists('/tmp/hhhh')  # False
os.path.isfile('/etc/passwd')  # True
os.path.isdir('/etc/passwd')  # False
os.path.islink('/usr/local/bin/python3')  # True 是否为快捷方式(链接)
os.path.realpath('/usr/local/bin/python3')  # '/usr/local/bin/python3.3' 获取文件链接的目标路径
os.path.getsize('/etc/passwd')  # 3812 获取文件大小
os.path.getmtime('/etc/passwd')  # 1272478234.0 获取文件修改时间
# import time
# time.ctime(os.path.getmtime('/etc/passwd')) # 'Wed Apr 28 13:10:34 2010'

## 获取目录下文件
names = os.listdir('somedir')  # 返回目录中所有文件列表，包括所有文件，子目录，符号链接等等
# Get all regular files
names = [name for name in os.listdir('somedir')
        if os.path.isfile(os.path.join('somedir', name))]
# Get all dirs
dirnames = [name for name in os.listdir('somedir')
        if os.path.isdir(os.path.join('somedir', name))]
# startswith() 和 endswith() 过滤
pyfiles = [name for name in os.listdir('somedir')
        if name.endswith('.py')]
# 对于文件名的匹配，可使用 glob 或 fnmatch 模块
import glob
pyfiles = glob.glob('somedir/*.py')

from fnmatch import fnmatch
pyfiles = [name for name in os.listdir('somedir')
        if fnmatch(name, '*.py')]
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

### 内置模块

#### time

```py
import time

time.localtime() # time.struct_time(tm_year=2019, tm_mon=10, tm_mday=25, tm_hour=16, tm_min=0, tm_sec=50, tm_wday=4, tm_yday=298, tm_isdst=0)
# 格式化成2016-03-20 11:45:39形式
print time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) 

print (time.time())                       #原始时间数据，1499825149.257892
print (int(time.time()))                  #秒级时间戳，1499825149
print (int(round(time.time() * 1000)))    #毫秒级时间戳，1499825149257
print (int(round(time.time() * 1000000))) #微秒级时间戳，1499825149257892
```

#### tempfile

- 通过 TemporaryFile, NamedTemporaryFile, TemporaryDirectory 创建文件或目录，使用完成后会自动清理
- `gettempdir()` 获取临时文件目录

```py
from tempfile import TemporaryFile, NamedTemporaryFile, TemporaryDirectory, gettempdir

## TemporaryFile
# 方式一：使用with，当退出with则文件会自动销毁。通常文本模式使用 w+t ，二进制模式使用 w+b
# with TemporaryFile('w+t', prefix='mytext', suffix='.txt', dir='/tmp', encoding='utf-8', errors='ignore') as f:  # /tmp/mytext5ff221.txt
with TemporaryFile('w+t') as f:
    f.write('Hello World\n')
    f.write('你好\n')

    # 将文件位置设置到起始位置进行读取文件
    f.seek(0)
    data = f.read()

# 方法二：文件在close后会自动销毁
f = TemporaryFile('w+t')
f.write('Hello World\n')
f.close()

## NamedTemporaryFile
# 在大多数Unix系统上，通过 TemporaryFile() 创建的文件都是匿名的，甚至连目录都没有。但是 NamedTemporaryFile() 却存在
with NamedTemporaryFile('w+t') as f:
# with NamedTemporaryFile('w+t', delete=False) as f: # 和 TemporaryFile() 一样，结果文件关闭时会被自动删除掉。此时设置 delete=False，则不会自动删除
    print('filename is:', f.name)


## TemporaryDirectory
with TemporaryDirectory() as dirname:
    print('dirname is:', dirname)

## gettempdir()
gettempdir()
```

### 模块扩展

#### pip镜像及模块安装

- pip镜像

```bash
# 镜像地址
# 清华 https://pypi.tuna.tsinghua.edu.cn/simple
# 官方 https://pypi.python.org/simple
# 阿里云 https://mirrors.aliyun.com/pypi/simple
# 豆瓣 http://pypi.douban.com/simple/

# Linux下，修改 ~/.pip/pip.conf (没有就创建一个)， 修改 index-url至tuna，内容如下：
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple

# windows下，直接在user目录中创建一个pip目录，如：C:\Users\xx\pip，新建文件pip.ini，内容如下:
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
```
- 模块安装
    - `pip install xxx` [pip](https://pypi.org/)
        - python3也可以使用`pip3 install xxx`
        - `pip install Django==2.0.6` 安装指定版本
        - `pip install xxx -i http://pypi.douban.com/simple/` 指定数据源
    - `pip install xxx.whl` [whl](https://www.lfd.uci.edu/~gohlke/pythonlibs/)
    - `pip list` 列举安装的模块
        - 可在`/Scripts`和`/Lib/site-packages`中查看可执行文件和模块源码
    - `pip uninstall xxx` 卸载
- `pip` 可用于安装管理python其他模块
    - 安装（windows默认已经安装）
        - 将`https://bootstrap.pypa.io/get-pip.py`中的内容保存到本地`get-pip.py`文件中
        - 上传`get-pip.py`至服务器，并设置为可执行
        - `python get-pip.py` 安装
        - 检查是否安装成功：`pip list` 可查看已经被管理的模块
    - 常见问题
        - 安装成功后，使用`pip list`仍然报错。windows执行`where pip`查看那些目录有pip程序，如strawberry(perl语言相关)目录也存在pip.exe，一种方法是将strawberry卸载

#### ConfigParser 配置文件读取

- 该模块ConfigParser在Python3中，已更名为configparser
- `pip install ConfigParser`
- 介绍：http://www.cnblogs.com/snifferhu/p/4368904.html

#### mysql操作库

- `pip install MySQL-python`(MySQLdb只支持2.7)
    > 报错`win8下 pip安装mysql报错_mysql.c(42) : fatal error C1083: Cannot open include file: ‘config-win.h’: No such file or director`。解决办法：安装 [MySQL_python‑1.2.5‑cp27‑none‑win_amd64.whl](https://www.lfd.uci.edu/~gohlke/pythonlibs/#mysql-python) 或 `MySQL-python-1.2.5.win32-py2.7.exe`（就相当于pip安装）
    - 工具类：http://www.cnblogs.com/snifferhu/p/4369184.html
- `pip install pymysql`(3.6)
    - 工具类：https://www.cnblogs.com/bincoding/p/6789456.html
- `pip install mysqlclient-1.3.13-cp36-cp36m-win_amd64.whl` **推荐**

#### pymongo MongoDB操作库 [^2]

- `pip install pymongo`             

#### scrapy 爬虫框架

- 主要用在python爬虫。可以css的形式方便的获取html的节点数据
- `pip install scrapy` 安装
- 文档：[0.24-Zh](http://scrapy-chs.readthedocs.io/zh_CN/0.24/index.html)、[latest-En](https://doc.scrapy.org/en/latest/index.html)

#### paramiko/fabric/pexpect 自动化运维

- `paramiko` 模块是基于Python实现的SSH远程安全连接，用于SSH远程执行命令、文件传输等功能
- `fabric` 模块是在`paramiko`基础上又做了一层封装，操作起来更方便。主要用于多台主机批量执行任务
- `pexpect` 是一个用来启动子程序，并使用正则表达式对程序输出做出特定响应，以此实现与其自动交互的Python模块

##### fabric

- 主要在python自动化运维中使用(能自动登录其他服务器进行各种操作)
- `pip install fabric` 支持python2
- `pip install fabric3` 支持python3
- 常见问题
    - 报错`fatal error: Python.h: No such file or directory`
        - 安装`yum install python-devel` 安装python-devel(或者`yum install python-devel3`)
    - 报错` fatal error: ffi.h: No such file or directory`
        - `yum install libffi libffi-devel` 安装libffi libffi-devel

##### pexpect

- pexpect 是 Python 语言的类 Expect 实现。程序主要用于"人机对话"的模拟，如账号登录输入用户名和密码等情况
- `pip install pexpect` 安装
- 参考：https://www.jianshu.com/p/cfd163200d12

```py
# pexpect==4.6.0
import pexpect

# 登录，并指定目标机器编码
process = pexpect.spawn('ssh root@192.168.1.131', encoding='utf-8')
process.expect(['password:', 'continue connecting (yes/no)?'])
process.sendline('xxx')

# 发送命令
process.buffer = str('') # 清空缓冲区
process.sendline("ps aux | awk '{print $2}' | grep 16983 --color=none") # 发送命令(--color=none表示不返回颜色字符)
process.expect(['\[[^@\[]*@[^ ]* [^\]]*\]# ', '\[[^@\[]*@[^ ]* [^\]]*\]\$ ']) # 匹配字符 [root@VM_2_2_centos ~]# [root@VM_2_2_centos ~]$ 
print(process.before) # 缓冲区开始到匹配字符之前的所有数据(不包含匹配字符)
print(process.before.split('\r\n'))
print(process.after) # 匹配字符数据

# 人机交互
process.interact() # 将控制权交给用户(python命令行变成bash命令行)
exit # 退出交互界面

# 退出pexpect登录
process.close(force=True)
```

## 项目创建和发布

### 项目创建

#### PyCharm创建django项目

- PyCharm创建django项目
    - File - New Project - Django - D:\gitwork\smpython\A02_DjangoTest(项目名需为字母数字下划线) 
    - Project Interpreter - **New environment** - Location可以选择(如django项目共用一个虚拟环境) - **Inherit global不勾选**(表示不包含全局包，否则`pip freeze`会多出很多全局包)
    - More Setting - Application Name - smtest(不要取test，会和Django自带名称冲突)
- 创建后默认包含`(虚拟环境名，如venv)`虚拟环境(与系统环境隔离，但是默认会使用系统的Python官方库)。再PyCharm中创建一个Terminal创建创建也会有`venv`标识(默认打开的Terminal窗口没有)
- 在有`venv`的Terminal创建安装类库则不会对系统产生干扰
- 启动django项目添加参数：如执行 `python manage.py runserver --insecure` 中的 `--insecure` 可在 `Configuration` - `Additional options`中配置

### 发布

- **记录客户端依赖(基于venv环境)**：`pip freeze > requirements.txt` venv环境运行后会生成一个此项目依赖的类库列表文件(安装上述方法创建项目默认不包含Python官方库)
- 服务器

```bash
# python3 的 pip3
pip3 install virtualenv
# 在当前目录创建虚拟环境目录ENV(可自定义名称)
# 如果已经python2也安装了virtualenv，则需要指明python执行程序，如 `virtualenv -p python3 ENV`
virtualenv ENV
# 启用此环境，后续命令行前面出现（ENV）代表此时环境已切换。之后执行命令全部属于此环境
# 退出虚拟环境命令 `deactivate`(无需加ENV/bin/)
source ENV/bin/activate
# 复制项目代码到项目目录(不用包含原来的虚拟环境目录)
# 之后执行pip3/python3 等指令，相当于是在此环境中执行。如果当前环境是python3，则pip默认指向pip3
# 或者直接通过`/ENV/bin/python3`执行程序
pip3 install -r /opt/myproject/requirements.txt
# 此时看到依赖已安装
pip3 list
# 运行
python3 /opt/myproject/main.py
```
- 运行程序脚本如

```bash
# 或者 nohup /home/smalle/ENV/bin/python3 /home/smalle/pyproject/automonitor/manage.py runserver 0.0.0.0:10000 > console.log 2>&1 &
source /home/smalle/ENV/bin/activate
nohup python3 /home/smalle/pyproject/automonitor/manage.py runserver 0.0.0.0:10000 > console.log 2>&1 &
```


---

参考文章

[^1]: http://blog.csdn.net/bijiaoshenqi/article/details/44758055 (MySQLdb安装报错)
[^2]: http://www.yiibai.com/mongodb/mongodb_python.html (Python连接MongoDB操作)
[^3]: https://python3-cookbook.readthedocs.io/zh_CN/latest/chapters/p05_files_and_io.html


