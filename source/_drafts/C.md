---
layout: "post"
title: "C"
date: "2019-10-13 18:18"
categories: lang
tags: [C, C++, C#]
---

## 简介

- C语言是一个面向过程的语言，C++是面向对象的语言
- `POSIX`(Portable Operating System Interface) 可移植操作系统接口：是IEEE为要在各种UNIX操作系统上运行软件，而定义API的一系列互相关联的标准的总称。基于此接口的程序可移植性强，微软的Windows也在往此接口靠近(**从而可看出C语言同样的源代码在不同操作系统运行的结果可能不一样**)
- 汇编简介
    - `I386`(32位)汇编简介

        ```c
        mov eax, 10 // 将10放到eax寄存器中
        add eax, 10 // 将寄存器中的值和10相加
        ```
    - VS反汇编：F9设置一个断点，F5以调试方式运行代码，然后在调试-窗口-反汇编中查看
- 计算机知识
    - 计算机内存分为`内核区域`和`用户区域`。操作系统运行在内存区域，普通程序运行在内核区域。32位操作系统，最大内存为4G，操作系统占用1G，剩下的3G给用户程序
    - CPU包含了`控制器`、`运算器`、`寄存器`。寄存器决定了CPU的位数
    - 寄存器取名
        - al、ah、bl、bh、cl、ch等代表8位的寄存器(8位的寄存器只能计算2^8=255内的数据，32位同理)
        - ax(al+ah)、bx、cx、dx等代表16位寄存器
        - eax、ebx、ecx、edx等代表32位寄存器
        - reax、rebx、recx、redx等位64位寄存器
    - CPU架构
        - `RISC`与`CISC`：`RISC`为精简指令集，`CISC`为复杂指令集
        - x86为CISC复杂指令集，包括AMD和inter生产的CPU都是x84架构；ARM为RISC精简指令集；`SPARC`为Sun公司的CPU，也为RISC精简指令集

### 环境配置

- 简单的方式如安装`gcc`编译器即可编译C/C++。通过超文本编辑器编写源码后进行编译运行
- `VC++ 6.0`
- `Visual Studio`
- `Qt Designer/Creator`
- `CLion`编辑器配置编译环境
    - Setting - Build - Toolchains - 设置[MinGW](http://mingw-w64.org/doku.php)(MinGW为windows下的gcc，可点击配置的Download下载后安装)
    - 设置MinGW可能会报错`For MinGW make to work correctly sh.exe must NOT be in your path.`，此时只需在Setting - Build - CMake - CMake options添加`-DCMAKE_SH="CMAKE_SH-NOTFOUND"`即可(提示可能还是存在，但不用考虑)

### GCC编译器

- C语言编译过程
    -> .c文件源码
    -> 预编译(宏定义、头文件展开，条件编译，去掉注释)
    -> 编译(检查语法、将C语言转成汇编语言)
    -> 链接(将C语言依赖库链接到编译的二进制文件中)
    -> 可执行程序
- gcc使用

```bash
gcc -v
gcc --help

# 编译 hello.c 源文件。如果在windows系统则会生成 a.exe 的可执行文件，如果在linux系统则会生成 a.out 的可执行文件
gcc hello.c
# gcc -o hello hello.c # -o 指定编译后的可执行文件名

# 参数说明
gcc -E -o hello.e hello.c # -E 预编译源文件。预编译：可将include包含的头文件内容简单替换到C文件中，同时将代码中的注释部分去掉
gcc -S -o hello.s hello.c # -S 将C语言转为汇编语言
gcc -c -o hello.o hello.s # -c 将代码编译成二进制的机器指令
gcc -o hello hello.o # 将语言库和编译后的二进制文件进行链接打包
```

## 基本语法

### Hello World

- hello.c 运行：linux下 `gcc hello.c`编译，会生成 a.out 执行文件，`./a.out` 执行

```c
// 导入库文件(类似导包)
#include <stdio.h> // <> 表示导入C标准库文件(处于/usr/include目录)
// #include "my.h" // "" 表示自定义的库文件

// 只能有一个main函数，入口函数
void main() {
    printf("Hello World\n");

    system("ls"); // 执行系统程序或命令
    // system("start calc"); // 打开windows计算器(需要编译成exe文件才可打开)
}
```

### 关键字

- 数据类型
    - char	            1 字节	-128 到 127 或 0 到 255
    - int	            2 或 4 字节
    - short	            2 字节
    - long	            4 字节
    - float             4 字节
    - double            8 字节
    - long double       16 字节
    - signed	声明有符号类型变量或函数(可省略)
    - unsigned	声明无符号类型变量或函数
    - struct	声明结构体类型
    - union	    声明共用体类型
    - enum
    - void
    - int* int** (多级指针) void* (万能指针) 等: 指针类型
- 控制语句
    - if/else/switch/case/default/for/do/while/break/continue/goto(无条件跳转语句)/return
- 存储类
    - auto	    声明自动变量(一般可以省略)
    - const	    定义常量，如果一个变量被 const 修饰，那么它的值就不能再被改变
    - extern	声明变量(可省略)或函数
    - register	声明寄存器变量(建议型指令, 如果寄存器有位置则生效, 不建议使用)
    - static
- 其他
    - sizeof	计算数据类型或变量长度（即所占字节数）
    - typedef	用以给数据类型取别名
    - volatile	防止编译器优化代码; 告诉编译器此修饰的变量随时可能变化，每次使用需要从地址中读取值

### 数据类型

- 说明
    - 变量名区分大小写
    - 字母数字下划线，不能数字开头
- 案例

```c
// 定义常量
// 此方式在C语言中不安全，在C++中是安全的
const int MAX = 10;
// 推荐使用此方式
#define MAX 10;

// 字符串
char* ch5 = "hello world";
printf("%s\n", ch5); // hello world
// 必须要加\0, 否则%s输出时会一直在内存中找到\0才停止输出
char ch6[12] = "hello world\0";
printf("%s\n", ch6); // hello world
```
- printf输出一个字符串
    - 整型
        - `%d` 输出一个有符号10进制
        - `%ld` 长整型
        - `%u` 无符号10进制
        - `%o` 输出8进制
        - `%x` 输出16进制(传入10进制则会转成16进制进行输出), 使用小写字母标识
        - `%X` 使用大写字母标识16进制
    - 字符型
        - `%c` 输出字符。单引号为字符(char)
        - `%s` 输出字符串(遇到]\0则停止输出)。双引号为字符串(char *)
    - 浮点型
        - `%f` 输出float类型
        - `%.2f` 保留2位小数
        - `%lf` 输出double类型
    - 其他
        - `%p` 输出一个变量对应的内存地址编号(为一个无符号的16进制值整型数据). `printf("%p\n", &a)`
        - `%e` 以科学计数法打印
        - `%%` 输出一个%
        - `%5d` 整体占5位，不够的前面补空格
        - `%7.2f` 包括小数点整体占7，小数点2位，不够的前面补空格
        - `%5s` 输出字符串的前5个字符
- `scanf("%d", &d);` 获取输入数值保存到变量d中
- `getchar()` 从键盘中读取一个char
- `putchar(var_char)` 输出一个char
- `sizeof` 查看数据占用内存大小

```c
int a = 1;
unsigned int len1 = sizeof(a); // 4
int len2 = sizeof(int); // 4
```
- 数据存储方式: 计算机中数据存储的方式都是已补码的方式存储的
    - 统一了0的编码: 0(0000 0000)和-0(1000 0000)同一以0的方式存储
    - 参考[软考中级-数据表示](/_posts/linux/软考中级.md#数据表示)

### 运算符

- `*` 取值运算符/降维运算符, 格式为`*指正变量`
- `&` 取地址运算符, 格式为`&变量名`

### 字符串

- 参考[string.h](#string.h)
- 字符串输入输出参考[stdio.h](#stdio.h)
- 字符串转换int/float/long参考[stdlib.h](#stdlib.h)

```c++
// 常用初始化方式
char s1[] = "hello";
char * s2 = "hello";

// 字符串拼接
void my_append(char *a, char *b)
{
    // 字符串数组的数组名表示指向此字符串的首个元素的指针(比如s1指向a，对s1进行加一运算后，s1++表示下一个元素b，以此类推)
    // a是指针变量, 值为地址, a++为下一个地址, *a为指针变量中保存的地址(指针的值)对应的值(地址对应的值)
    while (*a != 0)
        a++;
    while ((*a++ = *b++) != 0)
        ;
}
char s1[10] = "abc", s2[10] = "def";
my_append(s1, s2);
printf("%s %s\n", s1, s2); // abcdef def
```

### 内存管理

- 内存模型
    - 代码区(code)
        - 只读、共享
        - 低地址
    - 数据区
        - 常量数据
        - 初始化数据区(data, 又叫静态区): 全局变量/静态变量
        - 未初始化数据区(bss区)
    - 堆区(heap)
        - 需要手动开辟(malloc)和手动释放(free)
        - 中间地址
    - 栈区(stack)
        - 大小为1M, 在Windows中可扩展到10M, 在Linux中可扩展到16M
        - 高地址
- 变量
    - 局部变量: 在函数内部定义的变量
        - 存储位置: 栈区
    - 全局变量: 在函数外部定义的变量
        - **作用域: 整个项目的所有文件, 如果需要在其他地方使用则必须声明**。如`extern int a;`, 此时才可以读取和修改
        - 声明周期: 从程序创建到程序销毁
        - 存储位置: 数据区
    - 静态局部变量
        - **只会初始化一次，可以多次赋值**
        - 作用域: 只能在函数内部使用
        - 声明周期: 和全局变量一样
        - 存储位置: 数据区
    - 静态全局变量
        - 作用域: **只能在本文件中使用，不能在其他文件中使用**
        - 存储位置: 数据区
    - 说明
        - 全局变量可以和局部变量重名，会采用就近原则；全局变量不能重名
        - 函数内部的代码块可以定义和函数中定义的变量重名
        - 如果局部变量只声明了(此时内存已开辟空间)，未初始化则值为乱码(为任意值); vs中会报错(其他编辑器可能不会报错)
        - 未初始化的全局变量/静态局部变量，数据保存在未初始化数据区(又叫bss区)，此时为默认值(int为0)
- 函数
    - 全局函数: 在所以文件中都可使用，只要声明了就能使用。所有的函数默认是全局的
    - 静态函数: 只能在本文件中使用
- 堆空间使用

### 其他

```c++
// 防止头文件重复引用
#pragma once

// 防止头文件重复引用方式二, #ifndef的方式受C/C++语言标准支持
#ifndef __SOMEFILE_H__
#define __SOMEFILE_H__
  // ... 定义语句
#endif
```

## 标准库

### stdio.h

```c
printf();
scanf();

// === 字符串相关
gets(); // 读取字符串
fgets(); // 从流中读取字符串
puts(); // 输出字符串
fputs(); // 将流中的字符串输出
```

### string.h

```c
// 获取字符串长度, 需要引入string.h
strlen(s1);
// 字符串拷贝, \0也会拷贝；成功返回dest字符串首地址，失败返回NULL；dest的长度必须大于src，否则报错
strcpy(char *dest, const char *src);
// 字符串有限拷贝，拷贝n个字符；不一定会拷贝到\0
strncpy(dest, src, size_t n);
// 将src的字符串拼接到dest的尾部, \0也会追加过去
strcat(char *dest, const char *src);
strncat(); // 拼接前n个字符
// 比较s1和s2的大小，比较的是ASCII码大小。相等返回0，大于0(说明s1大于s2，返回的是ASCII差值，不同操作系统结果值可能不同)
strcmp(const char *s1, const char *s2);
strncmp(); // 比较前n个字符
// 将格式化的数据结果放到str中
sprintf(char *str, const char *format, ...)
// 在一个字符串中查找一个字符，返回第一次出现c的位置(地址)
char *strchr(const char *str, int c);
// 字符串截取，会破坏源字符串：用\0替换分割标志位；返回分割字符串的首地址
char *strtok(char *str, const char *delim);

// 内存重置. 将s的内存区域的前n个字节以参数c(unsigned char, 0-255)填入; 返回s的首地址
void *memset(void *p, int c, size_t n);
// 拷贝src所指向的内存内容的前n个字节到dest所指的内存地址上
void *memcpy(void *dest, const void *src, size_t n);
```

### stdlib.h

```c
// === 字符串相关
// 字符串转int: 扫描nptr字符串，跳过空格字符，直到遇到数字或正负号才开始转换，而遇到非数字或\0则结束；失败返回0
int atoi(const char *nptr);
atof(); // 字符串转float
atol(); // 字符串转long

// === 操作内存堆区
// 开辟堆内存空间: n个字节大小
void *malloc(size_t n);
// 释放内存空间: 开辟和释放的地址必须一致, 一般不要改变开辟的指针p(容易出现无主指针, 导致内存无效占用)
void free(void *p);
```
