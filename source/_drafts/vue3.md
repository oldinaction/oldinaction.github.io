---
layout: "post"
title: "Vue3"
date: "2024-06-20 18:14"
categories: [web]
tags: vue
---

## Vue3简介

- [Vue2参考: vue.md](/_posts/web/vue.md)
- 选项式和组合式：选项时为类似Vue2的JSON模式，组合式为类似React的函数式模式(使我们可以使用函数而不是声明选项的方式书写 Vue 组件)
- Vue3中没有了`$parent`和`$children`
    - 可通过`getCurrentInstance()`获取当前组件，`findComponentUpward()`向上查找父组件，和`findComponentsDownward()`向下查找子组件。参考：https://juejin.cn/post/7117808675716071460
- 文章
    - Vue3结合JSX
        - [babel-plugin-jsx](https://github.com/vuejs/babel-plugin-jsx)
        - 插槽和v-model使用：https://blog.csdn.net/cookcyq__/article/details/131440253
    - [Vue2 与 Vue3 如何创建响应式数据](https://zhuanlan.zhihu.com/p/357434039)

## 生命周期

| 选项式 API | 组合式 API |
| --- |  --- |
| `created`/`setup` | `<script setup>`可以在其中定义 onMounted 等方法 |
| `mounted` | `onMounted(() => { ... })` |
| `beforeMount` | `onBeforeMount(() => { ... })` |
| `beforeUpdate` | `onBeforeUpdate(() => { ... })` |
| `updated` | `onUpdated(() => { ... })` |
| `beforeUnmount` | `onBeforeUnmount(() => { ... })` |
| `unmounted` | `onUnmounted(() => { ... })` |

## 常用API

### v-model

- [**v-model**](https://cn.vuejs.org/guide/components/v-model.html)
    - 单个属性建议使用`modelValue`(固定props值)，此时直接`v-model="data"`即可
    - 多个属性可定义如`myModel`(取值props.myModel)，此时需使用`v-model:myModel="data"`(只有modelValue才能进行省略)

### defineProps/withDefaults

```html
<!-- 1.简单使用. TS模式需要定义类型 -->
<script setup>
    // 使用 `<script setup>` 语法时，defineProps 和 withDefaults 这类编译器宏不需要显式导入
    // import { defineProps, withDefaults } from "vue";
    
    const defines = defineProps(["width", "height"]);
    console.log(defines); 
</script>
<script setup lang="ts">
    const props = defineProps<{
        message: string
        count?: number
        isActive?: boolean
    }>()
</script>

<!-- 2.复杂使用: defineProps定义参数及类型, withDefaults设置默认值 -->
<script setup lang="ts">
    interface User {
        id: number
        name: string
    }

    const props = defineProps<User>()
    
    const props = withDefaults(defineProps<{
        message: string
        count?: number // ? 表示可选
        isActive?: boolean
        list?: Array<string>
        user?: User
        users?: User[]
        callback?: (id: number) => void // 函数类型
        size?: 'small' | 'medium' | 'large' // 联合类型
    }>(), {
        count: 0,
        list: () => ['default', 'value'], // 对象/数组类型的默认值必须通过工厂函数返回
        user: () => ({ id: 0, name: 'Guest' }),
        callback: () => console.log('Default callback'),
        size: 'small'
    })
</script>
```

## 响应式API

### watch

- [Vue3中watch的最佳实践](https://juejin.cn/post/6980987158710452231)

```html
<script setup>
import { watch, ref, reactive } from 'vue'
// ==> 1.侦听一个 getter
const person = reactive({name: '测试A'})
watch(
    () => person.name, 
    (n, o) => {
        console.log(n, o)
    },
    {immediate:true} // 可选
)
person.name = '测试B'

// ==> 2.直接侦听ref，及停止侦听
const ageRef = ref(16)
const stopAgeWatcher = watch(ageRef, (n, o) => {
    console.log(n, o)
    if (value > 18) {
        stopAgeWatcher() // 当ageRef大于18，停止侦听
    }
})

const changeAge = () => {
    ageRef.value += 1
}

// ==> 3.监听多个数据源
// 如果你在同一个函数里同时改变这些被侦听的来源，侦听器只会执行一次
// 如果用 nextTick 将两次修改隔开，侦听器会执行两次
const name = ref('测试A')
const age = ref(25)

watch([name, age], ([name, age], [prevName, prevAge]) => {
    console.log('newName', name, 'oldName', prevName)
    console.log('newAge', age, 'oldAge', prevAge)
})

// ==> 4.侦听引用对象（数组Array或对象Object）
const arrayRef = ref([1, 2, 3, 4])
const objReactive = reactive({name: 'test'})

// ref deep, getter形式，新旧值不一样
const arrayRefDeepGetterWatch = watch(() => [...arrayRef.value], (n, o) => {
    console.log(n, o)
}, {deep: true})

// reactive，deep，(修改name)新旧值不一样
const arrayReactiveGetterWatch = watch(() => objReactive, (n, o) => {
    console.log(n, o)
}, {deep: true})
</script>
```

### toRef

```js
// 选项式
export default defineComponent({
    props: {
        componentInfo: {
            type: Object,
            default() {
                return {
                    jsUrl: '',
                    cssUrl: ''
                }
            }
        },
    },
    setup(props, { emit }) {
        let module = ref(null);
        
        // 必须将 props 进行 toRef 否则无法获取最新值
        const componentInfoRef = toRef(props, 'componentInfo');

        // 必须监听变化才能触发其他方法更新
        watch(() => props.componentInfo, (n, o) => {
            console.log(n, o)
            init()
        }, { immediate:true })

        function init() {
            loadStyles(componentInfoRef.value.cssUrl);
        }
    }
})
```

### unref

- **unref**
    - 自动判断类型：unref 可以处理响应式引用和非引用类型的值。如果传入一个 ref，它会返回 .value 的值；如果传入一个普通值，则直接返回该值
    - 在 Vue 3 中，ref 是用于创建响应式数据的基本工具。使用 ref 创建的响应式对象需要在访问其值时使用 .value 属性

## 全局API

- app.provide(): 全局注入. 更多参考下文组件级别provide/inject

## 组合式API

### provide/inject依赖注入

- 组件级别依赖注入, 注入的对象只能在后代组件中使用; app.provide()为应用级别全局注入, 随应用实例存在
- 单向数据流: 虽然可以在后代组件中修改注入的响应式数据，但建议遵循单向数据流原则（通过事件或状态管理库修改）
- 生命周期限制: 注入的数据在组件初始化时就已确定，无法在运行时动态变更（除非使用响应式数据）

```html
<script setup>
import { ref, provide } from 'vue'

// provide('name', 'test')
const name = Symbol('name') // Symbol为ES6新的数据类型, 可理解为定义1个引用(不会产生重名问题)
provide(name, 'test') // 注入的名称可直接使用字符串, 但更推荐Symbol

// 最后代组件中注入
const name = inject(name)
// 注入一个值，若为空则使用提供的默认值
const bar = inject('name', 'hello')
</script>
```

## 选项式API


