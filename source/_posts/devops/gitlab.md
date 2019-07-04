---
layout: "post"
title: "gitlab"
date: "2016-11-20 10:39"
categories: [devops]
tags: [git]
---

## gitlab介绍

[gitlab官方文档](https://docs.gitlab.com/omnibus/README.html)。如[centos7安装](https://about.gitlab.com/downloads/#centos7)

### 常用命令

- `sudo gitlab-ctl restart` 重新启动
- `sudo gitlab-ctl reconfigure` 重新配置（运行中的项目，重新配置后，数据也不会丢失）

## 备份与恢复 [^1]

### 备份

- 新建备份目录

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

        ```
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

