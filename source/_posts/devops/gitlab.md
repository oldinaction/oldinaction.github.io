---
layout: "post"
title: "Gitlab"
date: "2016-11-20 10:39"
categories: [devops]
tags: [git]
---

## gitlab介绍

- [Gitlab 官方文档](https://docs.gitlab.com/)
- [Gitlab 中文文档](https://www.bookstack.cn/read/gitlab-doc-zh/README.md)
- Gitlab有CE社区免费版和EE企业收费版
- GitLab 可充当 Maven、Npm、Pypi、Docker 等存储库

### 常用命令

- `sudo gitlab-ctl restart` 重新启动
- `sudo gitlab-ctl reconfigure` 重新配置（运行中的项目，重新配置后，数据也不会丢失）

## 安装

- CE社区版Linux安装包镜像: https://mirror.tuna.tsinghua.edu.cn/gitlab-ce/
    - CE社区版安装参考: https://blog.51cto.com/u_16213672/10409442
- CE社区版Docker镜像: https://hub.docker.com/r/gitlab/gitlab-ce/tags EE企业版镜像: https://hub.docker.com/r/gitlab/gitlab-ee/tags
    - Docker安装CE版参考: https://blog.csdn.net/weixin_42286658/article/details/144768578
- **Docker安装CE版**

```bash
# 安装Docker: 参考[docker.md](/_posts/devops/docker.md#安装)

# 拉取镜像
docker pull gitlab/gitlab-ce

mkdir -p /home/gitlab/etc #安装程序目录
mkdir -p /home/gitlab/opt #数据目录
mkdir -p /home/gitlab/log #日志目录

# 启动容器
# 8180端口: gitlab管理页面端口; 8122端口: SSH端口，拉代码时的端口
# Window的路径可以为`-v D:\gitlab\etc:/etc/gitlab`
docker run -itd -p 8180:80 -p 8122:22 -v /home/gitlab/etc:/etc/gitlab -v /home/gitlab/log:/var/log/gitlab -v /home/gitlab/opt:/var/opt/gitlab --restart always --privileged=true --name gitlab gitlab/gitlab-ce

# 修改配置
vi /home/gitlab/etc/gitlab.rb
# 取消external_url注释，地址为宿主机地址，不需要设置端口；并设置ssh主机IP和端口
external_url 'http://192.168.1.100'
gitlab_rails['gitlab_ssh_host'] = '192.168.1.100'
gitlab_rails['gitlab_shell_ssh_port'] = 8122

# 修改root密码
docker exec -it gitlab /bin/bash # 进入容器内部
gitlab-rails console -e production # 进入gitlab控制台
user = User.where(id:1).first # 查询id为1的用户，id为1的用户是超级管理员
user.password='root123456' # 修改密码为root123456
user.save! # 保存
exit # 退出(需要执行两次)

# 重载服务
docker exec -t gitlab gitlab-ctl reconfigure
docker exec -t gitlab gitlab-ctl restart

# 访问 http://192.168.1.100:8180
```

## 备份与恢复

### 备份

- 新建备份目录 [^1]

```bash
mkdir -p /data/backup/gitlab
chown -R root /data/backup/gitlab
chmod -R 777 /data/backup/gitlab
```
- 备份配置 `sudo vim /etc/gitlab/gitlab.rb`

```bash
gitlab_rails['manage_backup_path'] = true
gitlab_rails['backup_path'] = "/data/backup/gitlab"     # gitlab备份目录
gitlab_rails['backup_archive_permissions'] = 0644       # 生成的备份文件权限
gitlab_rails['backup_keep_time'] = 7776000              # 备份保留7天，即604800秒
```
- 重载配置 `sudo gitlab-ctl reconfigure`
- 手动备份 `sudo gitlab-rake gitlab:backup:create --trace`
- 自动备份
    - `sudo vim /etc/crontab` 打开定时配置文件
    - `0 2 * * * /opt/gitlab/bin/gitlab-rake gitlab:backup:create`(每天凌晨2点进行备份)，添加到定时配置文件中
    - `systemctl reload crond` 重新加载配置

### 恢复

```bash
# 停止相关数据连接服务
gitlab-ctl stop unicorn
gitlab-ctl stop sidekiq

# 从相应编号备份中恢复 1510472027_2017_11_12_9.4.5_gitlab_backup.tar
gitlab-rake gitlab:backup:restore BACKUP=1510472027_2017_11_12_9.4.5

# 启动Gitlab
sudo gitlab-ctl start

# 可检查恢复情况
gitlab-rake gitlab:check SANITIZE=true
```

## 问题集锦

- 访问项目首页(如：http://114.55.888.888/)，结果页面不显示，地址栏的地址变成 http://gitlab/users/sign_in
    - 尝试方法：首先确保`/etc/gitlab/gitlab.rb`中的设置了`external_url`（如：`external_url "http://www.example.com"`），如果设置了，运行命令重新配置（`sudo gitlab-ctl reconfigure`，无需重启）。
- 页面显示`Forbidden`问题 [^2]
    - 主要是gitlab做了rack_attack防止攻击，针对某个IP并发过大，就会限制那个IP的访问，解决办法就是把宿主机IP加入到白名单当中。
    - 去掉配置注释 `vi /etc/gitlab/gitlab.rb`

        ```js
        gitlab_rails['rack_attack_git_basic_auth'] = {
            'enabled' => true,
            'ip_whitelist' => ["127.0.0.1","10.10.10.10"],
            'maxretry' => 300,
            'findtime' => 5,
            'bantime' => 60
        }
        ```
    - 重新加载配置并重启服务 `gitlab-ctl reconfigure`

## 管理员

- 管理员登录可在界面上对gitlab进行基本配置
- 找回管理员密码：https://www.jianshu.com/p/25afcfd02019
- 设置项目上限：管理员登录访问：/admin/users/ 编辑用户设置项目上限

---

参考文章

[^1]: https://www.cnblogs.com/kevingrace/p/7821529.html (Gitlab备份和恢复操作记录)
[^2]: https://blog.csdn.net/jzd1997/article/details/80253905

