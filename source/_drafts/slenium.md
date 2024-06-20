---
layout: "post"
title: "Selenium"
date: "2019-04-30 14:29"
categories: extend
tags: test
---

## 简介

- selenium 是一个 web 的自动化测试工具，开源。支持多平台，支持Java、Python、Perl、PHP、C#等语言进行测试脚本编写。支持ie、chrome、firefox、opera、safari等浏览器，支持录制
- selenium包含selenium1(早期版本)、selenium2(selenium1与webdriver合并版)、selenium3(兼容selenium2，去掉selenium RC等不常用功能)
- selenium套件
    - 录制工具(可将录制转换成基础脚本，也可直接编写脚本)：selenium ide(官方插件，可到chrome插件中下载)、katalon recorder
    - Selenium Grid：能并行的运行测试，也就是说，不同的测试可以同时跑在不同的远程机器上
- [官方Doc](https://docs.seleniumhq.org/docs/)、[github](https://github.com/SeleniumHQ/selenium)
- 本文基于python3 + selenium 4.9.0

## 安装

- 安装最新selenium版本 `pip install -U selenium` (需要安装python3)
- 安装对应版本chromedriver(否则为selenium内置chrome)
    
```py
# 查看chrome版本
chrome://settings/help

# 下载与本地chrome对应版本chromedriver，v2.33之前和chrome版本对照https://blog.csdn.net/morling05/article/details/81094151，
https://registry.npmmirror.com/binary.html

# 使用。参考：https://www.cnblogs.com/yhleng/p/9503819.html
from selenium import webdriver
# 此时自定义chrome驱动，则会自动启动系统chrome.exe，如果不行可设置chrome.exe到path
driver = webdriver.Chrome(r'D:\software\greensoft\chromedriver.exe')
# 使用selenium内置chrome.exe，selenium3内置chrome v50.0
driver = webdriver.Chrome()
```

## 简单案例

- 不用启动Chrome浏览器，只需安装即可

```py
# coding = utf-8
from selenium import webdriver

driver = webdriver.Chrome()  # 当然也可以换成 Ie 或 Firefox
driver.get("http://www.baidu.com")
driver.find_element_by_id("kw").send_keys("selenium")
driver.find_element_by_id("su").click()
driver.quit()
```

## XPath语法说明

```bash
## 绝对路径选择：从根节点开始的，到某个节点，每层都依次写下来，每层之间用 / 分隔的表达式，就是某元素的绝对路径
/html/body/div # 对应CSS的 `html>body>div`

## 相对路径选择：选择所有div元素里面的子节点p
//div//p # 可同时支持CSS的 `div>p` 和 `div p`

## 通配符*：选择所有div节点的所有直接子节点
//div/* # 对应CSS的 `div>*`

## 根据属性选择：选择所有class为a的b元素
//b[@class='a'] # 对应CSS的 `.a`
//*[@style='color'] # [style='color']
//*[contains(@class,'box')] # [class*='box'] 选择class属性包含box的所有元素
//*[starts-with(@a,'b')] # [a^='b'] 选择a属性开头为b的所有元素
//*[ends-with(@a,'b')] # [a$='b'] 选择a属性结尾为b的所有元素(xpath2.0语法，浏览器不支持)

## 按次序选择元素
//div/p[2] # `div p:nth-child(2)` 选择父元素为div中的p类型第2个子元素
//div/*[2] # `div :nth-child(2)` 选择父元素为div的第2个子元素
//p[last()-1] # `p:nth-last-child(2)` 选取p类型倒数第2个子元素

## 按范围选择元素
//option[position()<=2] # 选取option类型第1到2个子元素
//*[@class='a']/*[position()<=3] # 选择class属性为a的前3个子元素
//*[@class='a']/*[position()>=last()-2] # 选择class属性为a的后3个子元素

## 组选择
//*[@class='a'] | //*[@id='b'] # `.a , #b` 选所有class为a的元素，和所有id为b的元素

## 根据子节点选择父节点
//a/../.. # 查找后2代元素包含a元素的节点

## 兄弟节点选择
//*[@class='a']/following-sibling::* # `.a ~ *` 选择 class 为 a 的元素的所有后续兄弟节点
//*[@class='a']/preceding-sibling::* # 选择 class 为 a 的元素的所有前置兄弟节点
```

## 元素操作

- 查找元素

```python
# 查找一个元素，如果有多个取第一个
ele = self.driver.find_element(By.XPATH, '//*[@id="login"]')
self.driver.find_element(By.XPATH, '//*[contains(@class, "class1")]//*[contains(@class, "class1-2-1")]') # 类似CSS的 ".class1 .class1-2-1"
# 查找元素集合
trs = self.driver.find_elements(By.XPATH, '//*[contains(@class, ".tr")]')
# 串联查找，根据父元素查找子元素
trs[0].find_elements(By.XPATH, 'td')
```
- 给元素赋值

```python
# input输入框
ele.send_keys('ABC123') # 输入值
ele.clear() # 清空输入框
```
- 其他

```python
ele.click() # 点击元素
```

## 扩展功能

### 控制当前已经打开的chrome浏览器窗口

- 测试阶段常用
- 原理：先手动通过命令行启动浏览器，并开启调试模式(设置一个调试端口)；然后再通过Selenium连接
- 参考：https://blog.csdn.net/weixin_45081575/article/details/126389273
- 启动浏览器

```bash
# 找到可执行文件位置，如"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
chrome://version
# 命令行启动浏览器，并开启调试模式，也可通过python的`os.popen`执行命令; --user-data-dir会自动创建
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9528 --user-data-dir="/tmp/selenium"
```
- 代码

```py
import os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options

if __name__ == '__main__':
    os.system(r'"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9528 --user-data-dir="/tmp/selenium"')
	
	# 保证浏览器已经打开
    input('输入空格继续程序...')
	
    options = Options()
    # 此方法必须先通过命令行参数启动浏览器(启动前先关闭之前打开的浏览器，开发时不能开两个浏览器窗口)
    # 通过debuggerAddress进行附着进程，否则会重新启动一个浏览器实例
    options.add_experimental_option("debuggerAddress", "127.0.0.1:9528")
    browser = webdriver.Chrome(options=options)

    print(browser.title)
```

### Selenium获取Network数据

- 参考：https://blog.csdn.net/weixin_45081575/article/details/126551260
- 代码

```py
import json
from selenium import webdriver
from selenium.common.exceptions import WebDriverException
from selenium.webdriver import ChromeOptions
from webdriver_manager.chrome import ChromeDriverManager # pip install webdriver-manager

if __name__ == '__main__':
    caps = {
        "browserName": "chrome",
        'goog:loggingPrefs': {'performance': 'ALL'}  # 开启日志性能监听
    }
    options = ChromeOptions()
    # 自动根据安装的浏览器获取其对应的chromedriver版本
    DRIVER_PATH = ChromeDriverManager().install()
    browser = webdriver.Chrome(executable_path=DRIVER_PATH, desired_capabilities=caps, options=options)  # 启动浏览器
    browser.get('https://blog.csdn.net')

    performance_log = browser.get_log('performance')  # 获取名称为 performance 的日志
    for packet in performance_log:
        message = json.loads(packet.get('message')).get('message')  # 获取message的数据
        if message.get('method') != 'Network.responseReceived':  # 如果method 不是 responseReceived 类型就不往下执行
            continue
        packet_type = message.get('params').get('response').get('mimeType')  # 获取该请求返回的type
        if packet_type not in ['application/json']:  # 过滤type
            continue
        requestId = message.get('params').get('requestId')  # 唯一的请求标识符。相当于该请求的身份证
        url = message.get('params').get('response').get('url')  # 获取 该请求  url
        resp = browser.execute_cdp_cmd('Network.getResponseBody', {'requestId': requestId})  # selenium调用 cdp
        print(f'type: {packet_type} url: {url}, response: {resp}')
```

## 反爬技术

### 伪装请求端标识

- 使用[undetected_chromedriver](https://github.com/ultrafunkamsterdam/undetected-chromedriver)

```py
import undetected_chromedriver as uc
from webdriver_manager.chrome import ChromeDriverManager

options = ChromeOptions()
options.set_capability('goog:loggingPrefs', {'performance': 'ALL'}) # (可选)记录performance日志
self.driver = uc.Chrome(executable_path=ChromeDriverManager().install(), options=options)
self.hb56_performance = Hb56Performance(self.driver)
self.driver.get("https://www.baidu.com/")
```
- 使用stealth.min.js文件防止selenium被检测
    - [Selenium 最强反反爬方案来了](https://blog.csdn.net/wuShiJingZuo/article/details/115987011)

### 动态字体及字体加密

- [&#x开头的是什么编码](https://www.jianshu.com/p/6dcefb2a59b2)
    - [破解网站字体加密和反反爬虫](https://www.cnblogs.com/geeksongs/p/14351576.html)
    - [58同城字体加密&破解方法](https://www.cnblogs.com/q1ang/p/10176936.html)
    - 更有是每次请求都会返回随机字体，此时可将字体转成xml文件，然后根据xml中的`TTGlyph`属性进行分析，如下图0-9字体分析说明

    ![字体分析](/data/images/extend/%E5%AD%97%E4%BD%93%E5%88%86%E6%9E%90.jpg)

