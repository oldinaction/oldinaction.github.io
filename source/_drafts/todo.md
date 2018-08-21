## 开发

### smtools

- ExceptionU接受Throwable对象实例化，在minions全局异常中抛出
- ExceptionU添加无权访问异常

### minions

- 去除session.setAttribute(BaseKeys.SessionUserInfo, userDetails);
- services目录名改为service
- pom中加入resource目录的资源,maven打包问题
- Result对象data参数中考虑多态保存map和object(只保存Map，保存object不太好取值)
- CustomAuthenticationProvider.authenticate 去除对usernamenotfound的捕获


### blog






## 课外
