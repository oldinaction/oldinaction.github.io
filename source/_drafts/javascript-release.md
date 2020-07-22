---
layout: "post"
title: "JavaScript Release"
date: "2018-05-06 17:20"
categories: [web]
tags: js
---

## ES5

### 关键字

#### import/export [^1]

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

- https://developer.mozilla.org/zh-CN/docs/Web/JavaScript/Reference/Global_Objects/Array)
- http://javascript.ruanyifeng.com/stdlib/array.html

#### 相关方法

- 修改原数组
    - `pop` 从数组中删除最后一个元素，并返回该元素的值
    - `push` 将一个或多个元素添加到数组的末尾，并返回该数组的新长度
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

#### 示例

```js
// 发明家：包含名、姓、出生日期以及死亡日期
const inventors = [
    { first: 'Albert', last: 'Einstein', year: 1879, passed: 1955 },
    ......
    { first: 'Hanna', last: 'Hammarström', year: 1829, passed: 1909 }
];
const people = ['Beck, Glenn', ...... , 'Blake, William'];

// 以数组形式，列出其名与姓 ['Albert Einstein', 'Hanna Hammarström', ...]；获返回list<map>: arr.map(o => {return {...}})
const fullnames = inventors.map(inventor => `${inventor.first} ${inventor.last}`)
// 筛选出生于16世纪的发明家
const fifteenObj = inventors.filter(inventor => (inventor.year >= 1500 && inventor.year < 1600))
// 计算所有的发明家加起来一共活了几岁
const totalyears = inventors.reduce((total, inventor) => { return total + (inventor.passed - inventor.year) }, 0)
// 根据其出生日期，并从大到小排序
const birthdate = inventors.sort((inventora, inventorb) => (inventorb.year - inventora.year))
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
    // 将为素组转换成真正的数组
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

#### call/apply/bind [^2]

- call、apply、bind 都是为了改变某个函数运行时的上下文(context)而存在的，换句话说，就是为了改变函数体内部 this 的指向
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

### 操作Dom

- 动态创建iframe(异步加载，加快主站相应速度)

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

### 事件

#### onblur与onclick事件冲突(弹框穿透) 

- 场景：百度的搜索框，输入检索字后下拉会有对应的列表出来，要求点击搜索框外的区域下拉列表消失，点击下拉列表的某个记录后跳转。实现方式为 input 的onchange+onblur 与列表的onclik 。这样就会存在一个问题，当点击列表时 input 的onblur就先发挥作用，导致列表的onclik无效（js的单线程限制了只允许一个事件触发，onblur的优先性高于onclick）
- 解决办法：用`onMouseDown`代替`onClick`(onmousedown需要根据event区分鼠标左右键点击)
- 说明
    - onClick:是鼠标点击弹起后触发的的事件，即一次完整的鼠标点击过程。
    - onMouseDown:是指鼠标按下的瞬间触发的。
    - onMouseUp：在松开鼠标的时候触发，只要弹起的时候在你所要执行的区域上，就会触发。
    - 即onClick的作用=onMouseDown（按下触发）+onMouseUp（弹起触发）

### 易错点

```js
// 1.数据类型
[1].indexOf(1) // 0
[1].indexOf("1") // -1

// 2.判断
let flag = null // undefined、null、''、0、false 在直接if判断时都认为是false，但是 []、{} 认为是 true
if(flag) console.log(1) // 无输出
if('') console.log(1) // 无输出
if(0) console.log(1) // 无输出
if([]) console.log(1) // 1
if(!0) console.log(1) // 1
```

## ES6 (ES2017)

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
    log('Done: ' + r);
}).catch(function (reason) {
    log('Failed: ' + reason);
});
```
- [async、await](https://developer.mozilla.org/zh-CN/docs/learn/JavaScript/%E5%BC%82%E6%AD%A5/Async_await)
    - 说明
        - 使用 async 关键字，把它放在函数声明之前，使其成为 async function
        - await 只在异步函数里面才起作用
    - async简单使用

        ```js
        // 1.async
        async function hello() { return "Hello" }
        hello() // 返回一个Promise

        // 2.async
        let hello = async () => { return "Hello" }
        hello().then((value) => console.log(value)) // 或者 hello().then(console.log)
        ```
    - async、await

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

        // 方式三：耗时3002。Promise.all
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

### 扩展运算符(...) [^1]

- ES7 有一个提案，将 Rest 解构赋值/扩展运算符(...)引入对象。Babel 转码器已经支持这项功能
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



---

参考文章

[^1]: https://blog.csdn.net/qq_30100043/article/details/53424750 (javascript对象的扩展运算符)
[^2]: https://www.cnblogs.com/zt123123/p/8287725.html

