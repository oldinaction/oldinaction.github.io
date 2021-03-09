---
layout: "post"
title: "UML"
date: "2016-07-17 11:01"
categories: extend
tags: [UML, StarUML, PlantUML, design]
---

## UML介绍

- `UML`(Unified Modeling Language): 统一建模语言，是一种图形化的语言，它可以帮助我们在OOAD过程中标识元素、构建模块、分析过程并可通过文档说明系统中的重要细节。
    - `OO`(Object Oriented)：面向对象
    - `OOAD`(OOA&D)：面向对象的分析与设计
    - `OOP`(Object Oriented Programming)：面向对象编程
    - OOP的主要特征：`抽象`(abstract)、`封装`(encapsulation)、`继承`(inheritance)、`多态`(polymorphism)、`关联`(association)、`聚合`(aggregation)、`组合`(composition)、`内聚与耦合`(cohesion & coupling)
    - `RUP`(Rational Unified Process)：统一过程，是一个采用面向对象思想，使用UML作为软件分析设计语言，并结合了项目管理、质量管理等软件工程知识综合而成的软件方法。RUP分为四个阶段：`初始`，`精化`，`构建`（编码），`交付`（使用部署图）。RUP拥抱了需求的变化，好于瀑布式开发（照搬建筑模型，需求变化后修改很麻烦）
- UML包括：事物、关系、图、扩展机制
- 事物包括：
    - 结构：类、接口、构件、节点等
    - 行为：交互（消息）、状态等
    - 分组：包、子系统等
    - 注释：注释
- **关系** 包括：`依赖`、`关联`、`泛化`(extend、继承)、`实现`
- **九种建模图** 即：`用例图`(User Case)、`类图`、`对象图`、`顺序图`(Sequence)、`协作图`(Collaboration)、`状态图`(Statechart)、`活动图`(Activity)、`组件图`、`配置图`
- 使用UML完成项目顺序
    1. 完成User Case以及document
    2. 对于比较复杂的User Case 使用Activity活动图辅助说明或者Sequence顺序图
    3. 根据User Case Document和Activity 分析业务领域的概念，抽象出概念模型
    4. 根据概念模型抽象出类
    5. 分析类的职责与关系做出类图，通常先不做方法，制作属性然后做6，然后根据这抽象出方法
    6. 根据类图制作出Sequence顺序图、Collaboration协作图、Statechart状态图等各种图示
    7. 根据图示重复迭代5-6，直至“完美”，没有完美，够用就行了
    8. Coding编码
    9. 测试并修改，必要从前面开始改起，或从1，或从5（内部测试）
    10. 部署并与用户一起测试
    11. 从实施与测试的反馈驱动下一次的1->11（交付用户测试）

## 关系

UML中的关系包括：依赖、关联、泛化(extend)、实现

- `依赖`(Dependence)：虚线箭头

    ![依赖关系](/data/images/2016/07/依赖.png)

    低耦合：表示要降低跟不稳定的对象之间的依赖关系

- `关联`(Associations)：实线箭头

    相关概念：**关联名、导航(单向关联/双向关联)、角色、多重性、聚合、组合**

    - 导航性：

        ![导航性](/data/images/2016/07/导航性.png)

    - 角色：

        ![角色](/data/images/2016/07/角色.png)

    - 多重性：

        ![多重性](/data/images/2016/07/多重性.png)

    - 聚合和组合（聚合是一种关联，组合是一种聚合）

        ![聚合和组合](/data/images/2016/07/聚合和组合.png)

- `泛化`(Extend/Generalization、继承)：实线三角箭头

    ![泛化](/data/images/2016/07/泛化.png)

- `实现`(Implement/Realize)：虚线三角箭头

    ![实现](/data/images/2016/07/实现.png)

## 建模图

- 用于描述系统结构：
  - 用例图：需求捕获，测试依据
  - 类图：静态系统架构
  - 对象图：对象之间的关联
  - 构件图：构件之间的关联
  - 部署图：构件的物理部署
- 用于描述系统行为：
  - 顺序图：不活User Case 在某个时间场景上时间执行顺序
  - 协作图：强调对象之间的写作（顺序图与协作图之间可以互相转换，而其中的信息不会丢失）
  - 状态图：描述关键类生命周期的转化
  - 活动图：流程图，描述某个方法或User Case的执行过程。

通常合在一块使用，如下图：

![UML建模图](/data/images/2016/07/UML建模图.png)

### 用例图(user case diagram)

- 用例(Use Case)是文本形式的情节描述，用于需求的发现和记录，用例会影响后续的OOA/D工作。用例是一组相关的成功或失败的集合
- 用例的编写
    - 用例编号
    - 用例名
    - 用例描述
    - 参与者
    - 前置条件 //必须满足条件
    - 后置条件 //用例做完后，对系统的影响
    - 基本路径(1、2、3、) //最重要，主功能场景，只描述正常成功的场景，不要出现如果….;参与者动作，系统响应
    - 扩展点(2.a、3.a)
    - 补充说明 //对基本路径和扩展点的未尽事宜进行描述

  ![用例图](/data/images/2016/07/用例图.png)

  ![用例图](/data/images/2016/08/用例图.png)

### 类图(class diagram)

- UML中使用最多的图形，可用于对概念建模（领域模型）、分析类图
- 领域模型(domain model)：包括概念、关系、属性，业务领域的概念名词。可用于现实世界与软件实现之间的过渡。

  ![类图](/data/images/2016/07/类图.png)

### 顺序图(sequence diagram)与协作图(collaboration diagram)

- 顺序图强调消息时间顺序的交互图

    ![顺序图](/data/images/2016/07/顺序图.png)

- 协作图则是强调发送和接收消息对象的结构组件的交互图

    ![协作图](/data/images/2016/07/协作图.png)

- Rational Rose中顺序图转协作图：Browse -> Go To Collaboration Diagram
- Rational Rose中协作图转顺序图：Browse -> Go To Sequence Diagram

### 状态图(statechart diagram)

  ![状态图](/data/images/2016/08/状态图.png)

### 活动图(activity diagram)

  ![活动图](/data/images/2016/08/活动图.png)

## StarUML使用 [^1]

- `Model Explorer` 模型浏览区
- `Diagram Explorer` 建模图浏览区
- `Properties` 设置属性区域，可以修改某个元素的属性，如名称
- `Documentation` 文档注释区域，可以为某个元素添加注释
- `Attachments` 附件区，可以为某个元素添加附件，如图片说明等
- 时序图
    - 时序图中形如`:MyClass`的对象可以理解为`MyClass`的一个实例
    - 时序图中虚线返回线怎么画?
        - 选中这个线，在右下角有个设置属性区域，把ActionKind的值由CALL改为RETURN
    - `Combined Fragment` 交互片段
        - `alt` 选择性片段，多条件分支；用虚线分割(`Interaction Operand`)，每个区域代表一个分支
        - `opt` 满足条件则执行分支(添加片段：双击图标实例 - Add Operand)
        - `loop` 循环
        - `par` 并行执行
        - `region` 只能执行一个线程的临界片段
        - `break` 中断
        - `assert` 断言
        - `ignore` 忽略
    - `Interaction Operand` 结合Combined Fragment使用
    - `Frame` 框图，简化时序图复杂度
        - `sd` 框图定义
        - `ref` 框图引用
- 导出PDF：`File`-`Print`-`Size(Tile:1-1)`
- StarUML2使用
    - 导出PDF：`File`-`Print to PDF`-`All Diagrams; Landscape; 去掉Show Diagrame Name; A4` (可以导出字体颜色)
    - 对象名称中不能包含`<>`、`-`等特殊字符，可以包含`_`、`()`
- 破解
    - StarUML3破解 https://www.jianshu.com/p/984b6c49ea26

## PlantUML

- 官网: [http://www.plantuml.com](http://www.plantuml.com)
- 可以通过文字(代码)描述来生成UML，可谓UML中的MarkDown，支持时序图、用例图、类图、活动图、组件图、状态图、对象图、部署图等UML以及非UML图(产品交互图等)
- 基于java实现，下列插件生成的图片是基于`plantuml`的官方服务器生成的，也可自行搭建渲染服务器

### 插件支持

- IDEA支持：安装插件`PlantUML integration`。idea中不支持markdown，只能解析特定的文件后缀
- vscode支持：安装插件`PlantUML`，支持markdown语法如下

<pre>
&#x60;&#x60;&#x60;plantuml
@startuml
Bob->Alice : hello
@enduml
&#x60;&#x60;&#x60;
</pre>

- hexo支持：安装插件`npm install --save hexo-filter-plantuml`，使用同vscode中写markdown

## mermaid

- 类似`PlantUML`通过文字生成UML。基于js实现
- [github](https://github.com/knsv/mermaid)


---

参考文章

[^1]: https://wenku.baidu.com/view/bfc2d0d610a6f524ccbf85f2.html (StarUML工具介绍.ppt)
