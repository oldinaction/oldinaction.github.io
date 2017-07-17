---
layout: "post"
title: "ofbiz单元测试"
date: "2016-08-31 19:07"
categories: java
tags: [ofbiz, test]
---

## 测试方法书写

- 在ofbiz-component.xml中加入<test-suite loader="main" location="testdef/AezoTests.xml" />运行测试方法的入口文件
- 在入口文件AezoTests.xml中加入一个测试案例smPerson-tests

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <test-suite suite-name="Aezotests"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://ofbiz.apache.org/dtds/test-suite.xsd">

 	  <!-- 测试用例1：测试方法使用minilang实现 -->
 	  <test-case case-name="smPerson-tests">
        <simple-method-test name="smPersonTests" location="component://aezo/script/cn/aezo/test/AezoTestMethod.xml"/>
    </test-case>
  </test-suite>
  ```

- smPersonTests测试方法的内容

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <simple-methods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:noNamespaceSchemaLocation="http://ofbiz.apache.org/dtds/simple-methods-v2.xsd">

      <simple-method  method-name="smPersonTests" short-description="测试smPerson新增改查" login-required="false">
          <entity-one entity-name="UserLogin" value-field="userLogin" auto-field-map="false">
              <field-map field-name="userLoginId" value="system"/>
          </entity-one>
          <set field="createSmPersonCtx.userLogin" from-field="userLogin"/>
          <set field="createSmPersonCtx.username" value="smalleTest"/>
          <set field="createSmPersonCtx.password" value="123456"/>
          <set field="createSmPersonCtx.description" value="这是实现OFBiz的Test功能产生的记录!"/>

          <call-service service-name="createSmPersonOfTest" in-map-name="createSmPersonCtx">
              <result-to-field result-name="id"/>
          </call-service>
          <log level="info" message="========  新增SmPerson记录 [${id}] ======="/>

          <entity-one entity-name="SmPerson" value-field="smPersonList"/>
          <assert>
              <not><if-empty field="smPersonList"/></not>
              <if-compare-field field="smPersonList.id" to-field="id" operator="equals"/>
          </assert>
          <check-errors/>

      </simple-method>
  </simple-methods>
  ```

- 测试方法中调用的是我们需要进行测试的功能createSmPersonOfTest(实际开发中的某个功能)

## 运行测试

- 如果framework/entity/config/entityengine.xml中的`<delegator name="test" ...`使用的数据源和默认的delegator（`<delegator name="default" ...`）使用的数据源（datasource）一样，则需要先运行ant的`load-demo`
- 找到ant命令的`run-test`，右键`Run As`，选择`Ant Build...`。其他几个test相关的ant命令
  - `run-test-debug` 开启test时的debug。先运行此命令建立端口监听，再运行debug中该项目的远程调试命令
  - `run-test-list` 运行一系列test-cast（需在runtime/test-list-build.xml中配置）
  - `run-test-suite` 运行一个test-suite，如上面的suite-name="Aezotests"，需要配置参数`-Dtest.suiteName=Aezotests`
  - `run-tests` 运行所有的test-cast，包括ofbiz自带的application，耗时较长
- 如果选择`run-test`，则在配置`Main`选项卡中的`Arguments`，内容为
  ```text
  -Dtest.component=aezo
  -Dtest.case=smPerson-tests
  ```
- 点击`Apply`，`Run`运行测试

## 测试结果分析

测试结果会在控制台和`runtime/logs/test-results`中进行显示

## 使用java方法写测试方法，并加载默认数据

- 在入口文件AezoTests.xml中加入一个测试案例

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <test-suite suite-name="Aezotests"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://ofbiz.apache.org/dtds/test-suite.xsd">
    <test-group case-name="smPersonTest">
    	<!-- 加载测试需要的数据到数据库 -->
    	<entity-xml action="load" entity-xml-url="component://aezo/testdef/data/SmPersonTestData.xml"/>
    	<!-- 测试方法使用java实现 -->
    	<junit-test-suite class-name="cn.aezo.mytest.SmPersonTest"/>
    </test-group>
  </test-suite>
  ```

- SmPersonTestData.xml的数据为

  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <entity-engine-xml>
    <SmPerson username="smalleTestJava" password="123456" description="这是ofbiz test测试需要提前放到数据库的数据"/>
  </entity-engine-xml>
  ```

- SmPersonTest.java中的测试方法

  ```java
  package cn.aezo.mytest; // 包名最好不要起名为test，可能生成jar包失败

  import java.util.Map;
  import org.ofbiz.base.util.UtilMisc;
  import org.ofbiz.entity.GenericValue;
  import org.ofbiz.service.testtools.OFBizTestCase;

  // 继承的OFBizTestCase中含有dispatcher和delegator两个对象，且最终继承了Junit的TestCase类
  public class SmPersonTest extends OFBizTestCase {
  	protected GenericValue userLogin = null;
    public SmPersonTest(String name) {
      super(name);
    }

    @Override
    protected void setUp() throws Exception {
      // 在测试方法运行之前运行
    	userLogin = delegator.findOne("UserLogin", UtilMisc.toMap("userLoginId", "system"), false);
    }

    @Override
    protected void tearDown() throws Exception {
      // 在测试方法运行之后运行
    }

    // 测试方法命名必须以test开头。程序进到该测试类后会运行所有test开头的方法
    public void testCreateSmPerson() throws Exception {
    	Map<String, Object> ctx = UtilMisc.<String, Object>toMap("username", "smalleTestJava", "password", "12345678", "description", "这是ofbiz test的测试数据");
        ctx.put("userLogin", userLogin);
      Map<String, Object> resp = dispatcher.runSync("createSmPersonOfTestJava", ctx);
      String flag = (String) resp.get("flag");
      assertNotNull(flag);
      assertEquals("false", flag);
    }
  }
  ```
