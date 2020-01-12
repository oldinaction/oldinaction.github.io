---
layout: "post"
title: "并发编程"
date: "2018-12-05 14:28"
categories: java
tags: [concurrence]
---

## 简介

- Java 的并行 API 演变历程
    - 1.0-1.4 中的 java.lang.Thread 
    - 5.0 中的 java.util.concurrent(JUC)
    - 6.0 中的 Phasers 等
    - 7.0 中的 Fork/Join 框架
    - 8.0 中的 Lambda(如Stream)
- https://www.cnblogs.com/dolphin0520/category/1426288.html

## 线程基础

- 线程的相关方法(sleep/yield/join)
    - `Thread.sleep()`和`wait`的区别 [^4]
        - sleep是Thread类的方法，wait是Object类中定义的方法
        - sleep和wait都会暂停当前的线程，对于CPU资源来说，不管是哪种方式暂停的线程，都表示它暂时不再需要CPU的执行时间，OS会将执行时间分配给其它线程。区别是，调用wait后，需要别的线程执行notify/notifyAll才能够重新获得CPU执行时间；而sleep到达一定时间则会继续执行
        - sleep不会导致锁行为的改变。所谓sleep是指让线程暂停被调度一段时间，或者挂起一段时间。整个sleep过程除了修改挂起状态之外，不会动任何其他的资源，这些资源包括任何持有的任何形式的锁。至于认为sleep消耗资源的情况如下：如果A线程抢到一把锁，然后sleep，B线程无论如何也无法获取该锁，从而B的执行被卡住，浪费了CPU
    - `Thread.yield()`：当前线程让出CPU一小会调度其他线程，并进入等待队列等待CPU的下次调度，也可能存在让出CPU之后仍然调度的是此线程
    - `join()`：CPU执行A线程一段时间，当在A线程的代码中遇到b.join()，此时CPU会到B线程中去执行，等B执行完后再回到A线程继续执行。感觉像把B线程加入到A线程
- 线程的状态

    ![thread-state](/data/images/java/thread-state.png)
- synchronized关键字

## JUC(java.util.concurrent)



## 常用类

### ExecutorService [^1]

- `java.util.concurrent.ExecutorService` **接口**表述了异步执行的机制，并且可以让任务在后台执行。一个 ExecutorService 实例因此特别像一个线程池。事实上，在 java.util.concurrent 包中的 ExecutorService 的实现就是一个线程池的实现
- ExecutorService接口继承了`Executor`接口，其实现类如下
    - `ThreadPoolExecutor`(见下文)
    - `ScheduledThreadPoolExecutor`
- ExecutorService有如下方法
    - `execute(Runnable)` **以异步方式执行**，参数接收的Runnable实例任务线程，主线程中无法获取任务结果。可能出现主线提前结束导致JVM退出，致使子线程未运行完成。可结合`CountDownLatch`类实现阻塞主线程直到子线程完成
    - `submit(Runnable)` 与execute不同的是submit会返回一个 `Future` 对象(可以用于判断 Runnable 是否结束执行)。调用`Future.get()`则等价于同步执行
    - `submit(Callable)` 接收的 Callable 的实例与 Runnable 的实例很类似，但是 Callable.call() 方法可以返回一个结果，Runnable.run() 则不能返回结果；其返回的结果可以被 Future 对象接收。**调用`Future.get()`后，主线程会等待结果返回才会继续执行，此时等价于同步执行；如果不调用`Future.get()`则主线程不会阻塞**
    - `invokeAny(...)` 收一个包含 Callable 对象的集合作为参数，不会返回 Future 对象，而是**随机**返回集合中某一个 Callable 对象的结果；**如果一个任务运行完毕或者抛出异常，方法会取消其它的 Callable 的执行**
    - `invokeAll(...)` 会调用存在于参数集合中的所有 Callable 对象，并且返回一个包含 Future 对象的集合；可以通过这个返回的集合来得知每个 Callable 的是否执行完成(无法得知是出错提前完成还是执行成功)。**主线程会阻塞在invokeAll调用后等待所有子线程结束**
- ExecuteService服务的关闭
    - 当使用 ExecutorService 完毕之后应该关闭它，这样才能保证线程不会继续保持运行状态
    - 如果程序通过 main() 方法启动，并且主线程退出了，如果你还有一个活动的 ExecutorService 存在于程序中，那么程序将会继续保持运行状态。存在于 ExecutorService 中的活动线程会阻止Java虚拟机关闭。对于`execute(Runnable)`中的子线程不能阻止JVM退出
    - 为了关闭在 ExecutorService 中的线程，需要调用 `shutdown()` 方法。ExecutorService 并不会马上关闭，而是不再接收新的任务，一但所有执行当前任务的线程结束，ExecutorServie 才会真的关闭。**所有在调用 shutdown() 方法之前提交到 ExecutorService 的任务都会执行**
    - 立即关闭 ExecutorService，可以调用 `shutdownNow()` 方法。这个方法会尝试马上关闭所有正在执行的任务，并且跳过所有已经提交但是还没有运行的任务。但是对于正在执行的任务，是否能够成功关闭它是无法保证的，有可能他们真的被关闭掉了，也有可能它会一直执行到任务结束
- 简单案例

```java
/**
 * 结果：
 * End...
 * Asynchronous task...(是否打印是不确定的)
 */
@Test
public void execute() {
    ExecutorService executorService = Executors.newFixedThreadPool(10);

    executorService.execute(new Runnable() {
        @Override
        public void run() {
            // 睡眠后则不会打印"Asynchronous task..."
            // try {
            //     Thread.sleep(1000);
            // } catch (InterruptedException e) {
            //     e.printStackTrace();
            // }

            System.out.println("Asynchronous task...");
        }
    });

    System.out.println("End...");
    
    executorService.shutdown();
}

/**
 * 结果：
 * run...
 * future.get()=null
 * call...
 * future2.get() = my result...
 * end...
 */
@Test
public void submit() throws ExecutionException, InterruptedException {
    ExecutorService executorService = Executors.newFixedThreadPool(10);

    // #1
    Future future = executorService.submit(new Runnable() {
        public void run() {
            try {
                Thread.sleep(3000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }

            System.out.println("run...");
        }
    });
    // 如果任务结束执行则返回 null。注意：只有调用了`future.get()`才会阻塞主线程
    System.out.println("future.get()=" + future.get());

    // #2
    Future future2 = executorService.submit(new Callable<Object>() {
        @Override
        public Object call() throws Exception {
            System.out.println("call...");
            return "my result...";
        }
    });
    // 注意：只有调用了`future.get()`才会阻塞主线程
    System.out.println("future2.get() = " + future2.get()); // 如果省略此行，可能会先打印 end... ，再打印 call...

    System.out.println("end...");
}
```

### ThreadPoolExecutor

- 在操作系统中，线程是一个非常重要的资源，频繁创建和销毁大量线程会大大降低系统性能。Java线程池原理类似于数据库连接池，目的就是帮助实现线程复用，减少频繁创建和销毁线程 [^2]
- 常用构造方法`ThreadPoolExecutor(int corePoolSize, int maximumPoolSize, long keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue)`
    - `corePoolSize` 核心线程数量。默认情况下核心线程会一直存活，即使处于闲置状态也不会受存keepAliveTime限制，除非将allowCoreThreadTimeOut设置为true
    - `maximumPoolSize` 最大线程数量。超过这个数的线程将被阻塞，当任务队列为没有设置大小的LinkedBlockingDeque时，这个值无效
    - `keepAliveTime`：当线程池中线程数量大于核心线程数量，如果一个线程的空闲时间大于keepAliveTime，则该线程会被销毁
    - `unit` 是keepAliveTime的时间单位，如`TimeUnit.SECONDS`
    - `workQueue` 阻塞队列。常用的有三种队列，`LinkedBlockingDeque`、`ArrayBlockingQueue`、`SynchronousQueue`
    - `ThreadFactory`参数：the factory to use when the executor creates a new thread
    - `RejectedExecutionHandler`参数：当线程池中的资源已经全部使用，添加新线程被拒绝时，会调用RejectedExecutionHandler的rejectedExecution方法(**此时可能出现创建的线程超过定义的最大线程数**)。在 ThreadPoolExecutor 里面定义了4种 handler 策略
        - `CallerRunsPolicy`：这个策略重试添加当前的任务，他会自动重复调用 execute() 方法，直到成功
        - `AbortPolicy`：对拒绝任务抛弃处理，并且抛出异常
        - `DiscardPolicy`：对拒绝任务直接无声抛弃，没有异常信息
        - `DiscardOldestPolicy`：对拒绝任务不抛弃，而是抛弃队列里面等待最久的一个线程，然后把拒绝任务加到队列
- **线程池添加任务的整个流程**
    - 线程池刚刚创建是，线程数量为0
    - 执行`execute`添加新的任务时会在线程池创建一个新的线程
    - 当线程数量达到`corePoolSize`时，再添加新任务则会将任务放到`workQueue`队列
    - 当队列已满，放不下新的任务，再添加新任务则会继续创建新线程，但线程数量不超过`maximumPoolSize`
    - 当线程数量达到`maximumPoolSize`时，再添加新任务则会抛出异常，如`RejectedExecutionException`
- 完整示例

```java
@Bean
public ExecutorService myExecutorService() {
    ThreadFactory threadFactory = new ThreadFactoryBuilder().setNameFormat("my-pool-%d").build();
    return new ThreadPoolExecutor(5, 200, 0, TimeUnit.MILLISECONDS,
            new LinkedBlockingQueue<Runnable>(1024), threadFactory, new ThreadPoolExecutor.AbortPolicy());
}
```

### ScheduledThreadPoolExecutor


### Semaphore

- https://www.cnblogs.com/skywang12345/category/455711.html


### Fork/Join

- Fork/Join 框架是 Java7 提供了的一个用于并行执行任务的框架， 是一个把大任务分割成若干个小任务，最终汇总每个小任务结果后得到大任务结果的框架 [^3]
- 工作窃取算法：工作窃取(work-stealing)算法是指某个线程从其他队列里窃取任务来执行
    - 假如我们需要做一个比较大的任务，我们可以把这个任务分割为若干互不依赖的子任务，为了减少线程间的竞争，于是把这些子任务分别放到不同的队列里，并为每个队列创建一个单独的线程来执行队列里的任务，线程和队列一一对应
    - 当某个一个队列执行完成后，空闲的线程回去执行其他为完成队列的任务。通常使用`双端队列`，正常线程从头部获取任务，窃取线程从尾部获取任务
- Fork/Join 使用两个类来完成以上两件事情
    - `ForkJoinTask`：它提供在任务中执行 `fork()` 和 `join()` 操作的机制，通常情况下只需要继承下列子类
        - **`RecursiveAction`**：用于没有返回结果的任务
        - **`RecursiveTask`**：用于有返回结果的任务
    - **`ForkJoinPool`**：ForkJoinTask 需要通过 ForkJoinPool 来执行
- 简单案例

```java
public class Simple {
    public static void main(String ... args) throws ExecutionException, InterruptedException, TimeoutException {
        int[] array = {100,400,200,90,80,300,600,10,20,-10,30,2000,1000};

        // 默认取计算机核心数，也可自定义线程数
        ForkJoinPool pool = new ForkJoinPool();
        // 注意此处结束取的数组的最后一个下标值
        MaxNumberTask task = new MaxNumberTask(array, 0, array.length - 1);
        Future<Integer> future = pool.submit(task);

        // 注意：只有调用了`future.get()`才会阻塞主线程。表示1秒钟为获取到就放弃阻塞，直接报错TimeoutException
        System.out.println("Result:" + future.get(1, TimeUnit.SECONDS));
        System.out.println("end...");
    }

    // RecursiveAction：用于没有返回结果的任务
    /// RecursiveTask ：用于有返回结果的任务
    private static class MaxNumberTask extends RecursiveTask<Integer> {
        // 当任务大小大于此值是才进行任务分割
        private static final int THRESHOLD = 5;

        // the data array
        private int[] array;

        private int start = 0;
        private int end = 0;

        public MaxNumberTask(int[] array, int start, int end) {
            this.array = array;
            this.start = start;
            this.end = end;
        }

        @Override
        protected Integer compute() {
            int max = Integer.MIN_VALUE;

            // 注意：此处是数值相减进行判断
            if ((end - start) <= THRESHOLD) {
                // 注意：此处是取下标值
                for (int i = start;i <= end; i ++) {
                    // try {
                    //     Thread.sleep(1000);
                    // } catch (InterruptedException e) {
                    //     e.printStackTrace();
                    // }

                    max = Math.max(max, array[i]);
                }
            } else {
                // fork/join
                int mid = start + (end - start) / 2;
                MaxNumberTask lMax = new MaxNumberTask(array, start, mid);
                MaxNumberTask rMax = new MaxNumberTask(array, mid + 1, end);

                // 执行任务
                lMax.fork();
                rMax.fork();

                // 等待子任务结束并得到子结果
                int lm = lMax.join();
                int rm = rMax.join();

                // 合并子结果
                max = Math.max(lm, rm);
            }

            return max;
        }
    }
}
```

## 多线程测试

### 测试模板

```java
public abstract class AbstractMultiThreadTestSimpleTemplate {
    // 测试案例=========================================================================================
    static class DemoTest extends AbstractMultiThreadTestSimpleTemplate {
        public static void main(String[] args) {
            // 总共测试执行10000遍，100个并发
            new DemoTest().run(10000, 100);
        }

        @Override
        public void beforeExec() {}

        @Override
        public void exec() {
            System.out.println(Thread.currentThread().getName() + "测试内容...");
        }

        @Override
        public void afterExec() {}
    }

    // 测试模板=========================================================================================
    // 总访问量是totalNum，并发量是threadNum
    private static int totalNum = 100;
    private static int threadNum = 5;

    private static int count = 0;
    private float sumExecTime = 0;
    private long firstExecTime = Long.MAX_VALUE;
    private long lastDoneTime = Long.MIN_VALUE;

    public abstract void beforeExec();
    public abstract void exec();
    public abstract void afterExec();

    public void run(int totalNum, int threadNum) {
        AbstractMultiThreadTestSimpleTemplate.totalNum = totalNum;
        AbstractMultiThreadTestSimpleTemplate.threadNum = threadNum;
        this.run();
    }

    public void run() {
        beforeExec();

        final ConcurrentHashMap<Integer, ThreadRecord> records = new ConcurrentHashMap<Integer, ThreadRecord>();

        // 建立ExecutorService线程池，threadNum个线程可以同时访问
        ExecutorService es = Executors.newFixedThreadPool(threadNum);
        final CountDownLatch doneSignal = new CountDownLatch(totalNum); // 此数值和循环的大小必须一致

        for (int i = 0; i < totalNum; i++) {
            Runnable run = new Runnable() {
                public void run() {
                    try {
                        int index = ++count;
                        long systemCurrentTimeMillis = System.currentTimeMillis();

                        exec();

                        records.put(index, new ThreadRecord(systemCurrentTimeMillis, System.currentTimeMillis()));
                    } catch (Exception e) {
                        e.printStackTrace();
                    } finally {
                        // 每调用一次countDown()方法，计数器减1
                        doneSignal.countDown();
                    }  
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
        System.out.println("线程数量:\t\t" + threadNum);
        System.out.println("客户端数量:\t" + totalNum);
        System.out.println("平均执行时间:\t" + nf.format(avgExecTime) + "秒");
        System.out.println("总执行时间:\t" + nf.format(totalExecTime) + "秒");
        System.out.println("吞吐量:\t\t" + nf.format(totalNum / totalExecTime) + "次每秒");

        afterExec();
    }

    class ThreadRecord {
        long startTime;
        long endTime;

        ThreadRecord(long st, long et) {
            this.startTime = st;
            this.endTime = et;
        }
    }
}
```






---

参考文章

[^1]: https://my.oschina.net/bairrfhoinn/blog/177639 (ExecutorService 的理解与使用)
[^2]: https://blog.csdn.net/xiao__gui/article/details/51064317
[^3]: https://www.infoq.cn/article/fork-join-introduction
[^4]: https://www.zhihu.com/question/23328075

