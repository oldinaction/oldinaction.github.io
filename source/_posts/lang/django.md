---
layout: "post"
title: "Django"
date: "2018-09-24 21:29"
categories: [lang]
tags: [python, django]
---

## 简介

- [官网](https://www.djangoproject.com/)

## manage命令

```bash
# python manage.py <xxx>
python manage.py [xxx] --help

# 以下为内置命令，也可扩展命令
[auth]
    changepassword
    createsuperuser     # python manage.py createsuperuser --email admin@aezo.cn --username admin # 输入密码admin888
[authtoken]
    drf_create_token
[contenttypes]
    remove_stale_contenttypes
[django]
    check
    compilemessages
    createcachetable
    dbshell             # 进入数据库命令行
    diffsettings
    dumpdata
    flush
    inspectdb           # 根据数据库表结构生成django模型
    loaddata
    makemessages
    makemigrations      # 根据models.py的定义生成表结构迁移文件，每执行一次就会在migrations文件夹内生成一个文件
    migrate             # 执行迁移文件(将所有app，包括内置app下的迁移全部依次执行)到数据库。每次执行会先判断migrations文件夹下的文件在django_migrations表中是否存在，不存在则执行，并将执行记录保存在django_migrations表中
        --fake APP_NAME zero # 仅将my_app中的迁移添加到django_migrations表(生成一条假记录)，不会真正执行SQL
    sendtestemail
    shell               # 进入django的shell环境
    showmigrations      # 查看迁移
    sqlflush
    sqlmigrate
    sqlsequencereset
    squashmigrations
    startapp            # 创建App
    startproject        # 新建一个项目
    test
    testserver
[sessions]
    clearsessions
[staticfiles]
    collectstatic       # 收集资源文件，参考下文[静态资源](#静态资源)
        --noinput       # 如果静态资源目录有文件则需确认，加上此参数则跳过确认
    findstatic
    runserver           # 启动项目。eg：python manage.py runserver 0.0.0.0:8000 # 启动项目(开启局域网访问)

## 举例
python manage.py startapp myapp     # 创建App
python manage.py makemigrations     # 生成迁移
python manage.py migrate            # 执行迁移(将所有app，包括内置app下的迁移全部依次执行)
python manage.py collectstatic      # 收集资源文件
python manage.py runserver          # 启动项目
```

## hello world

```py
### urls.py 项目入口urls
from django.contrib import admin
from django.urls import path, include
from monitor import urls as monitor_urls

urlpatterns = [
    url(r'^', admin.site.urls),  # 如果域名后面没有指定路径就匹配这一条规则
    path('favicon.ico', RedirectView.as_view(url='static/theme/default/images/favicon.ico')),
    url(r'^static/(?P<path>.*)$', static.serve, {'document_root': settings.STATIC_ROOT}, name='static'),  # 静态资源地址

    path('admin/', admin.site.urls),
    path('monitor/', include(monitor_urls)),
]

### app/urls.py 子模块urls
from django.conf.urls import url
from monitor import views

urlpatterns = [
    url(r'^hello$', views.HelloView.as_view()),
]

### app/views.py
from django.views import View
from django.http import HttpResponse


class HelloView(View):
    def get(self, request, *args, **kwargs):
        # 使用模板(templates/monitor/index.html)：相对于templates目录的路径，且必须在`INSTALLED_APPS`中加入本app(如：'apps.monitor')
        return render(request, 'monitor/index.html', {
            'my_msg': "welcome",
        })

    def post(self, request, *args, **kwargs):
        # self.dispatch()
        if request.user.username == 'admin':  # 通过/admin登录后，默认会保存user到session中
            return HttpResponse('hello world...')
        else:
            return HttpResponse('please login...')
```

## Model

> http://www.cnblogs.com/wupeiqi/articles/5246483.html

### 数据库

- 数据库配置

```py
DATABASES = {
    # 默认使用的是sqlite3数据库
    # 'default': {
    #     'ENGINE': 'django.db.backends.sqlite3',
    #     'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    # },

    # 使用mysqls数据库
    # `pip install mysqlclient-1.3.13-cp36-cp36m-win_amd64.whl` 安装客户端(windows)
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'django_rest', # 数据库名
        'HOST': 'localhost',
        'PORT': '3306',
        'USER': 'root',
        'PASSWORD': 'root',
    }
}
```
- 生成/更新表结构
    - `python manage.py makemigrations` 生成迁移文件
    - `python manage.py migrate` 执行迁移文件(数据库表结构会同步更新)
    - 不建议手动到数据库删除表
- 创建管理用户(保存在auth_user表中)
    - `python manage.py createsuperuser --email admin@aezo.cn --username admin`(输入密码admin888) 
- 创建权限组数据并添加用户
    - `insert into "auth_group" ("id", "name") values (1, '管理员')`
    - `insert into "auth_user_groups" ("id", "user_id", "group_id") values (1, 1, 1)`

### 表结构定义

- 字段通用属性
    - `verbose_name` 定义字段说明，admin模块界面显示的字段名。中文定义如：`verbose_name=u'字段说明'`
    - `primary_key=True` 为主键
    - `blank=True` admin会根据在创建数据库时的非空与否属性来确定字段是否必填(所有类型字段默认都是不为空的)。对于时间和数字，允许为空的条件需要 `blank=True,null=True` 否则会引发错误
    - `null=True` 可为空。字符串可以不初始化，但是在修改时不能为空字符串。如果需要为空字符串可加blank=True
    - `choices` 可选值元组
    - `default` 默认值
- `DateField`、`DateTimeField` [^1]
    - `auto_now=True` 这个参数的默认值为false，设置为true时，能够在保存该字段时，将其值设置为当前时间，并且每次修改model，都会自动更新。因此这个参数在需要存储**最后修改时间**的场景下，十分方便。需要注意的是，设置该参数为true时，并不简单地意味着字段的默认值为当前时间，而是指字段会被“强制”更新到当前时间，你无法程序中手动为字段赋值；如果使用django再带的admin管理器，那么该字段在admin中是只读的
    - `auto_now_add` 设置为True时，会在model对象第一次被创建时，将字段的值设置为创建时的时间，以后修改对象时，字段的值不会再更新。该属性通常被用在存储**创建时间**的场景下。与auto_now类似，auto_now_add也具有强制性，一旦被设置为True，就无法在程序中手动为字段赋值，在admin中字段也会成为只读的
    - `default=django.utils.timezone.now` 默认值为当前时间且再admin模块可修改
    - 上述3个默认时间属性都不会再数据库级别创建默认值
- `Meta`为每个mode的元数据定义类
    - `verbose_name_plural` 可在admin模块显示此字段定义表别名
- 主键

    ```py
    # 自定义主键
    class Party(models.Model):
        # 手动定义主键名称
        # party_id = models.AutoField(primary_key=True) # mysql长度为10位int类型，且为自增主键
        # party_id = models.BigAutoField(primary_key=True) # mysql长度为20位bigint类型，且为自增主键
        # party_id = models.BigIntegerField(primary_key=True) # mysql长度为20位bigint类型，无法自增需要手动赋值主键

        # 未定义主键则默认创建主键名为id，类型11位的int，且为自增
        name = models.CharField(max_length=20)
        '''在types.py中定义：
        party_source = (
            ('A', '来源一'),
            ('B', '来源二'),
        )
        '''
        party_source = models.CharField(verbose_name=u'Party来源', choices=types.party_source, max_length=60)
        is_gov = models.BooleanField(verbose_name=u'是否为政府机构', default=True)

    # 关于联合主键
    class PartyRole(models.Model):
        party = models.ForeignKey('Party', on_delete=models.CASCADE)  # 此处同时使用了ForeignKey外键，见下文
        role_type = models.ForeignKey('RoleType', on_delete=models.CASCADE)

        class Meta:
            db_table = 'biz_party_role'  # 定义实际表名
            verbose_name_plural = u'Party角色'  # admin模块界面显示的字段名，默认显示表名
            unique_together = ("party", "role_type")   # django未实现联合主键, 只能通过组合唯一建校验
            # 自定义权限
            permissions = (
                ("publish_goods", "Can publish goods"),
                ("comment_goods", "Can comment goods"),
            )
    ```
- 外键/关联(使用物理外键，配合admin模块可更快实现增删改查功能)

    ```py
    ## 案例一：models.py
    # Author必须定义在Books上面
    class Author(models.Model):
        author = models.CharField(max_length=250) 
    class Books(models.Model):
        # book = models.ForeignKey('Author', on_delete=models.CASCADE) # 此时Author可以定义在Books下面。并且Author可以通过配置文件导入，否则需要在Books上面定义

        # 默认外键名为`属性名_id`
        book = models.ForeignKey(Author, on_delete=models.CASCADE)
        # book = models.ForeignKey(Author, on_delete=models.SET_NULL, db_constraint=False, null=True, blank=True) # 定义逻辑外键/软外键

        # 自关联
        parent_book = models.ForeignKey(to='self', on_delete=models.CASCADE)

    ## 案例二：models.py
    class PartyRelationship(BaseModel):
        """当事人(个人/组织)角色关系，如雇佣关系/部门关系等(职位属于人事模块)"""
        party_relationship_type = models.ForeignKey('PartyRelationshipType', on_delete=models.PROTECT)
        party_id_from = models.ForeignKey('Party', db_column='party_id_from', related_name='party_relationship_from',
                                        on_delete=models.CASCADE)
        party_id_to = models.ForeignKey('Party', db_column='party_id_to', related_name='party_relationship_to',
                                        on_delete=models.CASCADE)
        role_type_id_from = models.ForeignKey('RoleType', db_column='role_type_id_from', related_name='party_relationship_from',
                                            on_delete=models.PROTECT)
        role_type_id_to = models.ForeignKey('RoleType', db_column='role_type_id_to', related_name='party_relationship_to',
                                            on_delete=models.PROTECT)
        from_date = models.DateTimeField(default=timezone.now)
        thru_date = models.DateTimeField(verbose_name=u'过期时间', null=True, blank=True)

        class Meta:
            db_table = 'biz_party_relationship'
            # django未实现联合主键, 只能通过组合唯一建校验
            unique_together = ("party_id_from", "party_id_to", "role_type_id_from", "role_type_id_to", "from_date")
            verbose_name_plural = u'Party角色关系'
    ```
    - `ForeignKey`、`ManyToManyField`、`OneToOneField`分别在Model中定义多对一(使用ForeignKey的表为子表)，多对多，一对一关系
    - 参数
        - `related_name`
            - father.child_set.all()。获取子表(子表Child中有一个外键，此时父表中默认会存储 `子表_set` 来获取子表；也可在子表中定义 related_name；如果子表中有某一个表的两个外键，则必须要定义related_name)
            - father.child_related_name.all()。child_related_name为子表中定义的 related_name 名称
            - book = models.ForeignKey(Author, related_name='child_related_name', on_delete=models.CASCADE)
        - `db_column` 定义外键生成的字段名
        - `on_delete` 删除主表时，对子表的行为。ForeignKey必须
            - `CASCADE` 删除作者信息一并删除作者名下的所有书的信息
            - `PROTECT` 删除作者的信息时，采取保护机制，抛出错误：即不删除Books的内容
            - `SET_NULL` 只有当null=True才将关联的内容置空
            - `SET_DEFAULT` 设置为默认值
            - `SET()` 括号里可以是函数，设置为自己定义的东西
            - `DO_NOTHING` 字面的意思，啥也不干
        - `db_constraint=False` **数据库中不创建外键**。但是django仍然可以通过外键属性获取关联对象

### CRUD

#### 基本增删改

```py
from api.test import models

## 增
# 法一，返回值object
models.MyUser.objects.create(name='smalle', password='123')
# 法二，返回值object
obj = models.MyUser(name='smalle', password='123') # 也可 obj = models.MyUser()
obj.save()
# 法三，返回值object。可以接受字典类型数据 **kwargs
dic = {'name':'smalle','password':'123'}
models.MyUser.objects.create(**dic)
# 法四，返回值是一个元组(object, True/False)。首先尝试获取，不存在就创建，可以防止重复；创建时返回 True, 已经存在时返回 False
models.MyUser.objects.get_or_create(name="smalle", email="test@163.com")


## 查
# 获取单条数据，不存在则报错（不建议），返回 MyUser.objects
user = models.MyUser.objects.get(id=1)  # 如果不存在会报错 models.MyUser.DoesNotExist

# 获取全部，返回queryset类型
users = models.MyUser.objects.all()
if users.exists(): pass
# 获取全部数据的第1条数据
models.MyUser.objects.all().first()
# 获取指定条件的数据，返回queryset类型
models.MyUser.objects.filter(name='smalle')
# filter可以接受字典类型数据 **kwargs(下同)
dic = {'name':'smalle','password':'123'}
models.MyUser.objects.filter(**dic)


## 改
# 批量更新。适用于 .all()  .filter()  .exclude() 等后面 (危险操作，正式场合操作务必谨慎)
models.MyUser.objects.filter(name='smalle').update(password='123456')
models.MyUser.objects.filter(name__iexact="abc").update(name='xxx') # __iexact 后缀可过滤名称为 abc 但是不区分大小写，可以找到 ABC, Abc, aBC，这些都符合条件。将他们都改成 xxx
models.MyUser.objects.all().delete() # 删除所有 Person 记录
# 单个 object 更新。适合于 .get(), get_or_create(), update_or_create() 等得到的 obj
obj = models.MyUser.objects.get(id=1)
obj.password = '123456'
obj.save()


## 删
models.MyUser.objects.filter(name='smalle').delete()
```

#### 进阶查询

```py
from api.test import models

# 获取个数
models.MyUser.objects.filter(sex='boy').count()

# 获取id大于1 且 小于10的值
models.MyUser.objects.filter(id__lt=10, id__gt=1)

# in 获取id等于11、22、33的数据
models.MyUser.objects.filter(id__in=[1, 2, 3])
# not in
models.MyUser.objects.exclude(id__in=[1, 2, 3])

# 包含/不包含
models.MyUser.objects.filter(name__contains="aezo") # __contains 包含
models.MyUser.objects.filter(name__icontains="aezo") # __icontains大小写不敏感
models.MyUser.objects.exclude(name__icontains="aezo")

# 范围bettwen and
models.MyUser.objects.filter(id__range=[1, 10])

# order by
models.MyUser.objects.filter(sex='boy').order_by('id')    # asc
models.MyUser.objects.filter(sex='boy').order_by('-id')   # desc

# limit、offset。切片操作，获取前10个，切片可以节约内存，不支持负索引，可使用 reverse() 解决
models.MyUser.objects.all()[:10]
models.MyUser.objects.all()[10:20]

# __regex正则匹配，__iregex 不区分大小写
models.MyUser.objects.get(name__regex=r'^(An?|The) +')
models.MyUser.objects.get(name__iregex=r'^(an?|the) +')

# 日期
models.MyUser.objects.filter(birth_date__date=datetime.date(2000, 1, 1)) # __date 日期等于
models.MyUser.objects.filter(birth_date__date__gt=datetime.date(2000, 1, 1)) # __date__gt 日期大于
models.MyUser.objects.filter(pub_date__year=2000) # 同理 __month、__day、__week_day、__hour、__minute、__second
```

#### 联表查询

```py
from api.test import models

# 外键。查询子表
father = models.Father.objects.filter(id=1).first()
father.child_set.all() # 获取子表(子表Child中有一个外键，此时父表中默认会存储 `子表_set` 来获取子表；也可在子表中定义 related_name；如果子表中有某一个表的两个外键，则必须要定义related_name)
father.child_related_name.all() # child_related_name为子表中定义的 related_name 名称
```

#### QuerySet

- 从数据库中查询(all/filter)出来的结果一般是一个集合，这个集合叫做 `QuerySet` [^3]
- 如果只是检查 MyUser 中是否有对象，应该用 `models.MyUser.objects.all().exists()`
- 推荐用 `models.MyUser.objects.count()` 来查询数量，而不是用 `len(users)`，前者用的是SQL为`SELECT COUNT(*)`更高效
- `list(users)` 可以强行将 QuerySet 变成列表
- 案例

```py
# 参考：https://code.ziqiangxuetang.com/django/django-queryset-api.html
from api.test import models

## QuerySet 是可迭代的
users = models.MyUser.objects.all()
for u in users:
    print(u.name)
if users.exists():  # 如果无数据返回的也是 QuerySet 对象，如果通过 `if users is not None:`永远返回True，因此需要使用exists判断

## QuerySet 查询结果排序
models.MyUser.objects.all().order_by('-name') # 在 column name 前加一个负号，可以实现倒序

## QuerySet 支持链式查询
models.MyUser.objects.filter(name__contains="smalle").exclude(email="admin@163.com")

## QuerySet 支持切片，可以节省内存。但是QuerySet不支持负索引
models.MyUser.objects.all()[:10] # 取出前10条
models.MyUser.objects.all()[-10:] # 会报错！！！
# 使用 reverse() 解决
models.MyUser.objects.all().reverse()[:2] # 最后两条
models.MyUser.objects.all().reverse()[0] # 最后一条
# 使用 order_by 解决
models.MyUser.objects.order_by('-id')[:20] # id最大的20条

## QuerySet 重复的问题，使用 .distinct() 去重。一般的情况下，QuerySet 中不会出来重复的，但是多次查询将结果并到一起，可能会出来重复的值
qs1 = models.MyUser.objects.filter(label__name='test')
qs2 = models.MyUser.objects.filter(attr__name='hello')
qs3 = models.MyUser.objects.filter(inputer__name='smalle')
# 合并到一起，这个时候就有可能出现重复的
qs = qs1 | qs2 | qs3
# 执行去重方法
qs = qs.distinct()
```
- 进阶案例 [^4]

```py
# 参考：https://code.ziqiangxuetang.com/django/django-queryset-advance.html
from api.test import models

### 查看 Django queryset 执行的 SQL
print(str(models.MyUser.objects.all().query))
models.MyUser.objects.all().query.__str__()

### values_list 和 values
# values_list 和 values 返回的并不是真正的 列表 或 字典，也是 queryset。他们也是用的时候才真正的去数据库查
# 如果查询后没有使用，在数据库更新后再使用，此时得到在是新内容。如果想要旧内容保持着，数据库更新后不要变，可以 list 一下便会立即查询数据到内存
# 如果只是遍历这些结果，没有必要 list 它们转成列表(会浪费内存)
## values_list 获取元组形式结果。如获取用户的 name 和 qq
users = models.MyUser.objects.values_list('name', 'qq')
list(users)
# 如果只需要 1 个字段，可以指定 flat=True
list(models.MyUser.objects.values_list('name', flat=True))
## values 获取字典形式的结果。如获取用户的 name 和 qq
models.MyUser.objects.values('name', 'qq')
list(models.MyUser.objects.values('name', 'qq'))

### extra、defer、only
## extra 实现：别名(如`select name as full_name from my_user;`)，条件，排序等
# 使用extra后，name 和 tag_name 都可以使用
users = models.MyUser.objects.all().extra(select={'full_name': 'name'})
users[0].name
users[0].full_name
## defer 排除不需要的字段。此处如排除原来的 name 字段
models.MyUser.objects.all().extra(select={'full_name': 'name'}).defer('name')
models.MyUser.objects.all().defer('password')
## only 仅选择需要的字段(主键也会自动带出)
models.MyUser.objects.all().only('name')

### annotate 实现聚合：计数，求和，平均数等
## 计数。如计算每个组作者的文章数
# select author_id, count(author_id) as count from article group by author_id
from django.db.models import Count
models.Article.objects.all().values('author_id').annotate(count=Count('author')).values('author_id', 'count')
models.Article.objects.all().values('author__name').annotate(count=Count('author')).values('author__name', 'count')  # 获取关联表字段
## 求和。如求一个作者所有文章的总分
# select "author"."name", sum("article"."score") as "sum_score" from "article" inner join "author" on ("article"."author_id" = "author"."id") group by "author"."name"
from django.db.models import Sum
models.Article.objects.values('author__name').annotate(sum_score=Sum('score')).values('author__name', 'sum_score')
## 平均值。如求一个作者的所有文章的得分(score)平均值
# select author_id, avg(score) as avg_score from article group by author_id
from django.db.models import Avg
models.Article.objects.values('author_id').annotate(avg_score=Avg('score')).values('author_id', 'avg_score')

### select_related、prefetch_related
## select_related 优化一对一，多对一查询(select_related 是使用 SQL JOIN 一次性取出相关的内容)。eg：取出10篇文章，并需要用到作者的姓名
# 法一
articles = models.Article.objects.all()[:10]  # 不访问数据库
a1 = articles[0]  # 会访问数据库。取第一篇
a1.author_id  # 不访问数据库
a1.author.name  # 再次访问数据库
# 法二(推荐)。filter同样可以使用select_related进行链式查询
articles = models.Article.objects.all().select_related('author')[:10]
a1 = articles[0]  # 会访问数据库
a1.author.name  # 不访问数据库
## prefetch_related 优化一对多，多对多查询(prefetch_related是通过再执行一条额外的SQL语句，然后用 Python 把两次SQL查询的内容关联 joining 到一起)
# 法一
articles = models.Article.objects.all()[:3]
for a in articles:  # 第一次循环查询两次数据库，后面两次循环每次查询一次数据
    print(a.title, a.tags.all())
# 法二(推荐)
articles = models.Article.objects.all().prefetch_related('tags')[:10]
for a in articles:  # 第一次循环查询两次数据库，后面不查询数据
    print(a.title, a.tags.all())

### 自定义聚合功能
# 定义
from django.db.models import Aggregate, CharField

class GroupConcat(Aggregate):
    function = 'GROUP_CONCAT'
    template = '%(function)s(%(distinct)s%(expressions)s%(ordering)s%(separator)s)'
 
    def __init__(self, expression, distinct=False, ordering=None, separator=',', **extra):
        super(GroupConcat, self).__init__(
            expression,
            distinct='DISTINCT ' if distinct else '',
            ordering=' ORDER BY %s' % ordering if ordering is not None else '',
            separator=' SEPARATOR "%s"' % separator,
            output_field=CharField(),
            **extra)

# 使用。比如聚合后的错误日志记录有这些字段 time、level、info，想把 level、info 一样的聚到到一起，按时间和发生次数倒序排列，并含有每次日志发生的时间
models.ErrorLogModel.objects.values('level', 'info').annotate(
    count=Count(1), time=GroupConcat('time', ordering='time DESC', separator=' | ')
).order_by('-time', '-count')
```

## 自带App

### admin

#### admin.py 快速生成管理界面

- 应用注册：在`setting.py`的`INSTALLED_APPS`中加入此应用`apps.monitor`
- `admin.py`必须写在每个app对应根目录下 [^2]

```py
## party/models.py(模型)
from django.db import models
from sqbiz.base.models import BaseModel
from . import types

class PartyType(BaseModel):
    party_type_id = models.CharField(primary_key=True, max_length=60, choices=types.party_type_id)
    parent_type = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True)
    party_type_name = models.CharField(max_length=100)
    attr1 = models.CharField(max_length=60)
    attr2 = models.CharField(max_length=60)
    description = models.TextField(verbose_name=u'描述', null=True, blank=True) # TextField 类型字段，在admin模块会自动显示成 textarea 表单元素

    class Meta:
        db_table = 'biz_party_type'
        verbose_name_plural = 'Party类型'

    # admin模块子表显示父表时会调用，否则显示成PartyType object。python2使用的是__unicode__函数
    def __str__(self):
        return self.party_type_name

## party/admin.py
from django.contrib import admin
from sqbiz.party import models

# 同 admin.site.register(models.PartyType, PartyTypeAdmin) # 注册此类
@admin.register(models.PartyType)
class PartyTypeAdmin(admin.ModelAdmin):
    from django.core.paginator import Paginator

    ## 列表
    # 列表展示的字段，默认显示 ModelName object (PK)。此处my_custome_name为自定义字段名(model中无此字段)，如果要显示外键内的其他字段也可类似自定义字段
    list_display = ('party_type_id', 'parent_type', 'party_type_name', 'create_time', 'my_custome_name') # 此处的parent_type自关联外键，不能写成parent_type_id真实字段名，必需为model的字段名
    list_display_links = ('party_type_id', 'parent_type')  # 设置哪些字段可以点击进入编辑界面(默认第一个字段)
    ordering = ('-create_time',)  # 默认排序字段，负号表示降序排序
    list_max_show_all = 200  # 真实数据小于该值时，才会有显示全部，否则分页显示
    list_per_page = 100  # 设置每页显示多少条记录，默认是100条
    paginator = Paginator  # 分页插件

    actions = [func, ]  # 增加Action
    actions_selection_counter = True  # 显示选中的记录条数，默认True
    actions_on_top = True  # Action选项都是在页面上方显示
    actions_on_bottom = True  # Action选项都是在页面下方显示，默认False

    empty_value_display = "-NA-"  # 列数据为空时，默认显示数据
    list_select_related = True  # Django在检索管理更改列表页面上的对象列表时使用select_related()，这可以节省大量的数据库查询。默认False
    list_editable = ('parent_type', 'party_type_name', 'create_time',)  # 列表可编辑字段(可操作input/select/date/外键等)

    ## 筛选
    # 列表查询字段(所有的字段通过同一个搜索框输入)。__获取对象属性，此时相当于基于父表project的name进行筛选
    search_fields = ['party_type_name', 'description', 'parent_type__party_type_name']
    list_filter = ['party_type_name']  # 列表右边显示的过滤器(基于字段值distinct后进行快速筛选链接)。**也可自定义筛选类，参考下文**
    date_hierarchy = 'create_time'  # 详细时间分层筛选

    ## 编辑
    form = MyForm  # 用于定制用户请求时候表单验证。可继承 ModelForm
    # 新增/修改时的表单字段
    fields = ['party_type_id', 'parent_type', 'party_type_name', 'description', 'create_time'] # 此处的parent_type外键，不能写成parent_type_id真实字段名
    # 排除该字段
    exclude = ('create_time',)
    # 新增/修改表单暴露字段(常用)
    fieldsets = (
        # 基于Key分栏显示，None也可定义成 'PartyType信息'
        (None, {'fields': ('party_type_name', ('attr1', 'attr2'), 'description', 'create_time',)}), # ('attr1', 'attr2')表示两个字段显示时处于一行
        ('ParentType信息', {'fields': ('parent_type',)}),
    )

    # 基于用户过滤数据显示
    def get_queryset(self, request):
        """重新定义此ModelAdmin函数，使普通用户只能看到自己添加的类型"""
        qs = super(PartyTypeAdmin, self).get_queryset(request)
        if request.user.is_superuser:
            return qs
        return qs.filter(create_user_id=UserInfo.objects.filter(user_name=request.user))

    ## 设置只读字段
    readonly_fields = ('create_time',)

    def get_readonly_fields(self, request, obj=None):
        """重新定义此ModelAdmin函数，限制普通用户该字段为只读，超级管理员可修改"""
        if request.user.is_superuser:
            self.readonly_fields = []
        elif hasattr(obj, 'parent_type_id') and obj.parent_type_id:
            self.readonly_fields = []
        return self.readonly_fields

    def save_model(self, request, obj, form, change):
        """重新定义ModelAdmin函数，编辑时进行额外操作。删除时操作可以重新定义delete_model方法"""

        def make_paper_num():
            """生成随机字符串"""
            import datetime
            import random
            current_time = datetime.datetime.now().strftime("%Y%m%d%H%M%S")  # 生成当前时间
            random_num = random.randint(0, 100)  # 生成的随机整数n，其中0<=n<=100
            unique_num = str(current_time) + str(random_num)
            return unique_num  # 201912131506155

        if change:  # 更新时
            if obj.description is not None:
                obj.description = obj.description + make_paper_num()
            else:
                obj.description = make_paper_num()
        else:  # 新增时
            obj.description = make_paper_num()
        super(PartyTypeAdmin, self).save_model(request, obj, form, change)  # 此种修改不会被django记录到修改历史中
    
    ## 自定义列表字段 my_custome_name(条件：1.list_display中需要添加此字段；2.定义的方法名和字段名需要一致)
    def my_custome_name(self, partyType):
        """自定义列表字段my_custome_name函数，用来显示子表的扩展属性名"""
        my_custome_name = map(lambda x: x.attr_name, partyType.extAttrs.all())
        return ', '.join(my_custome_name)
    my_custome_name.short_description = '自定义名称'  # 设置表头显示
    my_custome_name.empty_value_display = "None"  # 自定义字段为空时的默认值

    # 定制Action行为具体方法
    def func(self, request, queryset):
        print(self, request, queryset)
        print(request.POST.getlist('_selected_action'))
```
- 自定义筛选类

```py
## api/admin.py
from django.contrib import admin
from api.pmhours import models

# 自定义的Filter类的代码必需放在ModelAdmin类的前面，否则无法使用
class NameKeywordFilter(admin.SimpleListFilter):
    """自定义筛选类"""
    title = '项目名关键词'  # 右侧栏筛选标题
    parameter_name = 'name'  # 在url中显示的参数名，如?name=xxx。不要使用q和next，这两个参数已作为django admin的默认参数使用了

    def lookups(self, request, model_admin):
        """自定义可筛选的参数元组"""
        return (
            ('A', '客户A'),
            ('B', '客户B'),
        )

    def queryset(self, request, queryset):
        """调用self.value()获取url中的参数，然后筛选所需的queryset."""
        if self.value() == 'A':
            return queryset.filter(name__icontains='客户A')
        if self.value() == 'B':
            return queryset.filter(name__icontains='客户B')


@admin.register(models.Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ('name', 'project_type', 'manager', 'section_type', 'description', 'start_time',)
    list_filter = ['project_type', NameKeywordFilter, ]  # 引入自定义筛选类
```
- 
- 一对多字段编辑(主子表一起编辑)

```py
from django.contrib import admin
from sqbiz.order import models

# 必须定义在OrderAdmin上方
class OrderDetailInline(admin.TabularInline):
    model = models.OrderDetail
    # 在主表编辑界面，默认显示2个子表编辑行(不够可手动新增行)
    extra = 2

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    inlines = [OrderDetailInline,]
    list_display = ('order_no', 'customer',)
```
- ManyToMany多对多字段编辑
    - 可以用filter_horizontal或filter_vertical定义字段

#### 添加动作(操作函数)到actions/列表行增加操作按钮

```py
class ProjectAdmin(admin.ModelAdmin):
    ## 添加actions
    actions = ['confirme', ]

    # queryset为勾选的记录
    def confirme(self, request, queryset):
        # from django.contrib import messages
        queryset.update(is_sure=True)
        self.message_user(request, '审核通过')  # message_user 为 ModelAdmin 提供的 Alert 提示信息函数
        # self.message_user(request, '审核不通过', level=messages.ERROR)
    confirme.short_description = '确认'

    # 列表行增加操作按钮
    list_display = ('name', 'buttons')  # buttons为自定义的列表显示字段，具体通过同名函数获取

    def buttons(self, obj):
        from django.utils.html import format_html
        button_html = """<a href="/admin/monitor/script/%s/change/">编辑</a>""" % (obj.id,)
        return format_html(button_html)
    _buttons.short_description = "操作"
```

#### 自定义用户登录操作

```py
## setting.py
AUTH_USER_MODEL = "party.UserLogin"

## party/models.py
from django.contrib.auth.models import AbstractUser

class UserLogin(AbstractUser):
    """扩展django的User模型"""
    id = models.BigAutoField(primary_key=True)
    party = models.ForeignKey('Party', on_delete=models.CASCADE, null=True, blank=True)

    first_name = None
    last_name = None
    is_staff = True
    # is_superuser = None

    class Meta:
        db_table = 'biz_user_login'
        verbose_name_plural = '登录用户'

## party/admin.py
from django import forms
from django.contrib.auth.forms import ReadOnlyPasswordHashField
from django.contrib.auth.admin import UserAdmin
from django.contrib import admin
from sqbiz.party import models

class UserLoginChangeForm(forms.ModelForm):
    password = ReadOnlyPasswordHashField()

    class Meta:
        model = models.UserLogin
        fields = '__all__'

    def clean_password(self):
        return self.initial["password"]

class UserLoginCreateForm(forms.ModelForm):
    password1 = forms.CharField(label='密码', widget=forms.PasswordInput)
    password2 = forms.CharField(label='密码确认', widget=forms.PasswordInput)

    class Meta:
        model = models.UserLogin
        fields = '__all__'

    def clean_password2(self):
        """校验字段(clean_字段名)"""
        password1 = self.cleaned_data.get("password1")
        password2 = self.cleaned_data.get("password2")
        if password1 and password2 and password1 != password2:
            raise forms.ValidationError("密码不匹配")
        return password2

    def save(self, commit=True):
        user = super(UserLoginCreateForm, self).save(commit=False)
        user.set_password(self.cleaned_data["password1"])
        if commit:
            user.save()
        return user

@admin.register(models.UserLogin)
class UserLoginAdmin(UserAdmin):
    form = UserLoginChangeForm
    add_form = UserLoginCreateForm

    list_display = ('username', 'party')
    list_filter = ('is_superuser', 'is_active', 'groups')

    # fields = ['username', 'password', 'party'] # 新增/修改暴露字段
    # 修改表单暴露字段(基于Key分栏显示)
    fieldsets = (
        (None, {'fields': ('username', 'password', 'email',)}),
        ('Party信息', {'fields': ('party',)}),
    )
    # 新增表单暴露字段
    add_fieldsets = (
        (None, {'classes': ('my-field-set-css-class',),
                'fields': ('username', 'password1', 'password2', 'email', 'party',)}),
    )
```

#### 自定义Django后台名称和favicon图标

- 修改默认的Django标题 [^5]

```py
from django.views.generic import RedirectView

# 在配置完static路径的情况下使用
urlpatterns = [
    path('favicon.ico', RedirectView.as_view(url='static/theme/default/images/favicon.ico')),
]

# 在总入口urls.py中修改
admin.site.site_header = '我在后台首页左上角'
admin.site.site_title = '我在浏览器标签后面'
admin.site.index_title = '我在浏览器标签前面'
```

#### 扩展主题

- 使用主题插件如：[simpleui](https://github.com/newpanjing/simpleui)、[Grappelli](https://github.com/sehmaschine/django-grappelli)

### django.contrib.contenttypes

> 源码参考【A02_DjangoTest】

- 主要用于一张表A和多张表关联，表A中一个字段用于存其他的表名，另外一个字段用于存储其他表的主键
- 示例

```py
## models.py
from django.db import models
from django.contrib.contenttypes.fields import GenericForeignKey, GenericRelation
from django.contrib.contenttypes.models import ContentType

class HeadImage(models.Model):
    username = models.CharField(max_length=32, verbose_name='用户姓名')
    # 不生成表字段，主要方便查询
    image_list = GenericRelation('Image')

class BannerImage(models.Model):
    name = models.CharField(max_length=64)
    href = models.CharField(max_length=255, verbose_name='Banner点击后的连接')
    # 不生成表字段，主要方便查询
    image_list = GenericRelation('Image')

class Image(models.Model):
    path = models.CharField(max_length=255)
    # content_type最终会在Image表中生成一个字段content_type_id，此字段对应表 django_content_type
    content_type = models.ForeignKey(ContentType, verbose_name='关联的表类型', on_delete=models.CASCADE)
    object_id = models.IntegerField(verbose_name='关联表的主键ID')
    # 不会生成表字段，主要方便操作数据
    content_object = GenericForeignKey('content_type', 'object_id')


## views.py
def test_contenttypes_create(request):
    '''创建数据'''
    banner = models.BannerImage.objects.filter(name='home').first()
    models.Image.objects.create(path='home1.jpg', content_object=banner)
    models.Image.objects.create(path='home2.jpg', content_object=banner)
    models.Image.objects.create(path='home3.jpg', content_object=banner)
    return HttpResponse('test_contenttypes_create...')

def test_contenttypes_list(request):
    '''查询数据'''
    banner = models.BannerImage.objects.filter(id=1).first()
    image_list = banner.image_list.all()
    # <QuerySet [<Image: Image object (1)>, <Image: Image object (2)>, <Image: Image object (3)>]>
    print(image_list)
    return HttpResponse('test_contenttypes_list...')
```

## django中间件(MIDDLEWARE)

- 中间件类型：`process_request`、`process_view`、`process_response`、`process_exception`、`process_render_template`
- 中间件执行顺序：用户请求 -> 经过所有process_request -> 视图函数 -> 经过所有process_view
- CSRF(Cross-site request forgery)跨站请求伪造
    - 全站开启或关闭，看中间件配置中是否有：'django.middleware.csrf.CsrfViewMiddleware'
    - 在process_view中检查视图是否有装饰器`@crsf_exempt`(全局有csrf时，此函数不考虑csrf)、`@crsf_protect`(全局无时，此函数考虑csrf)
    - 需要csrf检查时，从前请求体或cookies中获取token
    - 在csrf存在时，且未CBV模式下，去掉某个url的csrf功能，有两种方式
        - View子类上加`@method_decorator(csrf_exempt, name='dispatch')`
        - View子类重写dispatch方法，并在dispatch方法上加`@method_decorator(csrf_exempt)`(加在其他方法上无效)
    - 使用时在html的表单中加入 &#123;%csrf_token%&#125;

## 异常处理

- 覆盖500/404等异常展示：直接在templates目录中加404.html即可覆盖默认页面显示
- 自定义异常执行方法

```py
# django自定义错误返回处理方法
## urls.py
handler404 = "myapp.views.page_not_found"
handler500 = "myapp.views.page_error"
handler403 = "myapp.views.permission_denied"
handler400 = "myapp.views.bad_request"

## myapp/views.py
def page_not_found(request):
    return render_to_response('404.html')

def page_error(request):
    return render_to_response('500.html')

def permission_denied(request):
    return render_to_response('403.html')

def bad_request(request):
    return render_to_response('400.html')
```

## 配置

```py
### setting.py
import os

# 获取项目目录
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# 开启调试模式，出错后业务会显示堆栈信息，生成环境需要关闭
DEBUG = bool(os.getenv('DJANGO_DEBUG', True))  # 环境变量设置DJANGO_DEBUG=''
# 允许对外访问的主机地址。如增加服务器的内网地址，则可以通过本服务器的内网地址进行访问
ALLOWED_HOSTS = [
    '127.0.0.1',
    'localhost',
] + ['*'] if os.getenv('ALLOWED_HOSTS') is None else os.getenv('ALLOWED_HOSTS').split(",")
# 安装的apps(如要显示某app的admin模块，则必须先注册该app)
INSTALLED_APPS = []
# 引入的中间件
MIDDLEWARE = []
# 数据库连接
DATABASES = {
    # 'default': {
    #     'ENGINE': 'django.db.backends.sqlite3',
    #     'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    # },
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.getenv('DATABASES_NAME', 'django_rest'),
        'HOST': os.getenv('DATABASES_HOST', 'localhost'),
        'PORT': os.getenv('DATABASES_PORT', '3306'),
        'USER': os.getenv('DATABASES_USER', 'root'),
        'PASSWORD': os.getenv('DATABASES_PASSWORD', 'root'),
    },
}
# 语言
LANGUAGE_CODE = 'zh-Hans'
# 时区
TIME_ZONE = 'Asia/Shanghai'
# 静态文件目录
STATIC_URL = '/static/'
STATIC_ROOT = 'static'  # 为项目目录下的static文件夹

# 跨域配置
CORS_ORIGIN_ALLOW_ALL = True
# CORS_ORIGIN_WHITELIST = (
#     'localhost:8080',
#     '127.0.0.1:8080'
# )
CORS_ALLOW_METHODS = (
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
)

# 日志
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        # 打印数据库执行语句
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'DEBUG' if DEBUG else 'INFO',
        },
    },
}
```

## 杂项

### 静态资源

> django在配置文件中设置`DEBUG = False`后静态资源404问题。解决方式如以下几种：

- `python manage.py runserver --insecure` 启动加参数`--insecure`(正式环境中不建议)
- 解决方法

```py
## 在项目目录创建static文件
## pybiz/settings.py 创建静态资源目录
STATIC_URL = '/static/'
# STATIC_ROOT = ("/home/data/static/")
STATIC_ROOT = 'static'  # 默认基于BASE_DIR
# STATICFILES_DIRS = [
#     os.path.join(BASE_DIR, 'static/pub'),  # 不能包含STATIC_ROOT 
# ]

## 收集各模块的静态资源文件到上述目录
python manage.py collectstatic

## 暴露静态资源目录
# 法一：通过django访问
# pybiz/urls.py
from django.views import static
from pybiz import settings

urlpatterns = [
    url(r'^static/(?P<path>.*)$', static.serve, {'document_root': settings.STATIC_ROOT}, name='static'),  # 和上文STATIC_URL对应 
]

# 法二：使用nginx暴露
```

### 请求对象

- `request.POST['username']` 获取普通input的值
- `request.POST.getlist('hobby')` 获取checkbox的值
- `username = self.request.query_params.get('username', None)` 获取url参数

### 请求生命周期

![django-request](/data/images/lang/django-request.png)

### 发送邮件

```py
## settings.py
EMAIL_BACKEND = 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_USE_TLS = False
EMAIL_HOST = 'smtp.163.com'
EMAIL_PORT = 25
EMAIL_HOST_USER = 'aezocn@163.com'
EMAIL_HOST_PASSWORD = 'XXX'  # 163的客户端授权码
DEFAULT_FROM_EMAIL = 'aezo-django<aezocn@163.com>'

## 发送
from django.core.mail import send_mail, send_mass_mail

# 发送一份邮件(此处为普通文本，可以使用\n，\t等，还可使用超文本)
send_mail('Subject here', 'Here is the message.', 'from@example.com', ['to@example.com'], fail_silently=False)

# 发送多份邮件
message1 = ('Subject here', 'Here is the message', None, ['first@example.com', 'other@example.com'])  # 接收人为多个
message2 = ('Another Subject', 'Here is another message', 'hello <from@example.com>', ['second@test.com'])
send_mass_mail((message1, message2), fail_silently=False)
```

### 记录日志

- 脚本中使用

```py
import logging  # python内置库

logger = logging.getLogger('log')  # log为logger名称，在settings.py中配置了此名称log的处理方式

logger.info('hello world...')
logger.exception(e)
```

- settings.py

```py
import time

cur_path = os.path.dirname(os.path.realpath(__file__))
log_path = os.path.join(os.path.dirname(cur_path), 'runtime/logs')
if not os.path.exists(log_path): os.makedirs(log_path)  # 如果不存在这个logs文件夹，就自动创建一个

LOGGING = {
    'version': 1,
    'disable_existing_loggers': True,
    'formatters': {
        # 日志格式
        'standard': {
            'format': '[%(asctime)s] [%(filename)s:%(lineno)d] [%(module)s:%(funcName)s] '
                      '[%(levelname)s]- %(message)s'},
        # 简单格式
        'simple': {
            'format': '%(levelname)s %(message)s'
        },
    },
    # 过滤
    'filters': {
    },
    # 定义具体处理日志的方式
    'handlers': {
        # 默认记录所有日志
        'default': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(log_path, 'all-{}.log'.format(time.strftime('%Y-%m-%d'))),
            'maxBytes': 1024 * 1024 * 5,  # 文件大小
            'backupCount': 30,  # 备份数
            'formatter': 'standard',  # 输出格式
            'encoding': 'utf-8',  # 设置默认编码，否则打印出来汉字乱码
        },
        # 输出错误日志
        'error': {
            'level': 'ERROR',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(log_path, 'error-{}.log'.format(time.strftime('%Y-%m-%d'))),
            'maxBytes': 1024 * 1024 * 5,  # 文件大小
            'backupCount': 7,  # 备份数
            'formatter': 'standard',  # 输出格式
            'encoding': 'utf-8',  # 设置默认编码
        },
        # 控制台输出
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
            'formatter': 'standard'
        },
        # 输出info日志
        'info': {
            'level': 'INFO',
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': os.path.join(log_path, 'info-{}.log'.format(time.strftime('%Y-%m-%d'))),
            'maxBytes': 1024 * 1024 * 5,
            'backupCount': 15,
            'formatter': 'standard',
            'encoding': 'utf-8',  # 设置默认编码
        },
    },
    # 配置用哪几种 handlers 来处理日志
    'loggers': {
        # 类型为 django 处理所有类型的日志，默认调用
        'django': {
            'handlers': ['default', 'console'],
            'level': 'INFO',
            'propagate': False
        },
        # log 调用时需要当作参数传入
        'log': {
            'handlers': ['error', 'info', 'console', 'default'],
            'level': 'INFO',
            'propagate': True
        },
        # 打印数据库执行语句
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'DEBUG' if DEBUG else 'INFO',
        },
    }
}
```

### 模块打包成python包

- `pip install setuptools` 安装打包工具
- `python setup.py sdist` 执行打包
- `pip install --user django-polls/dist/django-polls-0.1.tar.gz` 基于用户安装 `django-polls`, 如果基于`virtualenv`安装允许同时运行多个相互独立的Python环境，每个环境都有各自库和应用包命名空间的拷贝
- `pip list` 查看包列表
- `pip uninstall django-polls` 卸载包

### FBV/CBV模式

- 函数作为视图或类作为视图，源码参考【A02_DjangoTest】

```py
# FBV: function base view
# CBV: class base view

### url.py
urlpatterns = [
    url(r'^users/', views.users), # FBV
    url(r'^students/', views.StudentsView.as_view()), # CBV
]

### views.py
import json
from django.shortcuts import render, HttpResponse

## FBV
def users(request):
    # if request.method == "GET":
    #     pass
    user_list = ['smalle', 'aezocn']
    return HttpResponse(json.dumps(user_list))


from django.views import View

## CBV: 根据不同的Http类型自动选择对应方法
from django.views import View

class MyBaseView(object):
    # 装饰器作用(拦截器)
    def dispatch(self, request, *args, **kwargs):
        print('before...')
        # 此时MyBaseView无父类，则到self(StudentsView)的其他父类查找dispatch
        ret = super(MyBaseView, self).dispatch(request, *args, **kwargs)
        print('end...')
        return ret

class StudentsView(MyBaseView, View): # 多继承(优先级从左到右)，寻找自身属性或方法 -> 寻找最左边父类的属性或方法 -> 寻找第二个父类的属性或方法 -> ...
    # def dispatch(self, request, *args, **kwargs):
    #     # 反射获取对应的方法(父类View内部也是实现了一个dispatch，其原理也是基于反射实现)
    #     fun = getattr(self, request.method.lower())
    #     return fun(request, *args, **kwargs)

    def get(self,request,*args,**kwargs):
        print('get...')
        return HttpResponse('GET...')

    def post(self,request,*args,**kwargs):
        return HttpResponse('POST...')

    def put(self,request,*args,**kwargs):
        return HttpResponse('PUT...')

    def delete(self,request,*args,**kwargs):
        return HttpResponse('DELETE...')
```

## docker发布

- `project-root/Dockerfile`举例

```Dockerfile
FROM python:3.6
MAINTAINER smalle

ARG APP_VERSION="v1.0.0"
ENV APP_VERSION=${APP_VERSION}
ENV PYTHONUNBUFFERED 1
# 是否开启Django DEBUG，更多配置如下
ENV DJANGO_DEBUG ''

RUN mkdir /webapps
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
libsqlite3-dev
RUN pip install -U pip setuptools

COPY requirements.txt /webapps/
RUN pip install -r /webapps/requirements.txt
ADD . /webapps/
WORKDIR /webapps
EXPOSE 80

CMD ["/bin/bash", "-c", "python manage.py collectstatic --noinput && python manage.py runserver 0.0.0.0:80"]
```
- setting.py

```py
DEBUG = bool(os.getenv('DJANGO_DEBUG', True))

ALLOWED_HOSTS = [
    '127.0.0.1',
    'localhost',
    '192.168.17.237'
] + (['*'] if not os.getenv('ALLOWED_HOSTS') else os.getenv('ALLOWED_HOSTS').split(","))

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.getenv('DATABASES_NAME', 'django_rest'),
        'HOST': os.getenv('DATABASES_HOST', 'localhost'),
        'PORT': os.getenv('DATABASES_PORT', '3306'),
        'USER': os.getenv('DATABASES_USER', 'root'),
        'PASSWORD': os.getenv('DATABASES_PASSWORD', 'root'),
    },
}
```
- 编译`docker build --rm -t pybiz:1.0.0 -f ./Dockerfile .`
- k8s-helm相关配置，其他参考[Chart说明](/_posts/devops/helm.md#Chart说明)

```yml
## values.yaml
deployment:
  env:
    ALLOWED_HOSTS: 192.168.17.237
    DATABASES_NAME: pybiz
    DATABASES_HOST: mysql-devops.devops.svc.cluster.local
    DATABASES_PORT: 3306
    DATABASES_USER: devops
    DATABASES_PASSWORD: devops

## templates/deployment.yaml
containers:
  env:
  - name: THIS_POD_IP
    valueFrom:
      fieldRef:
        fieldPath: status.podIP
  - name: ALLOWED_HOSTS
    # THIS_POD_IP动态获取pod-ip
    value: "$(THIS_POD_IP),{{- .Release.Name -}}.{{- .Release.Namespace -}}.svc,{{- range $k, $v := .Values.ingress.hosts -}}{{- $v.host -}}{{- end -}},{{ .Values.deployment.env.ALLOWED_HOSTS }}"
  {{- range $key,$val := .Values.deployment.env }}
  {{- if ne $key "ALLOWED_HOSTS" }}
  - name: {{ $key }}
    value: "{{ $val }}" # 一定要加双引号
  {{- end}}
  {{- end}}
```                      

## python基础

- 列表生成式

```py
>>> [x * x for x in range(1, 11)]
[1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

>>> [x * x for x in range(1, 11) if x % 2 == 0]
[4, 16, 36, 64, 100]

>>> C = [Foo, Bar]
>>> [item() for x in C]
[Foo(), Bar()]
```

- 继承

```py
# 多继承(优先级从左到右)，寻找自身属性或方法 -> 寻找最左边父类的属性或方法 -> 寻找第二个父类的属性或方法 -> ...
class StudentsView(MyBaseView, View):
    def get_super(self):
    `   # 获取父类
        super(StudentsView, self)
```

- 反射(`getattr`)

```py
class StudentsView(object):
    def run_hello(self):
        fun = getattr(self, "hello")  # 获取对象的属性或方法
        fun()

    def hello(self):
        print('hello...')
```



---

参考文章

[^1]: http://www.nanerbang.com/article/5488/ (DateTimeField如何自动设置为当前时间并且能被修改)
[^2]: https://www.cnblogs.com/huchong/p/7894660.html
[^3]: https://code.ziqiangxuetang.com/django/django-queryset-api.html
[^4]: https://code.ziqiangxuetang.com/django/django-queryset-advance.html
[^5]: https://aber.sh/articles/Django-Admin-Name/