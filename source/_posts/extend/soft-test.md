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

- 块存储和文件存储的测试重点也不一样
    - 块存储测试：fio/iozone是两个典型的测试工具，重点测试IOPS，延迟和带宽

        ```bash
        # fio -filename=/dev/sdc -iodepth=${iodepth} -direct=1 -bs=${bs} -size=100% --rw=${iotype} -thread -time_based -runtime=600 -ioengine=${ioengine} -group_reporting -name=fioTest
        # 测试IOPS：iodepth=32/64/128，bs=4k/8k，rw=randread/randwrite，ioengine=libaio
        # 测试延迟：iodepth=1，bs=4k/8k，rw=randread/randwrite，ioengine=sync
        # 测试带宽：iodepth=32/64/128，bs=512k/1m，rw=read/write，ioengine=libaio
        ```
    - fio/vdbench/mdtest是测试文件系统常用的工具。fio/vdbench用来评估IOPS，延迟和带宽；mdtest评估文件系统元数据性能，主要测试指标是creation和stat，需要采用mpirun并发测试

        ```bash
        # fio -filename=/mnt/yrfs/fio.test -iodepth=1 -direct=1 -bs=${bs} -size=500G --rw=${iotype} -numjobs=${numjobs} -time_based -runtime=600 -ioengine=sync -group_reporting -name=fioTest
        # 与块存储的测试参数有一个很大区别，就是ioengine都是用的sync，用numjobs替换iodepth
        # 测试IOPS：bs=4k/8k，rw=randread/randwrite，numjobs=32/64
        # 测试延迟：bs=4k/8k，rw=randread/randwrite，numjobs=1
        # 测试带宽：bs=512k/1m，rw=read/write，numjobs=32/64

        # mpirun --allow-run-as-root -mca btl_openib_allow_ib 1 -host yanrong-node0:${slots},yanrong-node1:${slots},yanrong-node2:${slots} -np ${num_procs} mdtest -C -T -d /mnt/yrfs/mdtest -i 1 -I ${files_per_dir} -z 2 -b 8 -L -F -r -u
        ```

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

- 使用案例(基于阿里云80G SSD硬盘进行)

```bash
touch ~/test
## 执行测试
fio -filename=~/test -direct=1 -iodepth=4 -rw=randrw -ioengine=libaio -bs=4k -size=2G -numjobs=4 -runtime=60 -group_reporting -name=Rand_Write_Testing

## 测试结果
Rand_Write_Testing: (g=0): rw=randrw, bs=(R) 4096B-4096B, (W) 4096B-4096B, (T) 4096B-4096B, ioengine=libaio, iodepth=4
...
fio-3.7
Starting 4 processes
Rand_Write_Testing: Laying out IO file (1 file / 2048MiB)
Jobs: 4 (f=4): [m(4)][7.0%][r=5024KiB/s,w=4816KiB/s][r=1256,w=1204 IOPS][eta 13m:27s] 
Rand_Write_Testing: (groupid=0, jobs=4): err= 0: pid=2450: Fri Sep 27 18:30:30 2019
    # iops：磁盘的每秒读写次数，是随机读写的关键指标
    # bw：磁盘的吞吐量，是顺序读写的关键指标
   read: IOPS=1226, BW=4908KiB/s (5026kB/s)(288MiB/60032msec)
    slat (usec): min=2, max=8631, avg=44.76, stdev=80.70
    clat (usec): min=26, max=96665, avg=6108.77, stdev=18978.72
     lat (usec): min=469, max=96678, avg=6154.07, stdev=18977.56
    clat percentiles (usec):
     |  1.00th=[  594],  5.00th=[  668], 10.00th=[  717], 20.00th=[  791],
     | 30.00th=[  857], 40.00th=[  922], 50.00th=[ 1004], 60.00th=[ 1106],
     | 70.00th=[ 1237], 80.00th=[ 1500], 90.00th=[ 2507], 95.00th=[77071],
     | 99.00th=[82314], 99.50th=[83362], 99.90th=[84411], 99.95th=[84411],
     | 99.99th=[91751]
   bw (  KiB/s): min=  936, max= 1624, per=25.01%, avg=1227.33, stdev=85.25, samples=480
   iops        : min=  234, max=  406, avg=306.82, stdev=21.31, samples=480
  write: IOPS=1233, BW=4934KiB/s (5052kB/s)(289MiB/60032msec)
    slat (usec): min=3, max=2539, avg=44.86, stdev=71.18
    clat (usec): min=35, max=94244, avg=6796.74, stdev=19522.18
     lat (usec): min=513, max=94265, avg=6842.16, stdev=19521.01
    clat percentiles (usec):
     |  1.00th=[  635],  5.00th=[  734], 10.00th=[  799], 20.00th=[  906],
     | 30.00th=[ 1012], 40.00th=[ 1123], 50.00th=[ 1237], 60.00th=[ 1401],
     | 70.00th=[ 1614], 80.00th=[ 2040], 90.00th=[ 4621], 95.00th=[78119],
     | 99.00th=[82314], 99.50th=[83362], 99.90th=[85459], 99.95th=[86508],
     | 99.99th=[92799]
   bw (  KiB/s): min= 1008, max= 1600, per=25.01%, avg=1233.75, stdev=73.48, samples=480
   iops        : min=  252, max=  400, avg=308.42, stdev=18.37, samples=480
  lat (usec)   : 50=0.01%, 100=0.01%, 250=0.01%, 500=0.03%, 750=10.12%
  lat (usec)   : 1000=29.20%
  lat (msec)   : 2=43.84%, 4=7.64%, 10=2.17%, 20=0.42%, 50=0.07%
  lat (msec)   : 100=6.50%
  cpu          : usr=0.51%, sys=3.68%, ctx=114096, majf=0, minf=136
  IO depths    : 1=0.1%, 2=0.1%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, >=64=0.0%
     submit    : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     complete  : 0=0.0%, 4=100.0%, 8=0.0%, 16=0.0%, 32=0.0%, 64=0.0%, >=64=0.0%
     issued rwts: total=73655,74048,0,0 short=0,0,0,0 dropped=0,0,0,0
     latency   : target=0, window=0, percentile=100.00%, depth=4

Run status group 0 (all jobs):
   READ: bw=4908KiB/s (5026kB/s), 4908KiB/s-4908KiB/s (5026kB/s-5026kB/s), io=288MiB (302MB), run=60032-60032msec
  WRITE: bw=4934KiB/s (5052kB/s), 4934KiB/s-4934KiB/s (5052kB/s-5052kB/s), io=289MiB (303MB), run=60032-60032msec

Disk stats (read/write):
  vda: ios=73487/73884, merge=0/114, ticks=449091/500446, in_queue=950677, util=100.00%
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




