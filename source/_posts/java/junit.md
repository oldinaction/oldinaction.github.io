---
layout: "post"
title: "Junit"
date: "2021-08-19 18:28"
categories: java
tags: test
---

## 使用

- IDEA右键测试包, 一件运行包下的所有 Tests

### 断言

| 方法                                       | 说明                  | 示例                                                                                                              |
|------------------------------------------|---------------------|-----------------------------------------------------------------------------------------------------------------|
| `assertEquals(expected, actual)`         | 判断两个值相等             | `Assertions.assertEquals(2, 1 + 1)`                                                                             |
| `assertNotEquals(unexpected, actual)`    | 判断两个值不相等            | `Assertions.assertNotEquals(3, 1 + 1)`                                                                          |
| `assertTrue(condition)`                  | 判断条件为 `true`        | `Assertions.assertTrue(list.isEmpty())`                                                                         |
| `assertFalse(condition)`                 | 判断条件为 `false`       | `Assertions.assertFalse(list.isEmpty())`                                                                        |
| `assertNull(actual)`                     | 判断对象为 `null`        | `Assertions.assertNull(user)`                                                                                   |
| `assertNotNull(actual)`                  | 判断对象不为 `null`       | `Assertions.assertNotNull(user)`                                                                                |
| `assertSame(expected, actual)`           | 判断两个对象引用相同（地址相等）    | `Assertions.assertSame(list1, list2)`                                                                           |
| `assertNotSame(unexpected, actual)`      | 判断两个对象引用不同          | `Assertions.assertNotSame(list1, list2)`                                                                        |
| `assertThrows(expectedType, executable)` | 判断执行代码抛出指定异常        | `Assertions.assertThrows(IllegalArgumentException.class, () -> { throw new IllegalArgumentException(); })`      |
| `assertAll(executables)`                 | 批量断言（所有断言都执行，失败时汇总） | `Assertions.assertAll("用户信息", () -> assertEquals("张三", user.getName()), () -> assertEquals(20, user.getAge()))` |

### @Rule

- `@Rule`是JUnit4.7加入的新特性，有点类似于拦截器，用于在测试方法执行前后添加额外的处理。实际上是@Before，@After的另一种实现
    - 需要注解在实现了TestRule的public成员变量上或者返回TestRule的方法上
    - 相应Rule会应用于该类每个测试方法
- 允许在测试类中非常灵活的增加或重新定义每个测试方法的行为，简单来说就是提供了测试用例在执行过程中通用功能的共享的能力 [^1]
- 案例参考下文[ErrorCollector](#ErrorCollector类收集错误统一抛出)

### ErrorCollector类收集错误统一抛出

- Junit在遇到一个测试失败时，并会退出，通过ErrorCollector可实现收集所有的错误，等方法运行完后统一抛出
- 案例

```java
public class Example {
    @Rule
    public ErrorCollector collector = new ErrorCollector();

    @Test
    public void example() {				
        collector.addError(new RuntimeException("error 1"));
        System.out.println("==================================");

        // 如果测试值 myVal != true 则将错误添加到collector中
        boolean myVal = false;
        // IsEqual.equalTo("xxx") IsNull.nullValue()
        collector.checkThat("error2", myVal, Is.is(true));

        // 代码执行完，此处会统一抛出错误，提示2个异常。但是如果是前面代码执行报错则不会打印测试结果
        // 如果全部成功则不报错
    }
}
```

### Before/After钩子

```java
import org.junit.jupiter.api.*;

public class ResourceManagementTest {
    // 静态资源（所有测试共享）
    private static DatabaseConnection sharedDbConnection;
    
    // 实例资源（每个测试独立）
    private File tempFile;

    // 在当前类的所有测试开始前执行一次（必须是 static 方法）
    // SpringBoot 可在类上添加注解 @TestInstance(TestInstance.Lifecycle.PER_CLASS) 此时可以去掉 static 从而可以获取 bean (SpringBoot3貌似有点问题)
    @BeforeAll
    public static void setUpAll() {
        sharedDbConnection = new DatabaseConnection("jdbc:mysql://localhost/test");
        sharedDbConnection.connect();
    }

    // 在每个测试方法开始前执行
    @BeforeEach
    public void setUpEach() {
        // 或者 Resource resource = new ClassPathResource("test.txt")
        tempFile = new File(System.getProperty("user.dir") + "/src/test/resources/test.txt");
        tempFile.createNewFile(); // 初始化临时文件
    }

    // 在每个测试方法结束后执行
    @AfterEach
    public void tearDownEach() {
        tempFile.delete(); // 清理临时文件
    }

    // 在所有测试结束后执行一次（必须是 static 方法）
    @AfterAll
    public static void tearDownAll() {
        sharedDbConnection.disconnect();
    }

    @Test
    public void testExample() {
        // 使用初始化的资源进行测试
        Assertions.assertTrue(tempFile.exists());
        // ...
    }
}
```

## SpringBoot测试

- 测试环境使用单独的配置文件
    - 可使用`@ActiveProfiles("test")`激活application-test.yml的配置文件
    - 如果在`src/test/resources`目录下增加application-test.yml，运行时会覆盖`src/main/resources`下的该文件
- 普通测试

```java
@AutoConfigureMockMvc // 可以自动的注册所有添加@Controller或者@RestController的路由的MockMvc了
@RunWith(SpringRunner.class)
@SpringBootTest
// @SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT) // websocket环境需要，否则报错：javax.websocket.server.ServerContainer not available
//@ActiveProfiles(value = {"dev", "dev-local"}) // 可设置配置文件（如果文件在外部可在测试类配置中增加环境变量，如spring.config.additional-location=/Users/smalle/data/project/aezo-chat-gpt/）
@TestInstance(TestInstance.Lifecycle.PER_CLASS) // @BeforeAll方法可以去掉 static 从而可以获取 bean (SpringBoot3貌似有点问题)
public class DynamicAddTests extends BaseLoginTest {
    @Autowired
    private MockMvc mockMvc;
    @Autowired
	private DataSource dataSource;

    @Test
    public void login(){
        try {
			MvcResult mvcResult = mockMvc.perform(MockMvcRequestBuilders.get("/test3?dsKey=mysql-two-dynamic"))
                    .andExpect(MockMvcResultMatchers.status().isOk())
                    .andReturn();
            String content = mvcResult.getResponse().getContentAsString();
            Assert.assertEquals("success", "hello world!", content);

            mockMvc.perform(MockMvcRequestBuilders.post("/api/login/auth")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"name\": \"smalle\"}")
            ).andExpect(MockMvcResultMatchers.status().isOk())
                    .andDo(MockMvcResultHandlers.print()); // 打印请求过程
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    @BeforeAll
    public void init() throws Exception {
        log.info("init start...");
        executeSqlFile("sql/init.sql");
        log.info("init end...");
    }
    
    public void executeSqlFile(String sqlFilePath) throws SQLException {
		try (Connection connection = dataSource.getConnection()) {
			// 执行 SQL 文件
			ScriptUtils.executeSqlScript(connection, new ClassPathResource(sqlFilePath));
		}
	}
}
```
- 基于登录: 如有些服务需要登录才能访问

```java
@Slf4j
@ExtendWith(SpringExtension.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, classes = MyApplication.class)
public class BaseLoginTest {
    // shiro 登录案例
	@Resource
	private org.apache.shiro.mgt.SecurityManager securityManager;
	
	@Autowired
	private WebApplicationContext webApplicationContext;

	private MockMvc mockMvc;

	@BeforeEach
	public void setUp() throws Exception {
	    // org.apache.shiro.SecurityUtils
        SecurityUtils.setSecurityManager(securityManager);
		mockMvc = MockMvcBuilders.webAppContextSetup(webApplicationContext).build();

		// 直接基于账号生成Token
		String tokenStr = JwtUtil.sign("admin", "随便");
		log.info("token={}", tokenStr);
        
        // 传入 Token 进行用户信息获取
		final JwtToken token = new JwtToken(tokenStr);
		final org.apache.shiro.subject.Subject subject = SecurityUtils.getSubject();
		subject.login(token);
	}
}
```

## 多线程测试

### 多线程简单测试模板

```java
public class TestU {
    public static void multiThreadSimple(MultiThreadSimpleTemplate.Exec exec) {
        new MultiThreadSimpleTemplate().run(exec, null, null);
    }

    public static void multiThreadSimple(MultiThreadSimpleTemplate.Exec exec, int totalNum, int threadNum) {
        new MultiThreadSimpleTemplate().run(totalNum, threadNum, exec, null, null);
    }

    public static void multiThreadSimple(MultiThreadSimpleTemplate.Exec exec, MultiThreadSimpleTemplate.BeforeExec beforeExec, 
                                         MultiThreadSimpleTemplate.AfterExec afterExec, int totalNum, int threadNum) {
        new MultiThreadSimpleTemplate().run(totalNum, threadNum, exec, beforeExec, afterExec);
    }

    private static class MultiThreadSimpleTemplate {
        // 总访问量是totalNum，并发量是threadNum
        private int totalNum = 1000;
        private int threadNum = 10;

        private int count = 0;
        private float sumExecTime = 0;
        private long firstExecTime = Long.MAX_VALUE;
        private long lastDoneTime = Long.MIN_VALUE;

        public void run(int totalNum, int threadNum, Exec exec, BeforeExec beforeExec, AfterExec afterExec) {
            this.totalNum = totalNum;
            this.threadNum = threadNum;
            this.run(exec, beforeExec, afterExec);
        }

        public void run(Exec exec, BeforeExec beforeExec, AfterExec afterExec) {
            if(beforeExec != null) {
                if(!beforeExec.beforeExec()) {
                    System.out.println("BeforeExec返回false, 中断运行");
                }
            }

            final ConcurrentHashMap<Integer, ThreadRecord> records = new ConcurrentHashMap<Integer, ThreadRecord>();

            // 建立ExecutorService线程池，threadNum个线程可以同时访问
            ExecutorService es = Executors.newFixedThreadPool(threadNum);
            final CountDownLatch doneSignal = new CountDownLatch(totalNum); // 此数值和循环的大小必须一致

            for (int i = 0; i < totalNum; i++) {
                Runnable run = () -> {
                    try {
                        int index = ++count;
                        long systemCurrentTimeMillis = System.currentTimeMillis();

                        exec.exec();

                        records.put(index, new ThreadRecord(systemCurrentTimeMillis, System.currentTimeMillis()));
                    } catch (Exception e) {
                        e.printStackTrace();
                    } finally {
                        // 每调用一次countDown()方法，计数器减1
                        doneSignal.countDown();
                    }
                };
                es.execute(run);
            }

            try {
                // 计数器大于0时，await()方法会阻塞程序继续执行。直到所有子线程完成(每完成一个子线程，计数器-1)
                doneSignal.await();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            // 获取每个线程的开始时间和结束时间
            for (int i : records.keySet()) {
                ThreadRecord r = records.get(i);
                sumExecTime += ((double) (r.endTime - r.startTime)) / 1000;

                if (r.startTime < firstExecTime) {
                    firstExecTime = r.startTime;
                }
                if (r.endTime > lastDoneTime) {
                    this.lastDoneTime = r.endTime;
                }
            }

            float avgExecTime = this.sumExecTime / records.size();
            float totalExecTime = ((float) (this.lastDoneTime - this.firstExecTime)) / 1000;
            NumberFormat nf = NumberFormat.getNumberInstance();
            nf.setMaximumFractionDigits(4);

            // 需要关闭，否则JVM不会退出。(如在Springboot项目的Job中切勿关闭)
            es.shutdown();

            System.out.println("======================================================");
            System.out.println("线程数量:\t" + threadNum + " 个");
            System.out.println("总访问量:\t" + totalNum + " 次");
            System.out.println("平均执行时间:\t" + nf.format(avgExecTime) + " 秒");
            System.out.println("总执行时间:\t" + nf.format(totalExecTime) + " 秒");
            System.out.println("吞吐量:\t\t" + nf.format(totalNum / totalExecTime) + " 次/秒");
            System.out.println("======================================================");

            if(afterExec != null) {
                afterExec.afterExec();
            }
        }

        private static class ThreadRecord {
            long startTime;
            long endTime;

            ThreadRecord(long st, long et) {
                this.startTime = st;
                this.endTime = et;
            }
        }

        @FunctionalInterface
        public interface BeforeExec {
            boolean beforeExec();
        }

        @FunctionalInterface
        public interface Exec {
            void exec();
        }

        @FunctionalInterface
        public interface AfterExec {
            void afterExec();
        }
    }
}
```

### 基于GroboUtils

- 多线程测试(基于Junit+[GroboUtils](http://groboutils.sourceforge.net/))
	- 安装依赖

		```xml
		<!-- 第三方库 -->
		<repositories>
			<repository>
				<id>opensymphony-releases</id>
				<name>Repository Opensymphony Releases</name>
				<url>https://oss.sonatype.org/content/repositories/opensymphony-releases</url>
			</repository> 
		</repositories>
		
		<dependency> 
			<groupId>net.sourceforge.groboutils</groupId> 
			<artifactId>groboutils-core</artifactId> 
			<version>5</version> 
		</dependency>
		```
	- 使用

		```java
		@Test
		public void multiRequestsTest() {
			int runnerCount = 100; // 并发数
			// 构造一个Runner
			TestRunnable runner = new TestRunnable() {
				@Override
				public void runTest() throws Throwable {
					// TODO 测试内容
					// Thread.sleep(1000); // 结合sleep表示业务处理过程，测试效果更加明显
					System.out.println("===>" + Thread.currentThread().getId());
				}
			};

			TestRunnable[] arrTestRunner = new TestRunnable[runnerCount];
			for (int i = 0; i < runnerCount; i++) {
				arrTestRunner[i] = runner; 
			}
			MultiThreadedTestRunner mttr = new MultiThreadedTestRunner(arrTestRunner);
			try {
				mttr.runTestRunnables();
			} catch (Throwable e) {
				e.printStackTrace();
			}
		}
		```


---

参考

[^1]: https://blog.csdn.net/fanxiaobin577328725/article/details/78407199
