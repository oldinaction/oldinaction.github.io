---
layout: "post"
title: "IOS应用开发"
date: "2022-02-09 19:23"
categories: [mobile]
tags: [ios, app]
---

## 开发者账号及打包

- 苹果账号类型
    - 个人开发者账号：App可提交到AppStore，688/年，**仅限开发者自己**，不需要邓百氏编码
    - 公司开发者账号：App可提交到AppStore，**688/年**，允许多个开发者协作开发，需要邓百氏编码
    - 企业开发者账号：**App不能提交到AppStore**，1988/年，允许多个开发者协作开发，需要邓百氏编码
        - 使用企业开发帐号，我们可以发布一个 ipa 放到网上，所有人（包括越狱及非越狱设备）都可以直接通过链接下载安装，而不需要通过 AppStore 下载，也不需要安装任何证书
        - 当然，使用企业帐号发布的 iOS 应用是不能提交到 AppStore 上的。而且企业级开发账号也比个人帐号更贵些（299刀/年）
        - 既然叫企业帐号，就说明是用来开发企业自己的内部应用，给自己的员工使用的。所以不要用企业号做大规模应用分发的一个渠道，否则有可能会被苹果封账号
- IOS应用分发方式
    - 使用个人开发者账号或公司开发者账号提交到AppStore进行分发（测试阶段通过添加测试设备uuid）
    - 使用签名方式通过ipa分发(不上架AppStore)
        - 苹果签名是苹果公司提供给第三方开发者在内测阶段用于分发测试的一种机制，通过企业开发者账号生成的p12文件实现签名分发
    - 企业签名
        - 无安装数量限制
        - 第三方签名不稳定，容易掉签
        - 需要信任操作，且信任入口较深
    - TestFlight(TF)
        - 仍需开发者账号
        - 限制安装数量10000个(貌似可实现不限量)
        - TF的有效期是90天，App更新会刷新此时间
        - 用户需先下载TestFlight，再从TestFlight里面下载内测APP
    - 保存书签至桌面
        - 无需签名及开发者账号
        - 只支持H5网页链接，不支持原生内容及推送
        - 仍需信任操作
    - 超级签名
        - 不易掉签
        - 无安装数量限制
        - 价格昂贵，安装一台设备10元起
    - 自签名
        - 如TrollStroe
        - 需要用户自己进行签名操作
    - WebClip书签模式
        - 相当于主页书签

## WebClip书签模式

- 将H5网页链接保存至桌面，基于苹果的WebClip功能
- 此模式有两种方式
    - 通过配置生成`.mobileconfig`文件，然后将此文件分发给用户下载，用户同下载的文件到设置中进行安装即可
    - 用户通过Safir浏览器访问H5，然后通过分享功能分享到桌面。此时只需要在HTML中增加一些meta标签即可
- mobileconfig使用
    - 参考：https://gjh.me/?p=594
    - 下载`Apple Configurator 2` - 文件 - 新建描述文件
        - 通用：名称、标识符、描述(安装时会展示)，组织和同意信息留空
        - Webclip：标签、URL、勾选可移除、勾选全屏幕、忽略清单范围(如果勾选则所有的访问都是全屏，去掉勾选则只有URL中的路径是全屏，其他会显示Safir浏览器下部分的分享栏和顶部的地址栏。注意：URL含vue hash模式的路径，但是不含history模式的路径。如果是想下载PDF文件分享到微信则需要去掉勾选，这样PDF资源路径不是URL中的路径就会显示下部分的分享栏)
        - SSL签名后会显示成未验证，仍然会警告用户未验证(不签名警告的是未签名)，通过开发者账号签名不会有此警告
    - 设置手机屏幕顶部状态栏背景颜色

    ```html
    <!-- H5模式设置手机状态栏颜色. uniapp可自定义H5模板文件，从而增加一下元信息 -->
    <meta name="theme-color" content="#066de8" media="(prefers-color-scheme: light)">
    <meta name="theme-color" content="#066de8" media="(prefers-color-scheme: dark)">
    ```
- meta标签参考
    - 官方说明：https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/ConfiguringWebApplications/ConfiguringWebApplications.html
    - https://www.ruletree.club/archives/2400/
    - https://zhangkn.github.io/2018/03/ConfiguringWebApplications/
- 安卓机H5全屏问题
    - 不支持将网页全屏展示，可下载UC浏览器，然后访问网页，设置全屏模式(对所有网页访问生效)
    - 或者使用js控制全屏(必须用户点击触发，且系统返回会退出全屏，IOS不支持)，参考：https://www.cnblogs.com/yangzhou33/p/9300329.html
