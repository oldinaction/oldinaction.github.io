---
layout: "post"
title: "hibernate"
date: "2017-05-21 15:39"
categories: [java]
tags: [ssh, orm]
---

* 目录
{:toc}

## 介绍

- ORM框架(对象关系映射)
    - JDBC操作数据库很繁琐
    - Sql语句编写并不是面向对象的
    - 可以在对象和关系表之间建立关联来简化编程
    - 0/R Mapping 简化编程
    - 0/R Mapping跨越数据库平台
- ssh流程/hibernate流程(**视频01、02**)、hibernate原理(**视频06(反射)、hiberbate内部大多直接以生成二进制码的形式实现**)
- O/RMapping编程模型（**映射接口使用jpa的，编程接口使用hibernate的**）
    - 映射模型
        - jpa annotation(java提供的annotation配置--常用)
        - hibernate annotation extension(Hibernate扩展的annotation配置--较少用)
        - hibernate xml(Hibernate的xml配置方式--常用)
        - jpa xml(java提供的xml配置--较少用)
    - 编程接口（做CRUD）
        - Jpa(不常用)
        - hibernate(现在用)
    - 数据査询语言
        - HQL(常用)
        - EJBQL(JPQL)：是HQL的一个子集. EJB必须用在容器(application server)中，而hibernate可以在j2se中使用
- JPA：Java Persistence API. JPA是接口/规范，hibernate是其实现. JPA是hibernate的作者基于hibernate抽象出来的. JPA是EJB3.0的的一部分
- 本文档基于hibernate3.3.2
- 资源下载：[hibernate-distribution-3.3.2.GA](https://sourceforge.net/projects/hibernate/files/hibernate3/3.3.2.GA/hibernate-distribution-3.3.2.GA-dist.tar.gz/download)、[hibernate-annotations-3.4.0.GA](https://sourceforge.net/projects/hibernate/files/hibernate-annotations/3.4.0.GA/hibernate-annotations-3.4.0.GA.zip/download)、[slf4jl.5.8](https://mvnrepository.com/artifact/org.slf4j/slf4j-log4j12/1.5.8)、[log4j-1.2.15](https://mvnrepository.com/artifact/log4j/log4j/1.2.15)
- jar包如下：(日志使用的log4j)

    ```html
    antlr-2.7.6.jar
    commons-collections-3.1.jar
    dom4j-1.6.1.jar
    ejb3-persistence.jar
    hibernate3.jar
    hibernate-annotations.jar
    hibernate-commons-annotations.jar
    javassist-3.9.0.GA.jar
    jta-1.1.jar
    junit-4.7.jar
    log4j-1.2.15.jar
    mysql-connector-java-5.1.26-bin.jar
    slf4j-api-1.5.8.jar
    slf4j-log4j12-1.5.8.jar
    ```
    - `slf4j-api`是一个日志接口，其实现可以为`log4j`(需要对应的适配器进行接口转换，如`slf4j-log4j12-1.5.8.jar`)、`slf nodep`、`jdk logging api`、`apache commons-logging`

## Hello World

### xml配置

> `test/cn.aezo.hibernate.hello.StudentTest`

1. 配置`hibernate.cfg.xml`(配置数据源、加入)

    ```xml
    <?xml version="1.0"?>
    <!DOCTYPE hibernate-mapping PUBLIC
            "-//Hibernate/Hibernate Mapping DTD 3.0//EN"
            "http://hibernate.sourceforge.net/hibernate-mapping-3.0.dtd">

    <!-- hibernate使用xml配置数据库映射的helloworld案例。 -->
    <hibernate-mapping package="cn.aezo.hibernate.hello">
    	<class name="Student" table="student">
     		<id name="id" column="id">
    			<generator class="native"></generator><!-- 定义id自动生成器 -->
    		</id>
            <property name="name" column="name"/>

            <!-- 当使用联合主键时的配置 -->
            <!-- 因为使用UTF-8编码是主键长度不能超过256个字节，而默认id长度是int(11),name长度是varchar(255)，则超出长度，故此处应该定义长度 -->
            <!--
            <composite-id name="pk" class="cn.aezo.hibernate.model.StudentPK">
            	<key-property name="id"></key-property>
            	<key-property name="name" length="50"></key-property>
            </composite-id>
            -->

            <property name="age" column="age"/>
        </class>
    </hibernate-mapping>
    ```
2. 配置Student的映射关系(Student.hbm.xml，需要放在对应类的同级目录)，并将其加入hibernate.cfg.xml中(`<mapping resource="cn/aezo/hibernate/hello/Student.hbm.xml"/>`)

### Annotation注解 (常用)

> `test/cn.aezo.hibernate.hello.TeacherTest`

1. 配置`hibernate.cfg.xml`(配置数据源、加入)
2. 给Teacher加注解
3. 将Teacher映射加入到hibernate.cfg.xml中(`<mapping class="cn.aezo.hibernate.hello.Teacher"/>`)

## hibernate.cfg.xml配置

- 此配置文件需要放入在src目录
- 配置如下

    ```xml
    <?xml version='1.0' encoding='utf-8'?>
    <!DOCTYPE hibernate-configuration PUBLIC
            "-//Hibernate/Hibernate Configuration DTD 3.0//EN"
            "http://hibernate.sourceforge.net/hibernate-configuration-3.0.dtd">

    <hibernate-configuration>

        <session-factory>

            <!-- 配置链接数据信息，配置后不需要自己写连接代码Database connection settings -->
            <property name="connection.driver_class">com.mysql.jdbc.Driver</property>
            <property name="connection.url">jdbc:mysql://localhost:3306/hiber</property>
            <property name="connection.username">root</property>
            <property name="connection.password">root</property>

            <!-- JDBC connection pool (use the built-in) -->
            <!-- <property name="connection.pool_size">1</property> -->

            <!-- 方言,告诉hibernate使用的sql语言是mysql规定的 SQL dialect-->
            <property name="dialect">org.hibernate.dialect.MySQLDialect</property>

            <!-- 通过getCurrentSession()获取此上下文的session，没有则自动创建。thread表示线程级别,jta用于分布式事物管理(不同的数据库服务器),使用时需要中间件 -->
            <property name="current_session_context_class">thread</property>

            <!-- Disable the second-level cache  -->
            <property name="cache.provider_class">org.hibernate.cache.NoCacheProvider</property>

            <!-- 展示sql语句 -->
            <property name="show_sql">true</property>
            <!-- 展示sql语句是格式化一下，更加美观 -->
            <property name="format_sql">true</property>

            <!-- 自动生成建表语句,update有表时不会删除表,没表时自动创建。create没有表时自动创建,有表时删除再创建 -->
            <property name="hbm2ddl.auto">update</property>

    		<!-- 测试那个就映射那个，将其他映射先去掉防止干扰 -->
    		<mapping resource="cn/aezo/hibernate/hello/Student.hbm.xml"/><!-- 使用xml方式需要的映射格式 -->
    		<mapping class="cn.aezo.hibernate.hello.Teacher"/><!-- 使用annotation方式需要的映射格式 -->
        </session-factory>

    </hibernate-configuration>
    ```

## 相关注解类

- 注解应该导入jpa的注解，如**`javax.persistence.*`**
- 类级别
    - **`@Entity`**: 注解实体类, 最终会和数据库的表对应. **注解了之后需要将该类加到hibernate.cfg.xml的mapping中**
    - **`@Table(name="_teacher")`** 当实体类的类名和对应的表名不一致时批注,此时对应表的实际名为_teacher
    - `@IdClass(TeacherPK.class)` 定义联合主键的类

        > 如 `cn.aezo.hibernate.hello.Teacher`

        - `@EmbeddedlD`/`@ Embeddable`也可以定义联合主键
    - `@SequenceGenerator(name = "teacherSeq", sequenceName = "teacherSeq_db")` Id生成策略使用能够sequence
        - 在主键上加注解 `@GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "teacherSeq")`
        - 常用ID生成策略有native identity sequence uuid(xml配置)
    - `@TableGenerator` 用一张表存储所有表主键的当前值(id生成策略)
    - `@BatchSize(size=5)` 发出sql语句时一次性取出5条数据
- 字段/方法级别
    - **`@Id`** 主键; `@Basic` 其他属性,可省略
    - **`@GeneratedValue`** 批注后主键会自动生成值，默认使用id生成策略是AUTO。@GeneratedValue(strategy=GenerationType.AUTO)，其中(strategy=GenerationType.AUTO)可以省略，会自动根据mysql/oracle转换，相当于xml方式中的native
    - **`@Column(name="_title")`** 当实际的字段名和类的属性名不一致时才需批注,此时表示对应的表中的字段实际名为_title。最好一致
    - `@OrderBy("name ASC")` 排序
    - `@Transient` 透明的.表示此字段在更新时不保存到数据库中,即不参加持久化.这是annotation的写法,在xml中则不写此属性即可
    - `@Temporal(value=TemporalType.DATE)` 表示相应日期类型只记录日期,最终表的字段类型是DATE。不写的话默认是记录日期和时间,字段类型是TIMESTAMP。此处可以省略"value="。不常用
    - `@Enumerated(EnumType.STRING)` 声明枚举类型。EnumType.STRING表示在表中生成的字段类型是varchar;EnumType.ORDINAL表示表中生成的字段类型是int，并且拿枚举的下表存储

        > 如 `test/cn.aezo.hibernate.hello.TeacherTest`

- annotation字段映射位置：可以在field上或者get方法上(建议)，如果写在field则破坏了面向对象的机制，写在get方法是public的，所有一般写在get方法上

## 核心开发接口

1. 示例

    > 如 `test/cn.aezo.hibernate.coreapi.TeacherTest`

    ```java
    // Configuration cfg = Configuration().configure(); // xml可以使用
    AnnotationConfiguration acfg = new AnnotationConfiguration().configure(); // xml和Annotation都能使用

    SessionFactory　session = acfg.buildSessionFactory();

    Session session = sf.getCurrentSession(); //从上下文找(要在hibernate配置文件中配置session运行的上下文)，如果有直接用，如果没有重新创建。事务提交自动close，下次获取的就是新的session
    // Session session =  sf.openSession(); //每次都是新的，需要close

    session.beginTransaction(); //开始一个事物

    session.save(teacher1);
    Teacher1 teacher1 = (Teacher1)session.load(Teacher1.class, 1); // 存在懒加载
    // Teacher1 teacher1 = (Teacher1)session.get(Teacher1.class, 1); // 不存在懒加载

    session.getTransaction().commit(); //提交事物
    // session.close();

    System.out.println(teacher1.getName()); // 懒加载时，此处会报错
    ```
2. 接口
    - `Configuration` / `AnnotationConfiguration`: 管理配置信息(hibernate.cfg.xml), 用来产生SessionFactory(使用buildSessionFactory方法产生Session)
        - 方法：`buildSessionFactory`
    - `SessoinFactor`: 用来产生和管理Session, 通常情况下每个应用只需要一个SessionFactory(除非要访间多个数据库)
        - 方法：`getCurrentsession`(从上下文中获取，如果上下文中没有则创建一个新的。常在事物中使用，事物提交后此session则关闭)、`openSession`(每次都是新的session，需要close)
        - getCurrentsession的上下文配置：`<property name="current_session_context_classs">thread</property>`(jta、thread常用 managed、custom.Class少用)
            - 上下文主要有thread和jta两种。thread依赖于数据库本身的，简称Connection事务，只针对一个数据库。jta从分布式界定事物
            - **`jta`(全称java transaction api) java分布式事务管理（多数据库访问）, jta需要application server支持，由中间件提供（jboss、WebLogic等，tomcat不支持）**
    - `Session`: 管理一个数据库的任务单元（简单说就是增 删 改 查）
        - 方法：`sava`、`delete`、`get`、`load`、`update`、`saveOrUpdate`、`clear`、`flush`
        - **get与load的区别**
            - 不存在对应记录时表现不一样
            - load返回的是代理对象，等到真正用到对象的内容时才发出sql语句(懒加载的)
            - get直接从数据库加载，不会延迟
            - `User3 user3 = (User3)session.get(User3.class, 1);`、`User3 user3 = (User3)session.load(User3.class, 1);`
        - update(视频32)
            - 用来更新detached对象，更新完成后转为persistent状态
            - update时默认会更新全部字段，更新部分字段的解决办法
                - 使用 HQL(EjBQL)(建议）
                - xml设定property标签的update属性，annotation设定@Column的updatable=false，不过这种方式很少用，因为不灵活
                - xml中使用dynamic-update。同一个session可以，跨session不行，不过可以用merge方法
        - clear：无论是load还是get,都会首先査找缓存（一级缓存)，如果没有才会去数据库査找。调用clear()方法可以强制清除session缓存
        - flush
            - 强制将内存(session缓存)与数据库同步. 默认情况下是session的事务提交(commit)时才同步!
            - session的FlushMode设置, 可以设定在什么时候同步缓存与数据库(很少用)

3. 三种对象状态(transient、persistent、detached)
    - 三种状态：
        - transient：内存中一个对象，内存和缓存(session缓存)中都没有ID。刚new 对象之后
        - persistent：ID在内存、缓存、数据库中都有。save了之后
        - detached：ID在内存和数据库中有，在缓存中没有。事物提交后(session关闭)
    - 三种状态的区分关键在于有没有ID，ID在数据库中有没有，在内存中有没有，在session缓存中有没有

## 关系映射 (视频35-52)

一对一：`@0ne20ne`、`@JoinColumn`；一对多/多对一：`@OneToMany`、`@ManyToOne`、`@JoinColumn`；多对多：`@ManyToMany`、`@JoinTable`

1. 一对一
    - `@0ne20ne` 指定关系, `@JoinColumn` 用于指定外键名称, 省略该注解则使用默认的外键名称,  `@JoinColumns` 联合主键使用, `@Embedded` 组件映射使用
    - **一对一单向外键关联**(src/cn.aezo.hibernate.one2one_uni_fk)

        ```java
        // Husband类的被约束表字段的get方法上加@0ne20ne @JoinColumn. 最终会在Husband的表中生成外键
        @OneToOne
        @JoinColumn(name="wifeId")// 指定生成的数据库字段名，不写@JoinColumn则默认生成外键名为wife_id
        public Wife getWife() {
            return wife;
        }
        ```
        - **Husband表会多出一个字段wifeId, 即为外键**
        - xml设置

            ```xml
            <class name="cn.aezo.hibernate.one2one_uni_fk.Husband">
                    <id name="id">
                        <generator class="native"/>
                    </id>
                    <property name="name"/>
                    <property name="age"/>
                    <one-to-one name="wife" column="wifeId" unique="true"/>
            </class>
            ```
    - **一对一双向外键关联**(src/cn.aezo.hibernate.one2one_bi_fk, 视频37)

        ```java
        // Husband1类
        @OneToOne
        @JoinColumn(name="wife1Id")//指定生成的数据库字段名，否则默认生成外键名为wife_id. 最终只会在Husband的表中生成外键
        public Wife1 getWife1() {
            return wife1;
        }

        // Wife1类
        // 此处表示Husband中对"getWife"中的wife字段设置的外键是主导，此处只是指明关系但是并不会在Wife1表中生成外键。双向关系必须指明
        // 双向时这个地方也需要一个关联关系，但是Husband1中wife1已经指明了关联关系且有一个外键了，故不应该再在Wife1生成一个外键。mappedBy就表明此处参考(映射到)Husband1中的wife1字段
        @OneToOne(mappedBy="wife1")
        public Husband1 getHusband1() {
            return husband1;
        }
        ```
        - **凡是双向关联，必设`mappedBy`**
        - **`一对一单向外键关联与一对一双向外键关联在数据库的表的格式是一样的,区别在于java程序中. 双向外键关联可通过Hibernate在两个类间互相调用彼此,而单向外键关联只能单方向调用.`**
    - 一对一单向主键关联(`@OneToOne、@primaryKeyJoinColumn`)
    - 一对一双向主键关联(`@OneToOne、@primaryKeyJoinColumn`)
    - **一对一的单向联合主键的外键关联**(src/cn.aezo.hibernate.one2one_uni_fk_composite)

        ```java
        // Husband2类(Wife2是一个联合主键类, name是只最终会在Husband2中生成的字段名即外键名, referencedColumnName指这个外键参考的字段)
        @OneToOne
        @JoinColumns({
            @JoinColumn(name="wife2Id", referencedColumnName="id"),
            @JoinColumn(name="wife2Name", referencedColumnName="name")
        })
        public Wife2 getWife2() {
            return wife2;
        }
        ```
    - 组件映射(src/cn.aezo.hibernate.component)
        - 一个对象是另外一个对象的一部分，java中有两个对象，但是保存在一张表中
        - `@Embedded` 注解的字段表明该对象是从别的位置嵌入过来的,是不需要单独映射的表
        - `@AttributeOverride` 注解需要写在getWife方法上, 可以重新指定生成的Wife类组件生成的字段名, 例如:Husband与Wife两个类中都有name字段,这样在生成表的时候会有冲突, 此时采用@AttributeOverride注解可以指定Wife类中的name属性对应新的字段名"wifename"
        - xml中使用 `<component>`
2. **多对一、一对多**
    - 指当前类(写注解的类)相对于注解属性(对应的类)的关系
    - 多对一单向关联：`@ManyToOne`(src/cn.aezo.hibernate.many2one_uni)

        ```java
        // User类. 外键保存在User类中
        @ManyToOne
        public Group getGroup() {
            return group;
        }
        ```
        - xml中

            ```xml
            <!--
                cascade取值all,none,save-update,delete,对象间的级联操作,只对增删改起作用.
                在存储时User时,设置了cascade="all"会自动存储相应的t_group.而不用管user关联的对象(通常情况下会优先存储关联的对象,然后再存储user)
             -->
            <many-to-one name="group" column="groupid" cascade="all"/>
            ```
    - 一对多单向关联：`@OneToMany`(src/cn.aezo.hibernate.one2many_uni)

        ```java
        // Group1类. 外键保存在User1类中
        @OneToMany
        @JoinColumn(name="groupId")// Hibernate默认将OneToMany理解为ManyToMany的特殊形式，如果不指定生成的外键列@JoinColumn(name="groupId")，则会默认生成多对多的关系,产生一张中间表
        public Set<User1> getUsers() {
            return users;
        }
        ```
        - xml中

            ```xml
            <set name="users">
                <key column="groupId"/>指定生成外键字段的名字
                <one-to-many class="cn.aezo.hibernate.one2many_uni.User1"/>
            </set>
            ```
    - 一对多/多对一双向关联(src/cn.aezo.hibernate.one2many_many2one_bi)

        ```java
        // User2类
        @ManyToOne // 配置规则:一般以多的一端为主,先配置多的一端
        public Group2 getGroup() {
            return group;
        }

        // Group2类
        @OneToMany(mappedBy="group")
        public Set<User2> getUsers() {
            return users;
        }      
        ```
3. 多对多(会生成中间表)
    - `@ManyToMany`、`@JoinTable`
    - 多对多单向外键关联(src/cn.aezo.hibernate.many2many_uni)

        ```java
        // Teacher2类
        @ManyToMany// 多对多关联 Teacher是主的一方 Student是附属的一方
        @JoinTable(
            joinColumns={@JoinColumn(name="teacherId")},//本类主键在中间表生成的对应字段名
            inverseJoinColumns={@JoinColumn(name="student2Id")}//对方类主键在中间表生成的对应字段名
        )
        public Set<Student2> getStudent2s() {
            return student2s;
        }
        ```
    - 多对多双向外键关联

        ```
        // 在Teacher这一端的students上配置
        @ManyToMany
        @JoinTable(
            name="t_s",
            joinColumns={@JoinColumn(name="teacher_id")},
            inverseJoinColumns={@JoinColumn(name="student_id")}
        )

        // 在Student一端的teachers只需要配置
        @ManyToMany(mappedBy="students")    
        ```
4. 关联关系中的CRUD、Cascade(级联)、Fetch(test/cn.aezo.hibernate.one2many_many2one_bi_curd)
    - **设定`cascade`以设定在持久化时对于关联对象的操作（CUD，R归Fetch管）**

        ```java
        // Group3类
        @OneToMany(
            mappedBy="group",
            cascade={CascadeType.ALL}//cascade=CascadeType.ALL表示存储user表时把与他相关联的表也存储，否则需要自己先手动存储关联的那个表
            //,fetch=FetchType.EAGER//取一对多时，默认只会取出一不会取出多,即fetch默认是lazy，此时设置了eager则会在取组的同时取出用户信息。一般不这么用
        )//cascade设定CUD，fetch设定R
        public Set<User3> getUsers() {
            return users;
        }

        // User3类
        @ManyToOne(cascade={CascadeType.ALL})//cascade=CascadeType.ALL表示存储user表时把与他相关联的表也存储，否则需要自己先手动存储关联的那个表
        public Group3 getGroup() {
            return group;
        }
        ```
        - 只要有关联关系(包括所有关联类型)，默认保存A，hibernate不会自动保存B. 设置在A中设置cascade可以让hibernate在保存A的时候也保持B. 如果需要保存B也保存A，则需要在B中也设置cascade
        - CascadeType取值：
            - `ALL`      Cascade all operations所有情况(CUD)
            - `MERGE`    Cascade merge operation合并(merge=save+update)
            - `PERSIST`  Cascade persist operation存储 persist()
            - `REFRESH`  Cascade refresh operation刷新
            - `REMOVE`   Cascade remove operation删除
    - **`fetch`获取数据的方式**
        - 查询时@ManyToOne默认会把一的那一方取出来(默认为EAGER)，@OneToMany则不会默认把多的那一方取出来(默认为LAZY). 修改fetch则可以改变默认取值方式
        - 取值有：`FetchType.LAZY`(懒惰) 和 `FetchType.EAGER`(渴望)
        - 示例

            ```java
            // 示例一
            Session session = sf.getCurrentSession();
            session.beginTransaction();
            // User3 user3 = (User3)session.load(User3.class, 1);
            User3 user3 = (User3)session.get(User3.class, 1); //当多对一时，取多时，默认会把一也取出来。此时取用户的信息时也会把组的信息取出来放到内存中
            session.getTransaction().commit();
            System.out.println(user3.getGroup().getName()); // 可以正常获取, @ManyToOne默认是EAGER。如果上面是load则此处会报错

            // 示例二
            Session session = sf.getCurrentSession();
            session.beginTransaction();
            Group3 group3 = (Group3)session.get(Group3.class, 1);//取一对多时，默认只会取出一不会取出多。但如果在关联的批注处设定了fetch=FetchType.EAGER，则会同时取出用户信息
            // Set<User3> user3s = group3.getUsers(); // ### 如果fetch没有设定了eager，则可以在此处手动把User都拿出来放到内存中. 一般是一对多时手动获取多的那一方 ###
            session.getTransaction().commit();

            // ### 如果fetch设定了eager则已经将用户信息取到内存中了. 否则此处会报错 ###
            for(User3 u : group3.getUsers()) {
                System.out.println(u.getName());
            }
            ```
    - 删除操作：如果Group和User都设置了CascadeType.ALL，则在删除user时也会把group删除. 解决办法
        - 直接写Hql语句执行删除（推荐）
        - 去掉@ManyToOne(cascade={CascadeType.All})设置, 手动执行CRU
        - 将user对象的group属性设为null，相当于打断User与Group间的关联

            ```java
            session.beginTransaction();
            User user = (User)session.load(User.class,1);
            user.setGroup(null);
            session.delete(user);
            session.getTransaction().commit();
            ```
5. 集合映射(src/cn.aezo.hibernate.collections_mapping)
    - 多的一方是什么的存储方式：Set(常用)、List、Map

        ```java
        // 使用Map存储
        @OneToMany(mappedBy="group",cascade={CascadeType.ALL})
        @MapKey(name="id")//以users中user的id作为map的key
        public Map<Integer, User4> getUsers() {
            return users;
        }
        ```
6. 继承映射(视频55)
    - `SINGLE_TABLE` 一张总表保存
    - `TABLE_PER_CLASS` 每个类分别一张表(最终也会生成3张表，使用@TableGenerator的id生成策略映射)
        - 使用多态查询时会查3张表并进行合并
    - `JOINED` 每个子类一张表(最终也会生成3张表，使用@Inheritance(strategy=InheritanceType.JOINED))
        - 查询必须使用进行联合
7. 树状结构设计(src/cn.aezo.hibernate.tree)
    - 在一个类中同时使用一对多和多对一

        ```java
        // Org组织类，对应表Org(id, pid, name)
        @OneToMany(
            mappedBy="parent",
            cascade={CascadeType.ALL}
            //,fetch=FetchType.EAGER//只适合小级别的树，同时取出所有的，打印就可以打印在一起了；否则就在需要的时候发起sql语句
        )
        public Set<Org> getChildren() {
            return children;
        }

        @ManyToOne
        @JoinColumn(name="parent_id")//只需写在关联处即可，所有也可写在@OneToMany的下面
        public Org getParent() {
            return parent;
        }
        ```
## HQL (test/cn.aezo.hibernate.hql1/2)

1. 查询语言：NativeSQL(oracle/mysql原生) > HQL(hibernate查询语言) > EJBQL(JPQL 1.0, 可以跨ORM框架) > QBC(Query By Criteria) > QBE(Query By Example)
2. 举例(查询、修改、删除)

    ```java
    import org.hibernate.Query;
    import org.hibernate.Session;

    // HQL 面向对象的查询语言，此处要写类名而不是表名，可以省略 select *
    Query q = session.createQuery("from Category c where c.name > 'c5' order by c.name desc");
    List<Category> categories = (List<Category>) q.list(); // q.iterate()

    // 链式编程
    Query q = session.createQuery("from Category c where c.id > :min and c.id < :max")
                     .setInteger("min", 2)
                     .setInteger("max", 8);
    List<Category> categories = (List<Category>) q.list();

    // setParameter会自动转换参数类型
    Query q = session.createQuery("from Category c where c.id > ? and c.id < ?");
    q.setParameter(0, 2).setParameter(1, 8);

    // 分页(取第二条到第4条数据)
    Query q = session.createQuery("from Category c order by c.name desc");
    q.setMaxResults(4);
    q.setFirstResult(2);

    // 获取Topic的Category类的属性id (Topic下的Category是@ManyToOne，默认在查询Topic的会取Category)
    Query q = session.createQuery("from Topic t where t.category.id = 1");
    // 如果设置成Lazy，则当调用t.getCategory()的时候才会查询Category

    // 从实体中取出一个VO/DTO（下面的MsgInfo不是一个实体，是一个VO/DTO，他需要一个对应的构造方法）
    Query q = session.createQuery("select new cn.aezo.hibernate.hql1.MsgInfo(m.id, m.cont, m.topic.title, m.topic.category.name) from Msg m");

    // join连接(left join)
    Query q = session.createQuery("select t.title, c.name from Topic t join t.category c");

    // 对象查询（调用的是equals方法）
    Query q = session.createQuery("from Msg m where m = :MsgToSearch");
    Msg m = new Msg();
    m.setId(1);
    q.setParameter("MsgToSearch", m);
    Msg mResult = (Msg) q.uniqueResult(); // 返回唯一结果(确定里面只有一条)

    // is empty 和 is not empty（最终sql语句使用了exists、not exists）
    Query q = session.createQuery("from Topic1 t where t.msgs is empty");
    Query q = session.createQuery("from Topic1 t where not exists (select m.id from Msg1 m where m.topic.id=t.id)");

    // 获取时间
    Query q = session.createQuery("select current_date, current_time, current_timestamp, t.id from Topic1 t");

    // 时间比较
    Query q = session.createQuery("from Topic1 t where t.createDate < :date");
    q.setParameter("date", new Date());

    // 分组
    Query q = session.createQuery("select t.title, count(*) from Topic1 t group by t.title");
    Query q = session.createQuery("select t.title, count(*) from Topic1 t group by t.title having count(*) >= 1");

    // 原生sql查询
    SQLQuery q = session.createSQLQuery("select * from category limit 2,4").addEntity(Category1.class);
    List<Category1> categories = (List<Category1>)q.list();

    // 常用查询
    Query q = session.createQuery("select count(*) from Msg m");
    Query q = session.createQuery("select max(m.id), min(m.id), avg(m.id), sum(m.id) from Msg m");
    Query q = session.createQuery("from Msg m where m.id between 3 and 5");
    Query q = session.createQuery("from Msg m where m.id in (3,4, 5)");
    Query q = session.createQuery("from Msg m where m.cont is not null");
    Query q = session.createQuery("from Topic1 t where t.title like '%5'");
    Query q = session.createQuery("from Topic1 t where t.title like '_5'");

    // 别名查询
    // (1) 在实体上进行注解查询语句，去别名topic.selectCertainTopic（原生sql语句查询别名注解@NamedNativeQueries）
    @NamedQueries({
       @NamedQuery(name="topic.selectCertainTopic", query="from Topic t where t.id = :id")
 	})
    public class Topic1 {...}
    // (2) 使用上叙别名
    Query q = session.getNamedQuery("topic.selectCertainTopic");
    q.setParameter("id", 5);

    // 执行修改/删除
    Query q = session.createQuery("update Topic1 t set t.title = upper(t.title)") ;
    q.executeUpdate();
    ```
3. QBC/QBE (test/cn.aezo.hibernate.qbc/qbe)

    ```java
    // QBC (Query By Criteria). 此时不需要sql语句, 纯面向对象了
    // criterion 约束/标准/准则
    Criteria c = session.createCriteria(Topic2.class) // from Topic
                 .add(Restrictions.gt("id", 2)) // greater than = id > 2
                 .add(Restrictions.lt("id", 8)) // little than = id < 8
                 .add(Restrictions.like("title", "t_"))
                 .createCriteria("category")
                 .add(Restrictions.between("id", 3, 5)) // category.id >= 3 and category.id <=5
                 ;
    // DetachedCriterea
    for(Object o : c.list()) {
        Topic2 t = (Topic2) o;
        System.out.println(t.getId() + "-" + t.getTitle());
    }

    // QBE (Query By Example)
    Topic3 tExample = new Topic3();
    tExample.setTitle("T_");

    Example e = Example.create(tExample)
                .ignoreCase().enableLike();
    Criteria c = session.createCriteria(Topic3.class)
                 .add(Restrictions.gt("id", 2))
                 .add(Restrictions.lt("id", 8))
                 .add(e)
                 ;

    for(Object o : c.list()) {
        Topic3 t = (Topic3)o;
        System.out.println(t.getId() + "-" + t.getTitle());
    }
    ```

## 性能问题

1. `session.clear()`的运用，尤其在不断分页循环的时候
    - 在一个大集合中进行遍历，遍历msg，取出其中的含有敏感字样的对象
    - 另外一种形式的内存泄露(面试题：Java在语法级别没有内存泄漏，但是可由java引起。例如：连接池不关闭或io读取后不关闭)
2. 1+N问题
    - 使用LAZY。`@ManyToOne` 默认是EAGER（默认在查询主表是，也会查询子表的数据，发出sql语句）。可将其改为`@ManyToOne(fetch=FetchType.LAZY)`，此时当使用的时候(如:t.getCategory().getName()时)才会发出sql语句
    - hql语句中使用`join fetch`。如将hql语句改成`from Topic t left join fetch t.category c`
    - QBC。如使用createCriteria查询，会自动生成含join fetch的sql语句
3. list和iterate不同之处
    - list取所有；iterate先取ID，等用到的时候再根据ID来取对象
    - session中list第二次发出仍会到数据库査询；iterate第二次首先找session级缓存
4. 一级缓存和二级缓存和査询缓存(指两次查询的条件一样)
    - 一级缓存是session级别的缓存；二级缓存是SessionFactory级别的缓存，可以跨越session存在；
    - 二级缓存
        - 打开二级缓存，hibernate.cfg.xml设定：

            ```xml
            <property name= "cache.use_second_level_cache">true</property><!--使用二级缓存-->
            <property name="cache.provider_class">org.hibernate.cache.EhCacheProvider</property><!--使用EhCache提供商提供的二级缓存-->
            ```
        - 使用`@Cache`注解(由hibernate扩展提供)
            - `@Cache(usage=CacheConcurrencyStrategy.READ_WRITE)`
            - 使用EhCache二级缓存 需要导入ehcache-1.2.3.jar及commons-logging-1.0.4.jar包
        - 二级缓存的使用场景：**经常被访问、改动不大或不会经常改动、数重有限（如权限信息、组织信息）**
        - load默认使用二级缓存；iterate默认使用二级缓存；list默认往二级缓存加数据，但是查询的时候不使用
        - 查询缓存(指两次查询的条件一样)
            - `<property name="cache.use_query_cache">true</property>` 查询缓存依赖与二级缓存，需要打开二级缓存
            - 调用Query的`setCachable(true)`方法指明使用二级缓存，如：`session.createQuery("from Category").setCacheable(true).list();`
        - 缓存算法：LRU、LFU、FIFO
            - LRU: Least Recently Used 最近很少被使用，按使用时间
            - LFU: Least Frequently Used 按命中率高低
            - FIFO: First In First Out 按顺序替换
5. 事务并发处理
    - 事务：ACID (Atomic原子性、Consistency一致性、Itegrity独立性、Durability持久性)
    - 事务并发时可能出现的问题
        - `dirty read`脏读(读到了另一个事务在处理中还未提交的数据)
        - `non-repeatable read`不可重复读(一个事物中两次读取的数据不一致，被其他事物影响了)
        - `phantom read`幻读(主要针对插入和删除，在读的过程中，另外一个事物插入或删除了一条数据影响了读的结果)
    - 数据库的事务隔离机制
        - 查看 `java.sql.Connection` 文档
        - 1：`read-uncommitted` 2：`read-committed` 4：`repeatable read` 8：`serializable`（数字代表对应值或级别，级别越高越安全但是效率约低）           
            - `read-uncommitted`(允许读取未提交的数据) 会出现dirty read, phantom-read, non-repeatable read 问题
            - **`read-commited`**(读取已提交的数据 项目中一般都使用这个)不会出现dirty read，因为只有另一个事务提交才会读出来结果，但仍然会出现 non-repeatable read 和 phantom-read。使用read-commited机制可用悲观锁、乐观锁来解决non-repeatable read 和 phantom-read问题
            - `repeatable read`(事务执行中其他事务无法执行修改或插入操作，较安全)
            - `serializable` 解决一切问题(顺序执行事务 不并发，实际中很少用)
            - 为什么取值要使用 1 2 4 8 而不是 1 2 3 4。1=0000  2=0010 4=0100 8=1000(位移计算效率高)
        - hibernate设置
            - 设定hibernate的事务隔离级别(使用hibernate.connection.isolation配置，取值1、2、4、8)
            - hibernate.connection.isolation = 2（如果不设 默认依赖数据库本身的级别）
            - 用悲观锁解决repeatable read的问题（依赖于数据库的锁）
                - 法一：`select ... for update`
                - 法二：使用另一种load方法：`load(xxx.class, i, LockMode.Upgrade)` i=1/2/4/8
            - Hibernate(JPA)乐观锁定(ReadCommitted)
                - 实体类中增加version属性(数据库也会对应生成该字段,初始值为0)，并在其get方法前加`@Version`注解，则在操作过程中没更新一次该行数据则version值加1，即可在事务提交前判断该数据是否被其他事务修改过
