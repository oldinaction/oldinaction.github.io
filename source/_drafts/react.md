---
layout: "post"
title: "React"
date: "2023-12-14 17:14"
categories: [web]
tags: react
---

## 组件

- 组件支持类组件和函数式组件，更推荐函数式

## Hooks

- 参考：https://juejin.cn/post/7041551402048421901
- 常用
    - useState 绑定变量
    - useReducer 基于类型绑定变量
    - useContext 绑定上下文
    - useEffect 副作用，类似vue watch
    - useLayoutEffect
    - useRef 绑定dom
        - forwardRef
    - useImperativeHandle 子组件中保留函数给父组件调用
    - useMemo 一般用于缓存数据
    - useCallback 一般用于缓存函数
- 举例

```js
import { useState } from 'react';

// ==> useState
// 默认组件属性和dom显示不是双向绑定的，通过useState进行双向绑定
const [count, setCount] = useState(count);


// ==> useReducer
// useReducer 作为 useState 的代替方案，在某些场景下使用更加适合，例如 state 逻辑较复杂且包含多个子值，或者下一个 state 依赖于之前的 state 等
const initialState = { count: 0 };

function reducer(state, action) {
  // 根据不同类型进行判断某个状态的处理方式
  switch (action.type) {
    case 'increment':
      return {count: state.count + 1};
    case 'decrement':
      return {count: state.count - 1};
    default:
      throw new Error();
  }
}

export default function Counter() {
  // dispatch类似setState，只不过需要传入一个类型对象
  const [state, dispatch] = useReducer(reducer, initialState);

  return (
    <>
      <p>Count: {state.count}</p>
      <button onClick={() => dispatch({type: 'decrement'})}>-</button>
      <button onClick={() => dispatch({type: 'increment'})}>+</button>
    </>
  );
}


// ==> useContext
// 默认父子组件传值需要一层层传递（同级组件可使用App进行传递），可使用useContext避免层层传递问题
export function Sub() {
    // 获取Context值
    const count = useContext(LevelContext); // 1
}

// 初始化一个Context
const ThemeContext = createContext(0);

export default function Main(props) {
  const count = useContext(LevelContext); // 0

  return (
    // 使用 Provider 将当前 props.value 传递给内部组件
    <ThemeContext.Provider value={ count + 1 }>
      <Sub />
    </ThemeContext.Provider>
  );
}


// ==> useEffect
// 类似vue watch
// 通常情况下，组件卸载时需要清除 effect 创建的副作用操作，useEffect Hook 函数可以返回一个清除函数，清除函数会在组件卸载前执行。组件在多次渲染中都会在执行下一个 effect 之前，执行该函数进行清除上一个 effect
// 默认情况下，effect 会在每一次组件渲染完成后执行。useEffect 可以接收第二个参数，它是 effect 所依赖的值数组，这样就只有当数组值发生变化才会重新创建订阅
useEffect(() => {
    document.title = `You clicked ${count} times`;

    // 返回一个清除函数，在组件卸载前和下一个effect执行前执行
    return () => {
      console.log('destroy effect');
      clearInterval(timer); // 如清除一些定时
    };
}, [count]); // 仅在 count 更改时更新


// ==> useRef/forwardRef/useImperativeHandle
// 默认情况，父组件无法直接调用子组件属性和方法。可使用useRef进行将子组件引用传递给父组件，从而完成调用
// useRef 用于返回一个可变的 ref 对象，其 .current 属性被初始化为useRef传入的参数
import { useRef, forwardRef, useImperativeHandle } from 'react'

// 通过 forwardRef 向父组件传递暴露的 ref. 接收一个(子组件)函数参数
// props为传入子组件的参数，第二个参数为父组件的 ref 实例值(inputRef)
const ForwardInput = forwardRef(function (props, ref) {
  const inputRef = useRef();
  // 自定义暴露给父组件的 ref 实例值
  useImperativeHandle(ref, () => ({
    focus: () => {
      inputRef.current.focus();
    }
  }));
  return <input ref={inputRef} type="text" {...props} />;
});

export default function Counter() {
  const inputRef = useRef();
  
  const onInputFocus = () => {
    // 默认再父组件中是无法访问到子组件的函数的，需在子组件中使用useImperativeHandle进行暴露
    inputRef.current.focus();
  };

  return (
    <>
      {/* react支持一个ref属性，该属性可以添加到任何的组件上。该ref属性可接收一个回调函数，这个回调函数在组件挂载或者卸载的时候被调用，传入参数是DOM本身 */}
      {/* 如果不是子组件，只是普通html dom也可使用ref操作dom */}
      {/* <input ref={inputRef} type="text" /> */}
      <ForwardInput ref={inputRef} />
      <button onClick={onInputFocus}>Input focus</button>
    </>
  );
}


// 性能优化（useCallback & useMemo）
// useCallback(fn, deps) 相当于 useMemo(() => fn, deps)
// 默认情况下函数式组件，如果某个绑定属性改变就会触发组件重新渲染，此时里面的函数也会重新创建；useCallback 用于创建返回一个回调函数，该回调函数只会在某个依赖项发生改变时才会更新
import { memo, useCallback } from 'react'

// memo将组件转换成一个记忆组件，只有props值没有改变，则组件不会重新渲染
const Button = memo(function ({ onClick }) {
    console.log('Button渲染了')
    return <button onClick={onClick}>Click me</button>
})

function App() {
    const [count, setCount] = useState(count);

    // 此时点击会导致count变化，从而重新渲染此组件，那么默认函数就会重新创建
    // 此处使用useCallback则不会重新创建函数，从而传递到Button组件的props就不会改成，从而子组件不会重新渲染
    const onClick = useCallback(() => {
        setCount(count + 1)
    }, []) // 类似useEffect，第二个参数决定是否重新渲染

    return (
        <>
            <p>Count: {state.count}</p>
            <Button onClick={onClick} />
        </>
    );
}
```
