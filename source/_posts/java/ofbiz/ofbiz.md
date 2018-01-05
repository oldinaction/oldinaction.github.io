---
layout: "post"
title: "ofbiz"
date: "2017-12-09 10:17"
categories: java
tags: [ofbiz]
---

## 简介

## 安装编译启动

### 编译

- 设置hot-deploy下组件(component)编译顺序
    - `hot-deploy/build.xml`
        
        ```xml
        <?xml version="1.0" encoding="UTF-8"?>
        <project name="OFBiz hot-deploy Build" default="build" basedir=".">
            <filelist id="hot-deploy-builds" dir="."
                files="ubase/build.xml,
                aplcodecenter/build.xml"/>
            <!--运行build命令时-->
            <target name="build">
                <iterate target="jar" filelist="hot-deploy-builds"/>
                <!--除去不需编译的组件-->
                <!--
                <externalsubant target="jar">
                    <filelist refid="hot-deploy-builds"/>
                </externalsubant>
                -->
                <externalsubant target="build">
                    <filelist dir=".">
                        <file name="umetro/build.xml"/>
                    </filelist>
                </externalsubant>
            </target>
            <!--运行clean命令时执行-->
            <target name="clean">
                <iterate target="clean" filelist="hot-deploy-builds"/>
                <!--除去不需clean的组件-->
                <externalsubant target="clean">
                    <filelist dir=".">
                        <file name="umetro/build.xml"/>
                    </filelist>
                </externalsubant>
            </target>
        </project>
        ```
    - 
- 设置hot-deloy下组件单独clean：在项目根目录下的`build.xml`中加入

    ```xml
    <target name="_clean-hot-deploy" description="clean hot-deploy jar">
		<hotdeployant target="clean"/>
    </target>
    ```