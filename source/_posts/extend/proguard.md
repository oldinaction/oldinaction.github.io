---
layout: "post"
title: "Proguard —— 加密java代码"
date: "2022-09-06 21:00"
categories: extend
---

## 简介

- [官网](https://www.guardsquare.com/)、[使用手册](https://www.guardsquare.com/manual/home)
- Proguard 是一个适用于 Java 平台混淆代码的工具，也可以用于 Android，虽然我们直接称为混淆，实际上 Proguard 包括 shrink（压缩），optimize（优化），obfuscate（混淆），preverify（预校验）四步
    - shrink： 检测并移除没有用到的类，变量，方法和属性
    - optimize: 优化代码，非入口节点类会加上 private/static/final, 没有用到的参数会被删除，一些方法可能会变成内联代码
    - obfuscate: 使用短又没有语义的名字重命名非入口类的类名，变量名，方法名。入口类的名字保持不变
    - preverify: 预校验代码是否符合 Java1.6 或者更高的规范(唯一一个与入口类不相关的步骤)
- 支持客户端、Grandle、Ant等，Maven需要第三方插件
    - 客户端使用参考: https://blog.51cto.com/jeecg/3193512
    - [第三方Maven插件](https://github.com/wvengen/proguard-maven-plugin)
        - [文档](http://wvengen.github.io/proguard-maven-plugin/index.html)
        - [官方案例](https://github.com/wvengen/proguard-maven-plugin/blob/master/src/it/simple/pom.xml)
        - [Springboot案例](https://github.com/devslm/proguard-spring-boot-example)
- 6个常用Java源代码保护工具: https://www.cnblogs.com/jpfss/p/11533257.html

## Springboot案例

- [案例源码](https://github.com/oldinaction/smjava/blob/master/extend/proguard-springboot/pom.xml)

```xml
<build>
    <plugins>
        <!-- proguard混淆插件. spring-boot-maven-plugin需要放到此插件的后面 -->
        <!-- 之后打包后，会生成 proguard_map.txt 的映射文件(源码名称和混淆后名称的映射) -->
        <plugin>
            <groupId>com.github.wvengen</groupId>
            <artifactId>proguard-maven-plugin</artifactId>
            <version>2.5.1</version>
            <executions>
                <execution>
                    <id>run-proguard</id>
                    <phase>package</phase>
                    <goals>
                        <goal>proguard</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```
- proguard.conf (放在pom根目录)

```txt
-dontnote
-dontwarn
-verbose
-dontshrink
-dontoptimize

-adaptresourcefilenames    **.properties,**.xml,META-INF/MANIFEST.MF,META-INF/spring.*
-adaptresourcefilecontents **.properties,**.xml,META-INF/MANIFEST.MF,META-INF/spring.*
-adaptclassstrings

-keepattributes Exceptions,InnerClasses,Signature,Deprecated,SourceFile,LineNumberTable,*Annotation*,EnclosingMethod
-renamesourcefileattribute SourceFile

-keep public class cn.aezo.smjava.proguard.Application {
    public static void main(java.lang.String[]);
}
-keep public class **.entity.* {
    *;
}
-keep class * extends java.io.Serializable
-keepclassmembers class * extends java.io.Serializable {
    *;
}
```
- 解决混淆后，Bean类名找不到的问题

```java
@SpringBootApplication
public class Application {
    public static class CustomGenerator implements BeanNameGenerator {

        @Override
        public String generateBeanName(BeanDefinition definition, BeanDefinitionRegistry registry) {
            return definition.getBeanClassName();
        }
    }

    public static void main(String[] args) {
        new SpringApplicationBuilder(Application.class)
                .beanNameGenerator(new CustomGenerator())
                .run(args);
    }
}
```

## 配置模板

```bash
# 方括号: [] # 方括号代表里面的内容是可选的
# 省略号: ... # 代表前面被指定的条目可以有任意多个。
# 竖线: | # 划分两个选项
# 括号: () # 代表整体
# 缩进 # 用于说明意图
# 空格 # 没有意义

[@annotationtype] [[!]public|final|abstract|@ ...] [!]interface|class|enum classname
    [extends|implements [@annotationtype] classname]
[{
    [@annotationtype] [[!]public|private|protected|static|volatile|transient ...] <fields> |
                                                                      (fieldtype fieldname);
    [@annotationtype] [[!]public|private|protected|static|synchronized|native|abstract|strictfp ...] <methods> |
                                                                                           <init>(argumenttype,...) |
                                                                                           classname(argumenttype,...) |
                                                                                           (returntype methodname(argumenttype,...));
    [@annotationtype] [[!]public|private|protected|static ... ] *;
    ...
}]

# 说明
关键字class可以指向任何接口或类。interface关键字只能指向接口，enum只能指向枚举,接口或者枚举前面的！表示相对应的非枚举或者接口
每个classname都必须是全路径指定，比如：java.lang.String 内部类使用美元符”$”分开，比如： java.lang.Thread$State 类名可以使用包含以下通配符的正则表达式:
    ? 任意匹配类名中的一个字符，但是不匹配包名分隔符。例如 “mypackage.Test?” 匹配”mypackage.Test1” 和 “mypackage.Test2”,不匹配 “mypackage.Test12”
    * 匹配类名的任何部分除了包名分隔符，例如”mypackage.*Test*”匹配 “mypackage.Test” 和 “mypackage.YourTestApplication”,但是不匹配 “mypackage.mysubpackage.MyTest”. 或者更通俗的讲， “mypackage.*” 匹配所有 “mypackage”包里的内容,但是不匹配它子包里的内容
    ** 匹配所有类名的所有部分，包括报名分隔符
extend和implements符号用于使用统配付来限定类. 他们效果是一样的，指定只有继承或者实现指定的类和接口
@符号用于限定那些被指定注解符号标注的类和类成员，注解符的指定方法和类名一样
域和方法的指定更像java语言，除了方法参数中没有参数名。表达式可以包含以下通配符
    <init>匹配任何构造函数
    <fields>匹配任何域
    <methods>匹配任何方法
    * 匹配任何方法和域
    注意：上面的所有统配符都没有返回值，只有<init>有参数列表
方法和域还可以用正则表示指定，可以使用的通配符如下
    ? 任意匹配方法名中的单个字符
    * 匹配方法命中的任意部分
数据类型描述可以使用以下通配符
    % 匹配任何原生类型 (“boolean”, “int”, etc, but not “void”)
    ? 任意匹配单个字符
    * 匹配类名的任何部分除了包名分隔符
    ** 匹配所有类名的所有部分，包括报名分隔符
    *** 匹配任何类型，包括原生和非原生，数组和非数组
    ... 匹配任意参数个数
    * 和 ** 永远不会匹配原生类型，而且只有 **** 匹配数组类型。举个栗子：”** get*()” 匹配“java.lang.Object getObject()” 但是不匹配”float getFloat()” 也不匹配”java.lang.Object[] getObjects()”
构造函数可以使用段类名（不包含包名）
类访问修饰符(public private static)一般用来限制统配类和类成员. 他们限定指定的类必须拥有指定的访问修饰符.一个前置的！表示该修饰符没有被设置
可以组合多个标志 (e.g. public static). 表示两个条件都要满足
```

## 配置参数

```bash
#递归的从给定文件中读取参数
-include filename

#指定当前配置文件中所有路径参数的基本目录
-basedirectory directoryname

#指定需要被处理r的jar(或者 aars, wars, ears, zips, apks, or directories)。在默认情况下任何非.class的文件会被原样复制到最终打包的jar。这里需要注意的是那些临时文件（如IDE产生的文件），尤其是当你直接用一个目录指定jar文件。class_path下的条目可以被过滤，详细请看filter，为了可读性，可以使用多条-injars命令
-injars class_path

#指定输出jar包的名字(或者 aars, wars, ears, zips, apks, or directories)。前面-injars 指定的jar包会被包含到输出jar包里。这个也可以使用过滤，详细请看filter， 
#你必须避免让输出文件复写输入文件。为了可读性，可以使用多条-outjars ，如果没有指定-outjar,不会有任何jar包生成。
-outjars class_path

#指定要被处理的程序依赖的jar(或者 aars, wars, ears, zips, apks, or directories)，这些jar不会被包进output jar。这个指定的jar至少得包含程序中有被继承的类。那些只有被调用的库中的class文件不需要出现，虽然他们的出现会改善优化的结果（什么鬼， Library class files that are only called needn’t be present, although their presence can improve the results of the optimization step. ）。当然这些path也是可以过滤的 ，为了可读性，可以使用多条 -libraryjars options. 
#请注意那些为运行proguard设置的class path，不会被用于寻找类文件，也就是说你必须显示的指定你的代码需要用到的jar路径。虽然这看上去有点麻烦，但是可以让你处理不同运行环境下的程序。比如你可以处理 
#j2se 的程序也可以处理jar包，只要你指定合适的jar路径。
-libraryjars class_path

#在读取依赖的库文件时，略过非public类，来加快处理速度和减少ProGuard内存消耗 。
-skipnonpubliclibraryclasses

#在读取依赖的库文件时，不要略过那些非public类，在4.5版本中，这是默认设置
-dontskipnonpubliclibraryclasses

#不要忽略依赖库中的非公有的类成员，包括域和方法，proguard默认会忽略
-dontskipnonpubliclibraryclassmembers

#指定那些需要被保留在输出jar的文件目录，在默认情况下，这些目录会被移除来减小输出文件的size。
-keepdirectories [directory_filter]

#指定需要被处理的类文件的java版本，如1.0, 1.1, 1.2, 1.3, 1.4, 1.5 (or just 5), 1.6 (or just 6), 1.7 (or just 7), or 1.8 (or just 8)
-target version

#指定需要被保留的类和成员。
-keep 选项

#指定需要被保留的类成员，如果他们的类也有被保留。比如你要保留一个序列化类中的所有成员和方法
-keepclassmembers

#指定保留那些含有指定类成员的类，比如你想保留所有包含main方法的类
-keepclasseswithmembers

#指定那些需要被保留名字的类和类成员，前提是他们在被代码压缩的时候没有被移除。举个栗子，你可能希望保留那些实现了Serializable接口的类的名字
-keepnames

#指定那些希望被保留的类成员的名字
-keepclassmembernames

#保留含有指定名字的类和类成员。
-keepclasseswithmembernames

#将匹配的类和成员全部打印到文件或者输出。这个可以用来验证自己需要保留的类有没有成功保留
-printseeds

# ======================================== #（文件压缩选项配置）
# Shrinking options  

#不压缩类文件。默认情况下会压缩所有的类文件，除了那些用keep声明和被这些类依赖的class
-dontshrink

#将没有用到的code打印到文件或者后台
-printusage [filename]

#将那些被保留的类的原因打印出来
-whyareyoukeeping class_specification

# ======================================== #（文件优化配置项）
# Optimization options

#不优化代码，默认优化
-dontoptimize

#指定需要被enable和disable的优化项目。
-optimizations optimization_filter

#指定优化的pass数目，默认是1，多个pass可以提升优化效果. 如果在一个优化pass结束后，没有发现被提升的项目，优化就结束
-optimizationpasses n

#指定那些没有任何副作用的方法，也就是说这些方法没有实际用处，移除也没关系，比如log方法，请谨慎使用该参数，除非你知道你在做什么
-assumenosideeffects class_specification

#设置该参数后，允许proguard在优化过程中扩大访问权限。这样可以提升优化效果。请不要讲此选项应用在 
#作为lib使用的code中，因为这可能会将那些不希望被访问的代码变的可以被访问
-allowaccessmodification

#设置该参数后，允许interface被merge，即使他们的实现类没有全部实现他们。这样可以通过减少class的数量来减小输出结果的size。java 二进制规范是允许这样做的 (cfr. The Java Language Specification, Third Edition, Section 13.5.3), 虽然java语言不允许这样做(cfr. The Java Language Specification, Third Edition, Section 8.1.4). 设置这个选项会在默写虚拟机上降低处理的性能，因为一些高级的JIT偏向于更少的类实现更多的接口，更坏的是，一些虚拟机可能无法处理被优化过的代码。
-mergeinterfacesaggressively

# ======================================== #（代码混淆选项配置）
# Obfuscation options 

#不混淆代码，默认混淆
-dontobfuscate

#将mapping 打印到文件或后台
-printmapping [filename]

#使用已有的mapping文件来混淆代码
-applymapping filename

#指定希望被用做指定类和类成员混淆后新名字的列表
-obfuscationdictionary filename

#指定一个文件，里面的所有名字将被用作混淆后类的名字
-classobfuscationdictionary filename

#指定一个文件，里面的所有名字将被用作混淆后包的名字
-packageobfuscationdictionary filename

#这只这个选项后，多个方法和域会使用同一个名字，只要他们的参数和返回类型不一样。这样可以减少优化后的size
-overloadaggressively

#如果类成员在混淆前拥有相同的名字，那么混淆后也使用相同的名字，如果混淆前拥有不同的名字，那么混淆后也是用不同的名字。如果不设置这个参数，那么更多的成员可以被映射到同一个名字。如 ‘a’, ‘b’, 等。所以使用这个参数会稍微增加最后的size，但是这个可以确保被保存的混淆后的名字在后面的处理中被尊重。
-useuniqueclassmembernames

#不生成大小写混合的类名。在默认情况下，混淆后的类名会包含大小写。但是当你在那些大小写不敏感的平台，比如windows下解压混淆后的jar，解包工具会将那些相似名字的类复写。
-dontusemixedcaseclassnames

#不混淆指定的包名，包名用逗号分开。可以包含？ * ，** 等通配符，也可以用！前置
-keeppackagenames [package_filter]

#将那些被重新命名的包重新打包，他们将会被移动到同一个父包里。如果不指定包名或者是空字串，那么他们会被打包到根包。
-flattenpackagehierarchy [package_name]

#将那些被重新命名的类重新打包，如果没有指定参数或者是空字串，那么包会被完全删除。这个参数会覆盖 -flattenpackagehierarchy参数。
-repackageclasses [package_name]

#指定需要被保留的属性，可以使用多条 -keepattributes命令。多条属性用逗号分开，也可以使用？ * ** 通配符，也可以使用！。例如，当你处理一个lib的时候至少得保留Exceptions, InnerClasses, and Signature 属性。当你生成混淆stack traces时应该保留SourceFile 和LineNumberTable 。最后你可以保留annotations 如果你的代码依赖他们。
-keepattributes [attribute_filter]

#保留那些需要被保留的方法的参数名字。这个选项事实上保留的是LocalVariableTable 和LocalVariableTypeTable这两个debug属性的修剪版本。这在处理lib的时候很有用。有些IDE可以用这些信息去协助开发者，比如工具提示和自动补全。
-keepparameternames

#指定一个放在类文件SourceFile 属性的String。这些属性必须放在开头，所以这也必须用-keepattributes 显示的指定。
-renamesourcefileattribute [string]

#指定那些对应到某个class name的String常量也要被混淆。如果没有设置过滤，所有对应于某个class name的string都要被适配。如果有设置过滤，只适配匹配过滤的string。举个例子，如果你的代码中有大量对应class的硬编码的string，然后你又不想保留他们的名字，就可以可以使用这个选项。
-adaptclassstrings [class_filter]

#指定对资源文件重命名的时候，使用对应class被混淆后的名字。如果没有指定过滤，所有资源文件都会被重命名，如果设置过滤，只有匹配的资源文件才会被过滤
-adaptresourcefilenames [file_filter]

#指定内容需要被更新的资源文件。任何在这些资源文件中被提及的class name都要被重名，基于那些相应的类被混淆后的名字。如果没有设置过滤，所有资源文件的内容将被更新。资源文件使用系统默认的字符集来解析和写入。你可以通过设置环境变量 LANG或者java 系统属性 file.encoding来更改。 
#警告: 你可能只希望将这个选项应用于text文件，因为解析和适配二进制文件会导致一些意想不到的问题，所以请确保你的指定的file足够精确.
-adaptresourcefilecontents [file_filter]

# ======================================== #（预校验选项）
# Preverification options 

#不对类文件进行预校验。默认情况下，如果类文件的目标是Java ME或者不低于java 6，都会进行预校验。 
#对于Java ME，预校验是要求的，所以你需要运行一个外部的预校验过程在你处理过的代码上如果你设置了这个选项。对于 java 6 这是一个可选的选项，但是在java 7 这是被要求的。只有在andriod中这是不被强制要求的，所以你可以关闭这个选项。
-dontpreverify

#指定被处理的class file是指向Java ME的。这样预校验就会适当的添加StackMap属性，这个和默认的StackMapTable属性不一样，因为这是对于Java SE来说。
-microedition

# ======================================== #（一般选项）
# General options 

#在处理过程中输出更详细的信息，如果在处理过程中出现异常，将会输出完整的调用栈，而不是只有错误信息
-verbose

#不要输出配置文件的潜在错误和遗漏，比如类名拼写错误或者缺少一些有用的选项。可选的过滤器是一个正则表达式；ProGuard 不会打印那些被过滤器匹配成功的类名的信息。
-dontnote [class_filter]

#完全不要警告unresolved references 和 其他重要的问题.可选的过滤器是一个正则表达式。 ProGuard 不会打印那些被过滤器匹配的成功的类的警告信息。忽略警告是非常危险的，举个例子，如果 unresolved classes or class members是确实被需要的，那么代码可能无法正常工作，所以请小心使用
-dontwarn [class_filter]

#打印任何关于unresolved references 和其他重要问题的警告，但是会继续处理下去。忽略警告是危险的。举个例子如果 unresolved classes or class members是确实被需要的，那么代码可能无法正常工作，所以请小心使用
-ignorewarnings

#将配置文件的内容，包括被替换的变量和引入的文件打印到后台或者文件。
-printconfiguration [filename]

#在任何处理步骤后，输出类文件的内部结构。可以输出到后台或者文件。比如，你可能希望打印出一个jar包的所有内容。
-dump [filename]


#另外 ProGuard还可以基于类文件的完整相对名字来过滤类路径和他们的内容。每个类路径可以被最多7个文件过滤器跟着，这些过滤器用圆括号括起来，并用分号分开：
#用于aar的过滤器,
#用于apk 的过滤器,
#用于zip 的过滤器,
#用于ear 的过滤器,
#用于war 的过滤器,
#用于jar 的过滤器,
#用于所有类文件名和资源文件名的过滤器.
#如果少于7个过滤器被指定，他们会被认为是后者的过滤器。任何空的过滤器会被忽略。更正式，一个被过滤的class path可以如下：
classpathentry([[[[[[aarfilter;]apkfilter;]zipfilter;]earfilter;]warfilter;]jarfilter;]filefilter)

#方括号的意思是里面的内容是可选的
#例如, “rt.jar(java/.class,javax/.class)” 匹配rt.jar中所有在java和javax目录下的class文件
#例如, “input.jar(!.gif,images/)” 匹配在input.jar里images目录下所有文件，除了.gif文件
#不同的过滤器会被应用到所有相应的文件类型，不管他们在jar中的嵌套层次；他们是正交的（orthogonal）
#例如, “input.war(lib/.jar,support/.jar;.class,.gif)” 只关注input war 里lib目录下的jar和suppor目录下的jar，然后会匹配所有遇到的class文件和gif文件

#File names

#ProGuard 接受文件和目录的绝对路径和相对路径。相对路径的解释如下： 
#如果设置了基准目录，则就相对基准目录，否则就相对与配置文件的路径，其他任何情况就相对与工作目录。名字可以包含java系统属性（或者Ant 属性，如果使用Ant），用’<’和’>’分隔。属性会被自动替换成他们对应点值。

#那些带有特殊字符的名字像空格和括号，必须用单引号或者双引号括起来。每个在列表中的名字必须用引号单独的括起来。引号本身需要escaped 当使用命令行的时候，来避免被shell gobbled。

#例如，在命令行，你可以使用’-injars “myprogram.jar”:”/your directory/your program.jar”’

#File filters

#像通用过滤器，文件过滤器是一个包含通配符，用逗号分开的名字列表。只有名字匹配了过滤的的文件才会被读取或者写入。支持以下通配符：

#? 匹配任何单个字符 
#* 匹配文件名的任何部分，除了路径分隔符 
#** 匹配文件名的任何部分，包含任意个文件分隔符

#例如, “java/.class,javax/.class” 匹配所有在java和javax里的class文件。

#此外, 文件名字之前可以加！，表示排除这个文件名

#例如，”!**.gif,images/**”匹配所有在images目录下除了gif文件之外的所有文件

#Filters

#ProGuard提供了很多带有过滤器的选项，在配置的各个方面：文件名，目录，类，包，属性，优化等。 过滤器是包含了一串用逗号分开的含有通配符的名字列表。只有匹配的名字才可以通过过滤器。支持的通配符依赖于那些被过滤名字的类型，但是以下的通配符是典型的： 
#A filter is a list of comma-separated names that can contain wildcards. Only names that match an item on the list pass the filter. The supported wildcards depend on the type of names for which the filter is being used, but the following wildcards are typical:

#? 匹配任何单个字符 
#* 匹配文件名的任何部分，除了路径分隔符

#此外, 名字还可以用！做前缀来用于在后面的匹配中将该名字排除。所以一个名字如果匹配一个过滤器，它是被拒绝或者接受取决于那个过滤器的条目是不是以！开头。如果名字不匹配这个过滤条目，就继续匹配接下来的条目。如果不匹配任何个条目，它是被拒绝还是接受要取决于最后的过滤条目是否以！开头

#例如, “!foobar,*bar” 匹配所有以bar结尾的名字，除了footbar。

#Keep option modifiers

#如果某些方法和域被-keep保留，那么这些方法和域的类型描述符中的任何类也要被保留。这在保留native方法名字时很有用，用来确保native方法的参数类型不会被重命名。
includedescriptorclasses

#指定被-keep保留的条目可以被压缩，即使他们不得不被保留。意思是，条目可能在压缩步骤中被移除，但是如果他们是必须的，他们可以不被优化或者混淆。
allowshrinking

#指定被-keep的条目可以被优化，即使他们必须被保留。意思是条目可能在优化步骤中被改变，但是他们可以不被移除或者混淆。
allowoptimization

#指定被-keep的条目可以被混淆，即使他们必须被保留。意思是，条目可能在混淆步骤中被改名，但是他们可以不被移除和优化。
allowobfuscation

#各种各样的用于压缩和混淆的-keep选项 在刚开始可能让人感觉混乱，但是却是有规律的。下表罗列了他们之间的关系：
Overview of keep options

#Keep	From being removed or renamed	From being renamed
#Classes and class members	-keep	-keepnames
#Class members only	-keepclassmembers	-keepclassmembernames
#Classes and class members, if class members present	-keepclasseswithmembers	-keepclasseswithmembernames
#每一个-keep 选项后面会跟着一个类和类成员的定义，-keep将被引用到这些类和类成员中。

#如果你不确定你需要哪一个选项，你应该简单的使用-keep。它会确保指定的类好成员不会在压缩步骤中被移除，和在混淆步骤中被改名。
#如果你指定类的时候没有指定类成员，ProGuard只会保留类和它的无参构造函数。
#如果你指定了一个方法，ProGuard只会保留这个方法，它的代码任然会被优化和适配。
```

### 案例

```bash
#例如下面的proguad-rules.pro

#指定library文件
-libraryjars <java.home>/lib/rt.jar

# JDK目标版本1.8
-target 1.8

# 不做收缩（删除注释、未被引用代码）
-dontshrink

# 不做优化（变更代码实现逻辑）
-dontoptimize

# 用于告诉ProGuard，不要跳过对非公开类的处理。
# 默认情况下是跳过的，因为程序中不会引用它们，
# 有些情况下人们编写的代码与类库中的类在同一个包下，并且对包中内容加以引用，此时需要加入此条声明。
-dontskipnonpubliclibraryclasses

# 优化时允许访问并修改有修饰符的类和类的成员
-dontskipnonpubliclibraryclassmembers

# 确定统一的混淆类的成员名称来增加混淆
-allowaccessmodification

# 保留第三方jar包的所有类及其成员和方法，例如{*;}匹配了类内的所有成员和方法。
-useuniqueclassmembernames

-dontwarn org.apache.logging.log4j.**

-keep class org.apache.logging.log4j.** { *;}
# 不混淆所有包名，本人测试混淆后WEB项目问题实在太多，毕竟Spring配置中有大量固定写法的包名
-keeppackagenames
# 不混淆所有特殊的类
-keepattributes Exceptions,InnerClasses,Signature,Deprecated,SourceFile,LineNumberTable,LocalVariable*Table,*Annotation*,Synthetic,EnclosingMethod
# 不混淆所有的set/get方法，毕竟项目中使用的部分第三方框架（例如Shiro）会用到大量的set/get映射
-keepclassmembers public class * {void set*(***);*** get*();}

# 不混淆security包下的所有类名，且类中的方法也不混淆
-keep class com.*.security.** { <methods>; }
# 不混淆model包中的所有类以及类的属性及方法，实体包，混淆了会导致ORM框架及前端无法识别
-keep class com.*.model.** {*;}
# 以下两个包因为大部分是Spring管理的Bean，不对包类的类名进行混淆，但对类中的属性和方法混淆
-keep class com.*.service.** 
-keep class com.*.dao.**
-keep class com.*.interceptor.** {<methods>;}

# 有了verbose这句话，混淆后就会生成映射文件
# 包含有类名->混淆后类名的映射关系
# 然后使用printmapping指定映射文件的名称
-verbose
-printmapping proguardMapping.txt
# 指定混淆时采用的算法，后面的参数是一个过滤器
# 这个过滤器是谷歌推荐的算法，一般不改变
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*

-keepdirectories

# 这个是给Microsoft Windows用户的，因为ProGuard假定使用的操作系统是能区分两个只是大小写不同的文件名，
# 但是Microsoft Windows不是这样的操作系统，所以必须为ProGuard指定-dontusemixedcaseclassnames选
-dontusemixedcaseclassnames

# 保留所有的本地native方法不被混淆
-keepclasseswithmembernames class * {
    native <methods>;
}
# 保留了com.*.web.common.BaseController
# 保留了继承自BaseController这些类的子类
# 因为这些子类，都有可能被外部调用
# 比如说，第一行就保证了所有Activity的子类不要被混淆
 -keep public class * com.*.web.common.BaseController
 -keep public class * extends com.*.web.common.BaseController

# 枚举类不能被混淆
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
# 保留实体类和成员不被混淆
-keep public class * extends com.*.model.common.BaseModel {
    public void set*(***);
    public *** get*();
    public *** is*();
}
```
