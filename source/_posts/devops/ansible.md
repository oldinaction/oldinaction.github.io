---
layout: "post"
title: "Ansible"
date: "2019-09-30 14:51"
categories: devops
tags: [tool]
---

## 简介

- `Ansible` 是用于在可重复的方式将应用程序部署到远程节点和配置服务器的开源工具。类似的如：Chef，Puppet，SaltStack和Fabric [^1]

## 安装及使用

### 安装

```bash
## 在 Control Machine 上安装 Ansible(节点机器无需安装)
yum install -y epel-release
yum install -y ansible
ansible --version # 2.8.4
ansible -h # 查看帮助
```
### 使用(利用ansible批量部署zabbix-agent)

- `zabbix`就是目前比较好的一款开源监控软件 [^2]
    - 此案例需要提前安装zabbix-server，参考[http://blog.aezo.cn/2019/09/03/linux/Zabbix/](/_posts/devops/zabbix.md) 

```bash
## 编辑ansible的hosts文件
cat >> /etc/ansible/hosts <<EOF
# 组名zabbix_agent_servers(推荐使用下划线)。之后的配置是基于此组下的所有服务器进行操作
[zabbix_agent_servers]
192.168.6.131
192.168.6.132
192.168.6.133
EOF

## 设置Control Machine可ssh到客户机
ssh-keygen # 产生私钥和公钥
ssh-copy-id root@192.168.6.131 # 将公钥发送至131/132/133

## 以ansible方式ping通客户端(必须全部ping通，显示`"ping": "pong"`即可)
ansible zabbix_agent_servers -m ping # zabbix_agent_servers为组名

## 创建zabbix相关文件夹
cd /etc/ansible/roles/
# templates存放zabbix-agent配置文件模板；
mkdir zabbix-agent/{files,templates,tasks} -pv
tree # 查看目录结构。 yum -y install tree

# files存放zabbix-agent的rpm包，通过此控制服务器分发给各client
cd /etc/ansible/roles/zabbix-agent/files
wget http://repo.zabbix.com/zabbix/4.0/rhel/7/x86_64/zabbix-agent-4.0.12-1.el7.x86_64.rpm

# 配置文件模板
cat >> /etc/ansible/roles/zabbix-agent/templates/zabbix_agentd.conf.j2 <<EOF
# 此j2生成的zabbix_agentd.conf配置中将只存在以下字段
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
EnableRemoteCommands=1
Server={{zabbix_serverip}}
ListenPort=10050
ServerActive={{zabbix_activeip}}
Hostname={{agent_hostname}}
AllowRoot=1
Include=/etc/zabbix/zabbix_agentd.d/*.conf
EOF

# 配置部署步骤。其中src为相对路径即可，基于files目录
cat >> /etc/ansible/roles/zabbix-agent/tasks/main.yaml <<EOF
- name: Copy zabbix-agent
  copy: src=zabbix-agent-4.0.12-1.el7.x86_64.rpm dest=/root/
- name: Install the zabbix-agend # 安装zabbix agentd
  shell: rpm -Uvh /root/zabbix-agent-4.0.12-1.el7.x86_64.rpm
- name: Copy zabbix-agent.conf  # 上传配置文件
  template: src=zabbix_agentd.conf.j2 dest=/etc/zabbix/zabbix_agentd.conf mode=644
- name: Start service zabbix-agent # 启动zabbix-agent，并开机自启
  service: name=zabbix-agent state=restarted enabled=true
- name: Delete zabbix-agent package # 删除安装包
  shell: rm -f /root/zabbix-agent-4.0.12-1.el7.x86_64.rpm
EOF

# 建立一个playbook文件，该文件的执行可用来调用创建好的roles
cat >> /etc/ansible/roles/zabbix-agent/zabbix-agent.yaml <<EOF
- hosts: zabbix_agent_servers # 指定需要执行的组
  user: root
  vars:
     zabbix_serverip: 192.168.6.131 # zabbix 服务器IP
     zabbix_activeip: 192.168.6.131:10051 # zabbix 服务器IP
     agent_hostname: '{{ ansible_hostname }}' # 自动获取客户端hostname
  roles:
    # 指定调用的角色(/etc/ansible/roles目录下文件名)
    - zabbix-agent
EOF

## 测试和执行playbook文件
ansible-playbook /etc/ansible/roles/zabbix-agent/zabbix-agent.yaml --check # 测试，观察`PLAY RECAP`中`ok`和`failed`的数量
ansible-playbook /etc/ansible/roles/zabbix-agent/zabbix-agent.yaml # 执行

## 在某一台客户机上查看zabbix-agent运行状态
systemctl status zabbix-agent
```










---

参考文章

[^1]: http://openskill.cn/article/504
[^2]: https://www.cnblogs.com/ding2016/p/6896875.html


