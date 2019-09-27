---
layout: "post"
title: "软件测试"
date: "2019-09-26 22:04"
categories: [extend]
tags: [test]
---

## 软件测试

### 数据库

## 硬件测试

### 磁盘

#### fio 工具

- fio使用

```bash
## 安装
yum install -y fio

## 常见参数
-filename=/data/test        # 支持文件、文件系统或者裸设备，可以通过冒号分割。-filename=/dev/sda2或-filename=/dev/sdb:/dev/sdc
-direct=1                   # 测试过程绕过机器自带的buffer，使测试结果更真实
-iodepth=4                  # io深度为4。如果ioengine采用异步方式，该参数表示一批提交保持的io单元数
-rw                         # 测试读写模式
    -rw=randwread             # 测试随机读的I/O
    -rw=randwrite             # 测试随机写的I/O
    -rw=randrw                # 测试随机混合写和读的I/O
    -rw=read                  # 测试顺序读的I/O
    -rw=write                 # 测试顺序写的I/O
    -rw=rw                    # 测试顺序混合写和读的I/O
-ioengine=libaio              # io引擎使用libaio | pync方式，如果要使用libaio引擎，可能需要`yum install libaio-devel`包。默认值是sync同步阻塞I/O，libaio是Linux的native异步I/O
-bs=4k                      # 单次io的块文件大小为4k。默认是4k
-size=2G                    # 本次的测试文件大小为2g，以每次4k的io进行测试。**注意：会在上述文件(/data/test)中写入2G的数据**
-numjobs=4                  # 本次的测试线程为4
-runtime=60                 # 测试时间为60秒，如果不写则一直将2g文件每次分4k写完为止
-group_reporting            # 关于显示结果的，汇总每个进程的信息
-lockmem=1g                 # 只使用1g内存进行测试
-name=Rand_Write_Testing    # 测试名称

## 结果参数说明
bw              # 磁盘的吞吐量，是顺序读写的关键指标
iops            # 磁盘的每秒读写次数，是随机读写的关键指标

io              # 执行了多少M的IO
slat            # 提交延迟
clat            # 完成延迟
lat             # 响应时间
cpu             # 利用率
IO depths       # io队列
IO submit       # 单个IO提交要提交的IO数
IO latencies    # IO完延迟的分布
ios             # 所有group总共执行的IO数
merge           # 总共发生的IO合并数
io_queue        # 花费在队列上的总共时间
util            # 磁盘利用率
```

- 使用案例

```bash
touch ~/test
## 执行测试
fio -filename=~/test -direct=1 -iodepth=4 -rw=randrw -ioengine=libaio -bs=4k -size=2G -numjobs=4 -runtime=60 -group_reporting -name=Rand_Write_Testing

## 测试结果
Rand_Write_Testing: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=4
...
fio-3.7
Starting 4 processes
Jobs: 4 (f=4): [m(4)][100.0%][r=520KiB/s,w=528KiB/s][r=130,w=132 IOPS][eta 00m:00s]
Rand_Write_Testing: (groupid=0, jobs=4): err= 0: pid=65409: Thu Sep 26 22:26:30 2019
    # iops：磁盘的每秒读写次数，是随机读写的关键指标
    # bw：磁盘的吞吐量，是顺序读写的关键指标
   read: IOPS=118, BW=476KiB/s (487kB/s)(27.9MiB/60153msec)
    slat (usec): min=9, max=2860, avg=113.39, stdev=95.48
    clat (usec): min=313, max=633045, avg=105460.90, stdev=79132.38
     lat (usec): min=373, max=633117, avg=105575.35, stdev=79131.82
    clat percentiles (msec):
     |  1.00th=[    7],  5.00th=[   15], 10.00th=[   24], 20.00th=[   41],
     | 30.00th=[   58], 40.00th=[   74], 50.00th=[   90], 60.00th=[  107],
     | 70.00th=[  129], 80.00th=[  159], 90.00th=[  205], 95.00th=[  247],
     | 99.00th=[  368], 99.50th=[  489], 99.90th=[  617], 99.95th=[  634],
     | 99.99th=[  634]
   bw (  KiB/s): min=    7, max=  208, per=25.01%, avg=118.80, stdev=32.14, samples=480
   iops        : min=    1, max=   52, avg=29.57, stdev= 8.06, samples=480
  write: IOPS=123, BW=496KiB/s (508kB/s)(29.1MiB/60153msec)
    slat (usec): min=3, max=4135, avg=168.92, stdev=137.05
    clat (usec): min=5, max=598543, avg=27452.72, stdev=44430.15
     lat (usec): min=272, max=598684, avg=27622.73, stdev=44432.87
    clat percentiles (usec):
     |  1.00th=[   253],  5.00th=[   371], 10.00th=[   660], 20.00th=[  1287],
     | 30.00th=[  2212], 40.00th=[  3032], 50.00th=[  5538], 60.00th=[ 15795],
     | 70.00th=[ 32375], 80.00th=[ 52691], 90.00th=[ 78119], 95.00th=[101188],
     | 99.00th=[177210], 99.50th=[261096], 99.90th=[522191], 99.95th=[574620],
     | 99.99th=[599786]
   bw (  KiB/s): min=    8, max=  264, per=25.07%, avg=124.10, stdev=46.77, samples=480
   iops        : min=    2, max=   66, avg=30.90, stdev=11.71, samples=480
  lat (usec)   : 10=0.02%, 250=0.44%, 500=3.46%, 750=1.84%, 1000=2.14%
  lat (msec)   : 2=6.14%, 4=9.95%, 10=4.78%, 20=7.10%, 50=16.85%
  lat (msec)   : 100=23.26%, 250=21.41%, 500=2.31%, 750=0.28%
  cpu          : usr=0.01%, sys=1.01%, ctx=14029, majf=0, minf=147
  IO depths    : 1=0.1%, 2=0.1%, 4=99.9%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=7154,7456,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4

Run status group 0 (all jobs):
   READ: bw=476KiB/s (487kB/s), 476KiB/s-476KiB/s (487kB/s-487kB/s), io=27.9MiB (29.3MB), run=60153-60153msec
  WRITE: bw=496KiB/s (508kB/s), 496KiB/s-496KiB/s (508kB/s-508kB/s), io=29.1MiB (30.5MB), run=60153-60153msec

Disk stats (read/write):
    dm-0: ios=7278/7740, merge=0/0, ticks=771957/230269, in_queue=1002796, util=100.00%, aggrios=7278/7717, aggrmerge=0/23, aggrticks=772177/225811, aggrin_queue=997990, aggrutil=100.00%
  sda: ios=7278/7717, merge=0/23, ticks=772177/225811, in_queue=997990, util=100.00%
```
- 基于配置文件测试

```bash
# 基于下文配置文件fio.conf进行测试
fio fio.conf

# 复制下面的配置内容，将directory=/path/to/test修改为测试硬盘挂载目录的地址，并另存为fio.conf
[global]
ioengine=libaio
direct=1
thread=1
norandommap=1
randrepeat=0
runtime=60
ramp_time=6
size=1g
directory=/path/to/test

[read4k-rand]
stonewall
group_reporting
bs=4k
rw=randread
numjobs=8
iodepth=32

[read64k-seq]
stonewall
group_reporting
bs=64k
rw=read
numjobs=4
iodepth=8

[write4k-rand]
stonewall
group_reporting
bs=4k
rw=randwrite
numjobs=2
iodepth=4

[write64k-seq]
stonewall
group_reporting
bs=64k
rw=write
numjobs=2
iodepth=4
```




