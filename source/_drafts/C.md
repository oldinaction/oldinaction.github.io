---
layout: "post"
title: "C"
date: "2019-10-13 18:18"
categories: lang
tags: [C, C++]
---

## 简介

- `POSIX`(Portable Operating System Interface) 可移植操作系统接口：是IEEE为要在各种UNIX操作系统上运行软件，而定义API的一系列互相关联的标准的总称。基于此接口的程序可移植性强，微软的Windows也在往此接口靠近(相反可看出C语言同样的源代码在不同操作系统运行的结果可能不一样)
- 汇编简介
    - `I386`(32位)汇编简介

        ```bash
        mov eax, 10 # 将10放到eax寄存器中
        add eax, 10 # 将寄存器中的值和10相加
        ```
    - VS反汇编：F9设置一个断点，F5以调试方式运行代码，然后在调试-窗口-反汇编中查看
- 计算机知识
    - 计算机内存分为`内核区域`和`用户区域`。操作系统运行在内存区域，普通程序运行在内核区域。32位操作系统，最大内存为4G，操作系统占用1G，剩下的3G给用户程序
    - CPU包含了`控制器`、`运算器`、`寄存器`。寄存器决定了CPU的位数
    - 寄存器取名：al、ah、bl、bh、cl、ch等代表8位的寄存器(8位的寄存器只能计算2^8=255内的数据，32位同理)；ax(al+ah)、bx、cx、dx等代表16位寄存器；eax、ebx、ecx、edx等代表32位寄存器；reax、rebx、recx、redx等位64位寄存器
    - CPU架构
        - `RISC`与`CISC`：`RISC`为精简指令集，`CISC`为复杂指令集
        - x86为CISC复杂指令集，包括AMD和inter生产的CPU都是x84架构；ARM为RISC精简指令集；`SPARC`为Sun公司的CPU，也为RISC精简指令集

### 环境配置

- 简单的方式如安装`gcc`编译器即可编译C/C++。通过超文本编辑器编写源码后进行编译运行
- CLion编辑器配置编译环境
    - Setting - Build - Toolchains - 设置[MinGW](http://mingw-w64.org/doku.php)(可点击配置的Download下载后安装)
    - 设置MinGW可能会报错`For MinGW make to work correctly sh.exe must NOT be in your path.`，此时只需在Setting - Build - CMake - CMake options添加`-DCMAKE_SH="CMAKE_SH-NOTFOUND"`即可(提示可能还是存在，但不用考虑)

### GCC编译器

- C语言编译过程：.c文件源码 -> 预编译 -> 编译 -> 链接(将语言库和编译后的二进制文件进行链接打包) -> 可执行程序
- gcc使用

```bash
gcc -v
gcc --help

gcc hello.c # 编译 hello.c 源文件。如果在windows系统则会生成 a.exe 的可执行文件，如果在linux系统则会生成 a.out 的可执行文件
gcc -o hello hello.c # -o 指定编译后的可执行文件名
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


