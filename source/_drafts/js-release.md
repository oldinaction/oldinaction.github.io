---
layout: "post"
title: "JavaScript知识点"
date: "2016-06-11 16:51"
categories: [web]
tags: js
---

## ES6 (ES2015)

### Promise/async/await

- Promise基本用法

```js
new Promise(function (resolve, reject) {
    log('start new Promise...');
    var timeOut = Math.random() * 2;
    log('set timeout to: ' + timeOut + ' seconds.');
    setTimeout(function () {
        if (timeOut < 1) {
            log('call resolve()...');
            resolve('200 OK');
        } else {
            log('call reject()...');
            reject('timeout in ' + timeOut + ' seconds.');
        }
    }, timeOut * 1000);
}).then(function (r) {
    return new Promise(...);
}).then(function (r) {
    log('Done: ' + r);
}).catch(function (reason) {
    log('Failed: ' + reason);
});
```
- [async、await](https://developer.mozilla.org/zh-CN/docs/learn/JavaScript/%E5%BC%82%E6%AD%A5/Async_await)
    - 说明
        - 使用 async 关键字，把它放在函数声明之前，使其成为 async function
        - await 只在异步函数（async修饰）里面才起作用
    - async简单使用

        ```js
        // 1.async
        async function hello() { return "Hello" }
        hello() // 返回一个Promise

        // 2.async
        let hello = async () => { return "Hello" }
        hello().then((value) => console.log(value)) // 或者 hello().then(console.log)
        ```
    - async、await、Promise.all

        ```js
        function timeoutPromise(interval) {
            return new Promise((resolve, reject) => {
                setTimeout(function(){
                    resolve("done");
                }, interval);
            });
        };

        // 方式一：耗时9004。简单async、await，下面3个函数要依次等待执行
        async function timeTest1() {
            await timeoutPromise(3000);
            await timeoutPromise(3000);
            await timeoutPromise(3000);
        }

        // 方式二：耗时3002。通过将 Promise 对象存储在变量中来同时开始3个timeoutPromise，然后同步等待结果
        async function timeTest2() {
            const timeoutPromise1 = timeoutPromise(3000);
            const timeoutPromise2 = timeoutPromise(3000);
            const timeoutPromise3 = timeoutPromise(3000);

            await timeoutPromise1;
            await timeoutPromise2;
            await timeoutPromise3;
        }

        // **方式三**：耗时3002。Promise.all
        async function timeTest3() {
            const timeoutPromise1 = timeoutPromise(3000);
            const timeoutPromise2 = timeoutPromise(3000);
            const timeoutPromise3 = timeoutPromise(3000);

            let values = await Promise.all([timeoutPromise1, timeoutPromise2, timeoutPromise3]);
            console.log(values) // ["done", "done", "done"]
        }

        let startTime = Date.now();
        timeTest1().then(() => {
            let finishTime = Date.now();
            let timeTaken = finishTime - startTime;
            alert("Time taken in milliseconds: " + timeTaken);
        })
        ```

- axios返回Promise

```js
function res() {
    // 返回Promise
    return this.axios.post("http://localhost/test", {})
            .then(response => {
                const res = response.data
                const status = res.status

                // 返回数据
                return {status, res}
            });
}

function test() {
    res().then(data => {
        // data为上面返回的数据
        console.log(data.status)
        console.log(data.res)
    })
}
```

### 扩展运算符(...)

- ES7 有一个提案，将 Rest 解构赋值/扩展运算符(...)引入对象。Babel 转码器已经支持这项功能 [^1]
- Rest 解构赋值
    - 解构赋值必须是最后一个参数，否则会报错 (2)
    - Rest解构赋值的拷贝是浅拷贝。即如果一个键的值是复合类型的值（数组、对象、函数），那么 Rest 解构赋值拷贝的是这个值的引用，而不是这个值的副本 (3)

```js
// (1)
let { x, y, ...z } = { x: 1, y: 2, a: 3, b: 4 }; // 相当于 x=1; y=2; z={a: 3, b: 4}

// (2) Rest解构赋值必须是最后一个参数，否则会报错
let { x, y, ...z } = null; //  运行时错误
let { x, y, ...z } = undefined; //  运行时错误  
let { ...x, y, z } = obj; //  句法错误
let { x, ...y, ...z } = obj; //  句法错误  

// (3) x是 Rest 解构赋值所在的对象，拷贝了对象obj的a属性。a属性引用了一个对象，修改这个对象的值，会影响到 Rest 解构赋值对它的引用。同理修改 x.a.b 也会影响 obj
let obj = { a: { b: 1 } };
let { ...x } = obj;  
obj.a.b = 2;
console.log(x.a.b) // 2
```
- 扩展运算符
    - 等同于 Object.assign (2)
    - 如果用户自定义的属性，放在扩展运算符后面，则扩展运算符内部的同名属性会被覆盖掉 (3)
    - Rest 解构赋值不会拷贝继承自原型对象的属性 (4)
    - 扩展运算符的参数对象之中，如果有取值函数get，这个函数是会执行的 (5)

```js
// (1)
let z = { a: 3, b: 4 };
let n = { ...z };  
console.log(n) // { a: 3, b: 4 }

let emptyObject = { ...null, ...undefined }; // 不报错

// (2) 等同于 Object.assign
// 等同于
let aClone = { ...a };
let aClone = Object.assign({x: 1}, a); // ****** a中的值会覆盖第一个对象的属性值 *****

// 等同于
let ab = { ...a, ...b };
let ab = Object.assign({}, a, b);

// (3)
// 等同于。a对象的x属性和y属性，拷贝到新对象后会被覆盖掉
let aWithOverrides = { ...a, x: 1, y: 2 };  
let aWithOverrides = { ...a, ...{ x: 1, y: 2 } };  
let x = 1, y = 2, aWithOverrides = { ...a, x, y };  
let aWithOverrides = Object.assign({}, a, { x: 1, y: 2 });  

// 等同于。如果把自定义属性放在扩展运算符前面，就变成了设置新对象的默认属性值
let aWithDefaults = { x: 1, y: 2, ...a };  
let aWithDefaults = Object.assign({}, { x: 1, y: 2 }, a);
let aWithDefaults = Object.assign({ x: 1, y: 2 }, a);

// (4) Rest 解构赋值不会拷贝继承自原型对象的属性
let o1 = { a: 1 };
let o2 = { b: 2 };
o2.__proto__ = o1;
let o3 = { ...o2 };
console.log(o3) // { b: 2 }

// (5) 扩展运算符的参数对象之中，如果有取值函数get，这个函数是会执行的
// 并不会抛出错误，因为 x 属性只是被定义，但没执行。当执行 aWithXGetter.x 时抛出错误
let aWithXGetter = { 
    ...a,  
    get x() {
        throw new Error('not thrown yet');  
    }  
};  
// 会抛出错误，因为 x 属性被执行了
let runtimeError = {
    ...a,
    ...{
        get x() {
            throw new Error('thrown now');  
        }  
    }  
};
```

## ES5

### 介绍

- 历史
    - javaScript 前身是 liveScript(Netscape，网景公司), 执行标准 ECMAScript (规定核心语法)
- 关联
    - 前端三大语言：HTML、CSS、JS
    - W3C 推出 DOM 标准：专门操作 HTML 元素，CSS样式，事件的统一标准。（规定比较重要）
    - BOM标准：专门操作浏览器窗口的工具，无标准，由浏览器厂商自行实现
    - 最后Netscape倒闭，工程师成立 Mozilla 基金会，最后发布 FireFox（理念是符合标准）
- **完整的 javaScript 语言由三部分组成**
    - 核心（`ECMAScript`）
    - 文档对象模型（`DOM`，Document Object Model）
    - 浏览器对象模型（`BOM`，Browser Object Model）
- javaScript 特点
    - 纯文本
    - 解释执行（读一行执行一行，后面的覆盖前面的）
        - javaScript运行在javascript解释器中，如浏览器中包含的解释器，或node解释器
        - 浏览器包含排版引擎和解释引擎。根据html标签决定使用什么引擎，`<script>`则找解释引擎
    - 弱类型
    - 基于对象

### 基本知识

- 区分大小写
- 字符串必须用单双引号包裹，语句有无分号效果一样
- `//`单行注释，`/*  */`多行注释（注释也占网页流量，生产环境最好去掉）
- `console.log();` 可在控制台打印相关信息，对程序无影响（`alert();`弹框打印）
- 利用`debugger;`调试，或者找到相应的源码再打断点
- `var input = prompt("请输入数据");` 用于收集用户输入数据的对话框（类似alert弹框）
- `<script>`脚本中的错误，仅影响当前脚本块中出错位置之后的代码(之前的代码照常执行)；function中的错误，只有调用方法时才触发
- 引入js文件时，`<script>`不支持单标签。必须使用 `<script src=""></script>`
- chrome 的控制台（F12），按 Shift+Enter 可换行
- nodejs 也可直接运行js文件，相当于解释器
- 事件：元素根据鼠标或者键盘的不同操作响应不同的交互行为。html的事件属性，如 ：onclick
- 网页的显示最好在7秒内，`<script>`一般放在body最后，为了使DOM先加载完
- `window`对象：是整个网页的全局作用域对象

#### 变量

- 使用`var`声明变量(一般驼峰)，**使用`const`定义常量** (一般大写)
- js中新同名变量的空间会替换旧变量的空间
- 程序都是在内存中运行的。变量声明-初始化-使用。声明是在内存中开辟一个空间，并起一个名字

#### 数据类型

- **`js是弱类型`** ：变量本身没有类型，只有变量中的值才有类型；一个变量可以反复保存不同类型的数据
- **`js数据类型`** ：包括原始数据类型和引用数据类型
    - 原始数据类型(数据保存在变量本地, 栈中)
        - 分类：number(数字)、string、boolean、null、undefined(未定义)
        - 原始类型大小，number：整数4字节，浮点8字节；string：Unicode每个字符占两字节，UTF-8字母数字占1字节，汉字占3字节
        - number
            - js中一切数字都用number保存，不分整型和浮点型
            - number类型值为不带引号的数字
            - 使用`toFixed(小数位数)`四舍五入解决舍入误差
        - string
            - Unicode是对所有语言文字中的字符编号（计算机只能处理数字，无法处理字符）
            - `字符串.charCodeAt(字符在字符串中的下标)`获取该字符的Unicode国际编码
            - js不严格区分字符串和字符
            - 转义字符，如`\n`
        - undefined
            - 标识变量仅声明过，但从未赋值；变量未赋值时，js默认赋值为undefined。undefined类型的值是"undefined"
    - 引用数据类型(数据保存在堆中)
        - 分类：Object、Function、Number、String、Boolean、Data、Error等
    - 利用 `typeof(X)` 可打印原始数据类型（返回string/number/boolean/object/function/undefined）
    - 使用 `arr instanceof Array` 用于判断一个变量是否为某个对象的实例
- **`js数据类型转换`** : 包括隐式转换(程序自动转换数据类型)和强制转换
    - **`+` 号的隐式转换** ：只要有字符串参与，一切类型都变为字符串(true为"true")；如果没有字符串参与，一切按数字计算(true转成1，false转成0)
    - **`-` 号的隐式转换**：任意数据类型做减法则先转成数值再运算，如果不能自动转成数字，则返回NaN，如果字符串为空则转成0
    - **强制转换** ：X.`toString()`、Number(X)、`parseInt(X)`、`parseFloat(X)`、Boolean(X)
    - 凡是从页面获取的数据都是字符串，必须先转换再计算
    - **js变量为数值类型且值为0时，转成字符串就会变成`''`**。因此`var i = 0; console.log(i == '');`打印结果为`true`
- `Number(X)`、`parseInt(X)` 和 `parseFloat(X)`区别
    - `Number()` 是将数据转成数值型，如果被转的对象还有其他字符则转换不了
    - `parseInt()` 从X字符串的第一个字符开始读取，如果遇到非数字的字符(包括小数点)则停止读取。如果第一个字符不是数字或为空的则返回`NaN`
        - `NaN` (Not a Number) : 是一个不是数字(内容)的数字(类型)；NaN和数字计算返回的还是NaN
        - `Infinity`(无穷大)：也是一个是一个不是数字(内容)的数字(类型)，如 10/0 时
    - `parseFloat()` 
        - 只识别第一个小数点，如果第一个小数点前无字符，则默认加零
        - 如果能将数据转成整数则不转成浮点（如parseFloat(2.0)的结果是2）
    - js字符串转数字与小数点保留：https://juejin.im/post/5cafdf075188251aee3a6071
    - 浮点数运算，参考：https://blog.csdn.net/u013347241/article/details/79210840
        - `console.log(0.1+0.2)` 返回 0.30000000000000004
        - 解决：如使用[bignumber](https://github.com/MikeMcl/bignumber.js)等类库

#### 运算符

- 算术运算符：`+ - * / % ++ --`
- 关系运算符：`> < == >= <= != ===`
    - **类型自动转换**（关系运算中）：字符串参与的比较则是比较每个字符的Unicode大小；空字符串会转为0；任何类型和数字进行比较都会转为数字再比较；布尔参与的会先变成数字
    - 严格相等：`===`（不带类型自动转换的比较，要求类型和值都相等；一般在不知道变量类型且不希望类型转换时使用）
    - `NaN` 和任何数字进行比较总返回 false
    - `isNaN(X)` 实际上是将X和NaN进行==比较。**isNaN采用的是Number(X)的隐式转换**。如果X是数字则返回false，否则返回true。
    - 普通数据先转换为相同数据类型再比较；如果结果可能是undefined则用严格比较；如果判读结果是否是数字，则用isNaN判断
- 逻辑运算：`|| && !`
- 位移：右移`>>` 左移`<<` （eg: 64>>3 实际是 64/(2*2*2)=8; 2<<2 实际是 2*(2*2)=8）
- 赋值运算：`= += -+ *= /= %=` **不建议使用连等赋值**
- 三目运算符：`? :`

#### 流程语句

- `if`、`switch`、`while`、`for`
- 增强for循环（拿到的是下标）

```js
var arr = ['a', 'b', 'c'];
for(var i in arr) { // i 是下标
    console.log(i + "==>" + arr[i]); // 0==>a ...
}
```

### Object

- https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Object

#### 相关方法

- `Object.assign(target, ...sources)` 将所有属性值从源对象复制到目标对象，并返回目标对象
    - `let c = Object.assign({}, a, b)` 将b合并到a，再将a合并到target并返回，且不会改变a和b
    - 只能进行浅拷贝，假如源对象的属性值是一个指向对象的引用（源对象和目标对象的该属性指向同一个地址，修改会互相影响），它也只拷贝那个引用值
    - 深拷贝解决方法：`let obj2 = JSON.parse(JSON.stringify(obj1))`
- `Object.defineProperty(obj, prop, descriptor)` 增加或修改对象属性。vue 2.x基于此特性实现响应式
- `Object.keys(obj)` 返回对象的所有可枚举属性的字符串数组(属性名)
    - 返回属性的顺序与手动遍历该对象属性时的一致
- `Object.getOwnPropertyNames(obj)` 在给定对象上找到的自身属性对应的字符串数组
    - 包括可枚举和不可枚举的所有属性。其中可枚举属性的顺序同Object.keys返回的顺序，不可枚举属性的顺序未定义
    - 如类数组对象可通过此方法进行遍历
- `Object.create(proto[, propertiesObject])` 使用某对象作为原型__proto__来创建新对象
    - proto 新创建对象的原型对象
- `Object.freeze(obj)` 冻结对象。不能修改对象属性，但是可重新赋值。vue项目对data属性使用此特性可提示性能

#### 示例

```js
var arr = ["a", "b", "c"];
console.log(Object.getOwnPropertyNames(arr).sort()); // ["0", "1", "2", "length"]

var obj = {
    0: "a",
    1: "b",
    "getName": function() {
        return "smalle"
    }
};
obj.name = 'hello'
console.log(Object.getOwnPropertyNames(obj).sort()); // ["0", "1", "getName", "name"]
console.log(obj["1"]); // b，通过obj.1会报错
```

### Array

- https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Array
- http://javascript.ruanyifeng.com/stdlib/array.html

#### 基本使用

- 案例

```js
var arr = [1, 'abc', true]; // 创建了一个数组对象，里面有3个元素
var str = arr[1]; // 取数组的值
arr.length // 获取的是数组的大小（元素的个数）

// 数组的其他创建方式（一般不用，因为不能创建只含有一个数值的数组，而 var arr = [3]; 可以）
var arr1 = new Array(3); // 创建一个数组，其中含有3个元素，其值为undefined，打印时是一个空字符
var arr2 = new Array(1, 'a', true); // 创建3个元素
```
- **用`[]`标识的都是数组**
- js中的数组有两个不限制
    - 不限制元素个数（可随时增删元素）。js会根据程序需要自动扩容。也可以设置length大小来达到扩容和缩容的效果
    - 不限制元素数据类型（从数组中取数据时，最好强转后再使用）
- 数组是引用类型的对象
    - 原始数据类型(数据保存在变量本地, 栈中)，引用数据类型(数据保存在堆中，栈中的值(如0x4081)保存这个数据的地址，此地址指向实际数据)
    - 原始数据类型只能保存一个值，而现实生活中的对象一般都是由多个属性进行描述的（如一个名字不能真正代表某个人，重名的太多，此时需要加上地址等信息来唯一确定某个人），引用数据类型可保存多个值
    - 凡是存在堆中的都是对象

#### 相关方法

- 修改原数组
    - `pop` 从数组中删除最后一个元素，并返回该元素的值
    - `push` 将一个或多个元素添加到数组的末尾，并返回该数组的新长度。animals.push('chickens', 'cats', 'dogs');
    - `shift` 用于把数组的第一个元素从其中删除，并返回第一个元素的值
    - `unshift` 将一个或多个元素添加到数组的开头，并返回该数组的新长度(该方法修改原有数组)
    - `splice` 基于下标修改某个元素
        - `array.splice(start[, deleteCount[, item1[, item2[, ...]]]])` 通过删除或替换现有元素或者原地添加新的元素来修改数组，并以数组形式返回被修改的内容。此方法会改变原数组
    - `sort` 排序操作，修改的是原数组(返回值也是原数组)。默认排序顺序是根据字符串Unicode码点
- 返回新数组
    - `slice` 返回一个新的浅拷贝数组对象。原始数组不会被改变。`array.slice([begin[, end]])`
        - begin：提取起始处的索引（默认从 0 开始）。如果该参数为负数，则表示从原数组中的倒数第几个元素开始提取，slice(-2) 表示提取原数组中的倒数第二个元素到最后一个元素（包含最后一个元素）
        - end：默认从0开始，但截取的不包含此索引元素。必须大于start，否则返回[]，省略则表示到数组末尾
    - `map` 映射操作。对原数组每个元素进行处理，并回传新的数组
    - `filter` 过滤操作。筛选符合条件的所有元素，若为true则返回组成新数组
    - `reduce` 归并操作。总共两个参数，第一个是参数，可以理解为累加器，遍历数组累加回传的返回值，第二个是初始元素。如果没有提供初始元素，则将使用数组中的第一个元素
        - `array.reduce(callback(accumulator, currentValue[, index[, array]])[, initialValue])`，接受参数如下
            - Accumulator (acc) (累计器)
            - Current Value (cur) (当前值)
            - Current Index (idx) (当前索引)
            - Source Array (src) (源数组)
- 其他方法
    - `some` 测试数组中是否至少有一个元素满足条件(传入的测试函数)

#### 示例

```js
// 发明家：包含名、姓、出生日期以及死亡日期
const inventors = [
    { first: 'Albert', last: 'Einstein', year: 1879, passed: 1955 },
    ......
    { first: 'Hanna', last: 'Hammarström', year: 1829, passed: 1909 }
];
const people = ['Beck, Glenn', ...... , 'Blake, William'];

// 以数组形式，列出其名与姓 ['Albert Einstein', 'Hanna Hammarström', ...]；或返回list<map>: arr.map(o => {return {...}})
const fullnames = inventors.map(inventor => `${inventor.first} ${inventor.last}`)
// 筛选出生于16世纪的发明家
const fifteenObj = inventors.filter(inventor => (inventor.year >= 1500 && inventor.year < 1600))
// 计算所有的发明家加起来一共活了几岁
const totalyears = inventors.reduce((total, inventor) => { return total + (inventor.passed - inventor.year) }, 0)
// 根据其出生日期，并从大到小排序
const birthdate = inventors.sort((inventora, inventorb) => (inventorb.year - inventora.year))

// === 语法
var newArray = arr.filter(callback(element[, index[, array]])[, thisArg])
var new_array = arr.map(function callback(currentValue[, index[, array]]) {
    // Return element for new_array 
}[, thisArg])

// === 其他
console.log([1, 2, 3, 4, 5].some((element) => element % 2 === 0)); // true
```

#### 伪数组

- 特点
    - 具有length属性
    - 按索引方式存储数据
    - 不具有数组的push()、pop()等方法
- 将伪数组转换成真正的数组
    
    ```js
    // 此处仅列举两种方法
    arr = [].slice.call(objs)
    arr = Array.prototype.slice.call(objs)
    ```
- 示例

    ```js
    // 得到一个伪数组，原型为 HTMLCollection
    var tables = document.getElementsByTagName('table')
    // 将伪数组转换成真正的数组
    var tableArr = Array.prototype.slice.call(tables)

    // 构造一个伪数组
    var obj = {
        "0": "abc",
        "1": 123,
        "length": 2,
        "push": Array.prototype.push,
        "splice": Array.prototype.splice
    }
    obj.push('hello') // 3
    ```

### Function

#### 基本

- 基本语法

```js
function 函数名(参数列表) {
    // ...
    return 返回值; // 函数可以不需要返回值
}
```
- 全局函数：ECMAScript定义了标准，由各浏览器实现的函数
    - `encodeURIComponent()` 对统一资源标识符中的部分单字节再次进行编码（也可对汉字进行编码，建议使用）
    - `decodeURIComponent()` 解码
        - `encodeURI()` 对统一资源标识符进行编码，将url中的非法字符转换为单字节字符(编码，utf-8格式)
        - `decodeURI()` 将encodeURI转换后的字符串转换为原文(解码)
        - 如果在URL中再次出现保留字则是非法，如 `/ ? $ : `等，在传输过程中会出错，使用encodeURI无法进行单字节编码，需要使用encodeURIComponent进行编码
    - `eval()` 执行纯字符串格式的代码(可以将服务器传回来的数据转成对象)

#### call/apply/bind

- call、apply、bind 都是为了改变某个函数运行时的上下文(context)而存在的，换句话说，就是为了改变函数体内部 this 的指向 [^2]
- call、apply、bind 参数
    - 三者第一个参数都是this要指向的对象，也就是想指定的上下
    - 三者都可以利用后续参数传参，call从第二个参数开始对应被调用函数参数，apply是通过数组传递被调用函数参数
- call、apply、bind 调用方式
    - call、apply 是立即调用；bind 是返回对应函数，便于稍后调用
- 示例

    ```js
    // 1.call、apply、bind 对比
    var obj = {name: 'smalle'}

    var foo = {
        get: function(count) {
            return this.name + '-' + count; 
        }
    }
    
    console.log(foo.get.call(obj, 1));      // smalle-1
    console.log(foo.get.apply(obj, [2]));   // smalle-2
    console.log(foo.get.bind(obj, 3)());    // smalle-3

    // 2.自定义console.log方法
    function log() {
        // arguments参数是个伪数组，通过 Array.prototype.slice.call 转化为标准数组(才可以使用unshift等方法)
        var args = Array.prototype.slice.call(arguments)
        args.unshift('[aezo] ')
        
        console.log.apply(console, args)
    }
    log("hello world") // [aezo] hello world
    ```

### 执行环境与作用域

#### 执行环境

- 执行环境的特点 [^5]
    - 同步执行，单线程
    - 唯一的全局执行环境，局部执行环境个数没有限制
    - 每个函数调用，包括自身函数的多次调用，js都会创建一个新的局部执行环境
    - 每个执行环境都有一个与之关联的`变量对象`，环境中定义的所以有变量和函数都保存在这个对象中
- js中有三种执行环境
    - 全局执行环境
        - 在浏览器中，全局环境就是window对象，所以所有全局属性和函数都是作为window对象的属性和方法创建
    - 函数执行环境
    - Eval执行环境，参考[下文eval](#eval)
        - 直接的调用 eval，作用域为局部作用域中；间接调用 eval(比如通过引用)，作用域是全局；严格模式下的eval的变量仅存在于eval内部，不外泄
        - eval内代码可以读取和使用所在作用域的变量，eval中声明的变量也可以在当前作用域中存在

#### 作用域

- 作用域：是指变量的生命周期（一个变量在哪些范围内保持一定值） [^4]
- 作用域相关知识点
    - 全局作用域
        - 生命周期将存在于整个程序之内，能被程序中任何函数或者方法访问，在 JavaScript 内默认是可以被修改的
        - 显式声明：带有关键字 `var` 的声明(基于let、const对比描述，具体见下文)
        - **隐式声明**：不带有声明关键字的变量，JS 会默认帮你声明一个全局变量
    - 函数作用域
        - **立即执行函数**：`(function() { //... })()` 能够自动执行，且里面包裹的内容，能够很好地消除全局变量的影响
    - 块级作用域
        - 任何一对花括号（`{}`）中的语句集都属于一个块，在这之中定义的所有变量在代码块外都是不可见的，称之为块级作用域
        - JS在 ES6 之前，是没有块级作用域的概念的
        - ES6 使用 let 和 const 关键字代替 var，从而实现块级作用域。创建块级作用域的条件是必须有一个 `{}` 包裹
    - 词法作用域
        - 当要使用声明的变量时，JS引擎总会从最近的一个域，向外层域查找的方式即为此法作用域
        - 作用域嵌套：有词法作用域一样的特性，查找变量时，总是寻找最近的作用域（基于作用域链查找）
        - 作用域链：当代码在一个环境中执行时，会创建`变量对象`(参考执行环境)的一个作用域链。这个作用域链由执行环境的`变量对象`组成，从前到后依次为最近到最远作用域，因此最后一个永远是全局作用域
    - **动态作用域**
        - 动态作用域是基于调用栈的，而不是代码中的作用域嵌套(词法作用域)
        - 词法作用域是函数的作用域在函数定义的时候决定的，而动态作用域是在函数调用的时候决定的
        - JavaScript 除了 this 之外，其他都是根据词法作用域查找
        - **上下文和作用域**
            - 每个函数的调用都有与之相关的作用域和上下文。作用域是基于函数，而上下文时基于变量对象
            - [call/apply/bind](#call/apply/bind) 都是为了改变某个函数运行时的上下文(context)而存在的，换句话说，就是为了改变函数体内部 this 的指向
            - 参考下文案例
- 案例

```js
// ============ 全局作用域
// 1.全局变量会挂载到 window 对象上
var testValue = 123;
var testFunc = function () { console.log('just test') };
console.log(window.testFunc) // ƒ () { console.log('just test') }

// 2.隐式声明
function foo(value) {
    result = value + 1; // 没有用 var 修饰
    return result;
};
foo(123);
console.log(window.result); // 124

// ============ 块级作用域
// 1.使用 let 和 const 关键字代替 var，从而实现块级作用域
for(var i = 0; i < 5; i++) {}
console.log(i) // 5 ==> 说明此时没有块级作用域

for(let i = 0; i < 5; i++) {}
console.log(i) // 报错：ReferenceError: i is not defined

// 2.**常见考题**
for(var i = 0; i < 5; i++) {
  setTimeout(function() {
    console.log(i); // 5 5 5 5 5 ==> 这里的 i 是在全局作用域里面的，只存在 1 个值，等到回调函数执行时，用词法作用域捕获的 i 就只能是 5
  }, 200);
};
for(let i = 0; i < 5; i++) {
    setTimeout(function() {
      console.log(i); // 0 1 2 3 4 ==> 当然还可以使用函数包括setTimeout实现
    }, 200);
};

// ============ **上下文和作用域**
// 1.当调用一个函数，通过new操作符创建一个对象的实例，this指向新创建的实例
function test() {
    console.log(this);
}
test(); // Window {...}
new test(); // test {}

// 2.作用域和每次函数调用时变量的访问有关系，每次调用都是独立的；上下文总是关键字this的值，是调用当前可执行代码的对象的引用
var object = {
    test: function() {
        console.log(this === object);
    }
}
object.test(); // true
```

### 零散知识

#### import/export 

- 案例 [^1]

```js
// myexp.js
// 命名导出
export { myFunc1, myFunc2 }
export const foo = Math.sqrt(2) // 导出只能是const对象

// 默认导出，一个文件只能有一个默认导出
export default {}
export default function() {}
export default class {}

import func from 'myexp.js' // 或'myexp'，导出默认对象赋值到func
import myFunc1 as func from 'myexp'
import { myFunc1, myFunc2 } from 'myexp'
```

#### eval

- [eval函数](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/eval)
- **eval函数存在漏洞，已不建议使用，可参考上述连接中的Function代替方案**
- **作用域**：直接的调用 eval，作用域为局部作用域中；间接调用 eval(比如通过引用)，作用域是全局；严格模式下的eval的变量仅存在于eval内部，不外泄
- 使用如下

    ````js
    // eval 使用
    function test() {
        var x = 2, y = 4;
        console.log(eval('x + y'));  // 直接调用，使用本地作用域，结果是 6
        
        var geval = eval; // 通过引用间接调用，等价于在全局作用域调用
        console.log(geval('x + y')); // 间接调用，使用全局作用域，throws ReferenceError 因为`x`未定义
        console.log(window.eval('x + y')) // 间接调用
        (0, eval)('x + y'); // 另一个间接调用的例子
    ​}

    // Function使用。下面示例打印 Saturday
    console.log(
        // return(function(a){return a(5)}) 中的 a 为 Function 第三个括号传递的参数(一个处理函数)
        Function('"use strict";return(function(a){return a(5)})')()(
            function(a){ return"Monday Tuesday Wednesday Thursday Friday Saturday Sunday".split(" ")[a%7||0] }
        )
    );
    ```

#### 模板字符串

- [模板字符串](https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/template_strings)
- 模板字面量，在ES2015规范的先前版本中被称为“模板字符串”
- 使用

    ```js
    // 使用模板字符串
    var name = 'smalle'
    console.log(`hello ${name}`) // hello smalle

    // 自定义模板字符串解析方法，解析 {{xxx}} 格式
    String.prototype.render = function (context) {
        return this.replace(/\{\{([^\}]+)\}\}/g, (match, key) => (context[key] || match));
    };
    "hi, {{name}}, {{{{name}}}}".render({name: 'smalle', smalle: 'test'}) // hi, smalle, {{{{name}}}}
    ```

### 易错点

```js
// 1.数据类型
[1].indexOf(1) // 0
[1].indexOf("1") // -1

// 2.空值判断
let flag = null // undefined、null、''、0、false 在直接if判断时都认为是false，但是 []、{} 认为是 true
if(flag) console.log(1) // 无输出
if('') console.log(1) // 无输出 (false)
if(0) console.log(1) // 无输出 (false)
if(!0) console.log(1) // 1 (true)
if([]) console.log(1) // 1 (true)
if({}) console.log(1) // 1 (true)
if(0 == null) console.log(1) // 无输出 (false)
if(undefined == null) console.log(1) // 1 (true)
if(undefined === null) console.log(1) // 无输出 (false)
```

## DOM

### 动态创建iframe(异步加载，加快主站相应速度)

```js
function createIframe() {
    var i = document.createElement("iframe");
    i.id="iframe"
    i.src = "http://localhost/test";
    i.frameborder = "0";
    i.width = "100%";
    i.height = "100%";
    i.onload=myOnloadFunc;
    document.getElementById("iframeDiv").appendChild(i);
};

if (window.addEventListener) window.addEventListener("load", createIframe, false);
else if (window.attachEvent) window.attachEvent("onload", createIframe);
else window.onload = createIframe;
```

### onblur与onclick事件冲突(弹框穿透) 

- 场景：百度的搜索框，输入检索字后下拉会有对应的列表出来，要求点击搜索框外的区域下拉列表消失，点击下拉列表的某个记录后跳转。实现方式为 input 的onchange+onblur 与列表的onclik 。这样就会存在一个问题，当点击列表时 input 的onblur就先发挥作用，导致列表的onclik无效（js的单线程限制了只允许一个事件触发，onblur的优先性高于onclick） [^3]
- 解决办法：用`onMouseDown`代替`onClick`(onmousedown需要根据event区分鼠标左右键点击)
- 说明
    - onClick:是鼠标点击弹起后触发的的事件，即一次完整的鼠标点击过程。
    - onMouseDown:是指鼠标按下的瞬间触发的。
    - onMouseUp：在松开鼠标的时候触发，只要弹起的时候在你所要执行的区域上，就会触发。
    - 即onClick的作用=onMouseDown（按下触发）+onMouseUp（弹起触发）


### clientHeight、offsetHeight、scrollHeight区别

- 参考：https://blog.csdn.net/shibazijiang/article/details/103894498


### 常见问题





---

参考文章

[^1]: https://blog.csdn.net/qq_30100043/article/details/53424750 (javascript对象的扩展运算符)
[^2]: https://www.cnblogs.com/zt123123/p/8287725.html
[^3]: https://blog.csdn.net/yelangshisan/article/details/78936220
[^4]: https://juejin.cn/post/6844903584891420679
[^5]: https://juejin.cn/post/6844904065776910344

