---
layout: "post"
title: "JavaScript Release"
date: "2018-05-06 17:20"
categories: [web]
tags: js
---

## ES6

### Promise

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
        }
        else {
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

- ajax返回Promise

```js
function res() {
    // 返回Promise
    return this.$ajax.post("http://localhost/test", {})
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

### 对象扩展运算符(...) [^1]

- ES7 有一个提案，将 Rest 解构赋值 / 扩展运算符(...)引入对象。 Babel 转码器已经支持这项功能

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

[^1]: [javascript对象的扩展运算符](https://blog.csdn.net/qq_30100043/article/details/53424750)

