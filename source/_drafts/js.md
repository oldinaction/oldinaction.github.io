---
layout: "post"
title: "Javascript"
date: "2016-06-11 16:51"
categories: [web]
tags: [js]
---

## javaScript 介绍

> - 前端三大语言：HTML、CSS、JS
> - 专门设计网页交互的语言
> - 运行在javascript解释器中（浏览器中包含解释器）
> - 互联网第一大语言，JSer
> - javaScript 前身是 liveScript(Netscape,网景公司), 执行标准 ECMAScript (规定核心语法)
> - W3C: 推出 DOM 标准：专门操作 HTML 元素，CSS样式，事件的统一标准。（规定比较重要）
> - BOM标准：专门操作浏览器窗口的工具，无标准，由浏览器厂商自行实现
> - 最后Netscape倒闭，工程师成立 Mozilla 基金会，最后发布 FireFox（理念是符合标准）

 完整的 javaScript 语言由三部分组成：
- 核心（`ECMAScript`）
- 文档对象模型（`DOM`，Document Object Model）
- 浏览器对象模型（`BOM`，Browser Object Model）

javaScript 特点：
- 纯文本
- 解释执行（读一行执行一行，后面的覆盖前面的）
- 弱类型
- 基于对象

## javascript 知识点

### 基本知识

- 区分大小写
- 字符串必须用单双引号包裹，语句有无分号效果一样
- `//`单行注释，`/*  */`多行注释（注释也占网页流量，生产环境最好去掉）
- `console.log();` 可在控制台打印相关信息，对程序无影响（`alert();`弹框打印）
- `<script>`脚本中的错误，仅影响当前脚本块中出错位置之后的代码(之前的代码照常执行)；function中的错误，只有调用方法时才触发
- 引入js文件时，`<script>`不支持单标签。必须使用 `<script src=""></script>`
- 利用`debugger;`调试，或者找到相应的源码再打断点

> - chrome 的控制台（F12），按 Shift+Enter 可换行
> - nodejs 也可直接运行js文件，相当于解释器
> - 浏览器包含排版引擎和解释引擎。根据html标签决定使用什么引擎，`<script>`则找解释引擎
> - 事件：元素根据鼠标或者键盘的不同操作响应不同的交互行为。html的事件属性，如 ：onclick
> - 网页的显示最好在7秒内，`<script>`一般放在body最后，为了使DOM先加载完
> `var input = prompt("请输入数据");` // 用于收集用户输入数据的对话框

### 变量、数据类型、运算符

**base.html**

1. 使用`var`声明变量(一般驼峰)，**使用`const`定义常量** (一般大写)
2. 变量未赋值时，js默认赋值为undefined
3. js中新同名变量的空间会替换旧变量的空间
4. **`js是弱类型`** ：变量本身没有类型，只有变量中的值才有类型；一个变量可以反复保存不同类型的数据。
5. **`js数据类型`** ：包括原始数据类型和应用数据类型。原始数据类型(数据保存在变量本地, 栈中)：number(数字)、string、boolean、null、undefined(未定义)；引用数据类型(数据保存在堆中)：Object、Function、Number、String、Boolean、Data、Error等。利用 `typeof(X)` 可打印原始数据类型（返回string/number/boolean/object/function/undefined）；使用 `arr instanceof Array` 用于判断一个变量是否为某个对象的实例。
  - number类型：js中一切数字都用number保存，不分整型和浮点型。number类型值为不带引号的数字。使用`toFixed(小数位数)`四舍五入解决舍入误差。
  - string类型：Unicode是对所有语言文字中的字符编号（计算机只能处理数字，无法处理字符）`字符串.charCodeAt(字符在字符串中的下标)`获取该字符的Unicode国际编码。js不严格区分字符串和字符。转义字符，如`\n`
  - undefined类型：标识变量仅声明过，但从未赋值。undefined类型的值是"undefined"。
  - 原始类型大小：number: 整数4字节，浮点8字节；string：每个字符2字节
6. **`js数据类型转换`** : 包括隐式转换(程序自动转换数据类型)和强制转换
  - **`+` 号的隐式转换** ：只要有字符串参与，一切类型都变为字符串(true为"true")；如果没有字符串参与，一切按数字计算(true转成1，false转成0)。
  - **`-` 号的隐式转换**：任意数据类型做减法则先转成数值再运算，如果不能自动转成数字，则返回NaN，如果字符串为空则转成0。
  - **强制转换** ：X.`toString()`、Number(X)、`parseInt(X)`、`parseFloat(X)`、Boolean(X)
  - 凡是从页面获取的数据都是字符串，必须先转换再计算
  - **js变量为数值类型且值为0时，转成字符串就会变成`''`**。因此`var i = 0; console.log(i == '');`打印结果为`true`
7. 运算符
  - 算术运算符：+ - * / % ++ --
  - 关系运算符：> < == >= <= != ===
    - **类型自动转换**（关系运算中）：字符串参与的比较则是比较每个字符的Unicode大小；空字符串会转为0；任何类型和数字进行比较都会转为数字再比较；布尔参与的会先变成数字
    - 严格相等：=== （不带类型自动转换的比较，要求类型和值都相等；一般在不知道变量类型且不希望类型转换时使用）
    - `NaN` 和任何数字进行比较总返回 false
    - `isNaN(X)` 实际上是将X和NaN进行==比较。**isNaN采用的是Number(X)的隐式转换**。如果X是数字则返回false，否则返回true。
    - 普通数据先转换为相同数据类型再比较；如果结果可能是undefined则用严格比较；如果判读结果是否是数字，则用isNaN判断
  - 逻辑运算：|| && !
  - 位移：右移>> 左移<< （eg: 64>>3 实际是 64/(2*2*2)=8; 2<<2 实际是 2*(2*2)=8）
  - 赋值运算：= += -+ \*= /= %= (**不建议使用连等赋值**)
  - 三目运算符：? :

> - 程序都是在内存中运行的。变量声明-初始化-使用。声明是在内存中开辟一个空间，并起一个名字
> - `Number(X)`、`parseInt(X)` 和 `parseFloat(X)`区别：
>
> Number()是将数据转成数值型，如果被转的对象还有其他字符则转换不了。
> parseInt()从X字符串的第一个字符开始读取，如果遇到非数字的字符(包括小数点)则停止读取。如果第一个字符不是数字或为空的则返回`NaN`
> `NaN` (Not a Number) : 是一个不是数字(内容)的数字(类型)；NaN和数字计算返回的还是NaN。`Infinity`(无穷大)：也是一个是一个不是数字(内容)的数字(类型)，如 10/0 时。
> parseFloat() 只识别第一个小数点，如果第一个小数点前无字符，则默认加零
> parseFloat() 如果能将数据转成整数则不转成浮点（如parseFloat(2.0)的结果是2）
>
> Unicode每个字符占两字节；UTF-8字母数字占1字节，汉字占3字节。

- js字符串转数字与小数点保留：https://juejin.im/post/5cafdf075188251aee3a6071
- 浮点数运算，参考：https://blog.csdn.net/u013347241/article/details/79210840
    - `console.log(0.1+0.2)` 返回 0.30000000000000004
    - 解决：如使用[bignumber](https://github.com/MikeMcl/bignumber.js)等类库

### 函数

**function.html**

- 基本语法

    ```js
    function 函数名(参数列表){
    // ...
        return 返回值; // 函数可以不需要返回值
    }
    ```
    - `window`对象：是整个网页的全局作用域对象
    - 对未声明的变量进行赋值，js默认会在全局进行声明这个变量
    - 函数作用域在调用方法时创建，方法执行完就被销毁
- 全局函数：ECMAScript定义了标准，由各浏览器实现的函数。eg:
    - `encodeURIComponent()` 对统一资源标识符中的部分单字节再次进行编码（也可对汉字进行编码，建议使用）
    - `decodeURIComponent()` 解码
        - `encodeURI()` 对统一资源标识符进行编码，将url中的非法字符转换为单字节字符(编码，utf-8格式)
        - `decodeURI()` 将encodeURI转换后的字符串转换为原文(解码)
        - 如果在URL中再次出现保留字则是非法，如 `/ ? $ : `等，在传输过程中会出错，使用encodeURI无法进行单字节编码，需要使用encodeURIComponent进行编码
    - `eval()` 执行纯字符串格式的代码(可以将服务器传回来的数据转成对象)
- `if`、`switch`、`while`、`for`
    - 增强for循环（拿到的是下标）

    ```js
    var arr = ['a', 'b', 'c'];
    for(var i in arr) { // i 是下标
        console.log(i + "==>" + arr[i]); // 0==>a ...
    }
    ```

### 数组

**array.html**

1. 基本语法
  - `var arr = [1, 'abc', true];` // 创建了一个数组对象，里面有3个元素
  - `var str = arr[1];` // 取数组的值
  - `arr.length` 获取的是数组的大小（元素的个数）
  - **用`[]`标识的都是数组**
  - js中的数据有两个不限制：**不限制元素个数（可随时增删元素）**、**不限制元素数据类型（从数组中取数据时，最好强转后再使用）**
  - js会根据程序需要自动扩容。也可以设置length大小来达到扩容和缩容的效果。
  - 数组是引用类型的对象
    > - 原始数据类型(数据保存在变量本地, 栈中), 引用数据类型(数据保存在堆中，栈中的值(如0x4081)保存这个数据的地址，此地址指向实际数据)；原始数据类型只能保存一个值，而现实生活中的对象一般都是由多个属性进行描述的（如一个名字不能真正代表某个人，重名的太多，此时需要加上地址等信息来唯一确定某个人），引用数据类型可保存多个值。
    > - 凡是存在堆中的都是对象
    > - 数组的其他创建方式（一般不用，不能创建只含有一个数值的数组；而 var arr = [3]; 则表示创建的数组中只含有一个元素，值为 3 ）
    >   - var arr1 = new Array(3); // 创建一个数组，其中含有3个元素，其值为undefined，打印时是一个空字符
    >   - var arr2 = new Array(1, 'a', true); // 创建3个元素




05



## DOM

### clientHeight、offsetHeight、scrollHeight区别

- 参考：https://blog.csdn.net/shibazijiang/article/details/103894498






sssss


---

参考文章

[^1]: https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Statements/export (export)
[^2]: https://blog.csdn.net/yelangshisan/article/details/78936220 (JS Onblur 与Onclick事件冲突的解决办法)