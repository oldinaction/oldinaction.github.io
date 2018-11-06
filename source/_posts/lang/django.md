---
layout: "post"
title: "django"
date: "2018-09-24 21:29"
categories: [lang]
tags: [python, django]
---

## 简介

- [官网](https://www.djangoproject.com/)

## 命令

- `python manage.py startapp myapp` 创建App
- `python manage.py makemigrations` 生成迁移
- `python manage.py migrate` 执行迁移
- `python manage.py runserver` **启动项目**
    - `python manage.py runserver 0.0.0.0:8000` 启动项目(开启局域网访问)

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
    # `pip install mysqlclient-1.3.13-cp36-cp36m-win_amd64.whl` 安装客户端
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
    - `python manage.py makemigrations` 检查数据库迁移
    - `python manage.py migrate` 执行数据库迁移
    - 不建议手动到数据库删除表
- 创建管理用户(保存在auth_user表中)
    - `python manage.py createsuperuser --email admin@aezo.cn --username admin`(输入密码admin888) 
- 创建权限组数据并添加用户
    - `INSERT INTO "auth_group" ("id", "name") VALUES (1, '管理员')`
    - `INSERT INTO "auth_user_groups" ("id", "user_id", "group_id") VALUES (1, 1, 1)`

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

    # 关于联合主键
    class PartyRole(models.Model):
        party = models.ForeignKey('Party', on_delete=models.CASCADE)
        role_type = models.ForeignKey('RoleType', on_delete=models.CASCADE)

        class Meta:
            # 定义表名
            db_table = 'biz_party_role'
            # django未实现联合主键, 只能通过组合唯一建校验
            unique_together = ("party", "role_type")
    ```
- 外键/关联

    ```py
    #models.py
    # Author必须定义在Books上面
    class Author(models.Model):
        author = models.CharField(max_length=250) 
    class Books(models.Model):
        # book = models.ForeignKey('Author', on_delete=models.CASCADE) # 此时Author可以定义在Books下面。并且Author可以通过配置文件导入

        # 默认外键名为`属性名_id`
        book = models.ForeignKey(Author, on_delete=models.CASCADE)

        # 自关联
        parent_book = models.ForeignKey(to='self', on_delete=models.CASCADE)
    ```
    - `ForeignKey`、`ManyToManyField`、`OneToOneField`分别在Model中定义多对一(使用ForeignKey的表为子表)，多对多，一对一关系
    - 参数
        - `related_name`
            - father.child_set.all()。获取子表(子表Child中有一个外键，此时父表中默认会存储 `子表_set` 来获取子表；也可在子表中定义 related_name；如果子表中有某一个表的两个外键，则必须要定义related_name)
            - father.child_related_name.all()。child_related_name为子表中定义的 related_name 名称
            - book = models.ForeignKey(Author, related_name='child_related_name', on_delete=models.CASCADE)
        - `db_column` 定义外键生成的字段名
        - `on_delete` 删除主表时，对子表的行为
            - `CASCADE` 删除作者信息一并删除作者名下的所有书的信息
            - `PROTECT` 删除作者的信息时，采取保护机制，抛出错误：即不删除Books的内容
            - `SET_NULL` 只有当null=True才将关联的内容置空
            - `SET_DEFAULT` 设置为默认值
            - `SET()` 括号里可以是函数，设置为自己定义的东西
            - `DO_NOTHING` 字面的意思，啥也不干
        - `db_constraint=False` 数据库中不创建外键。但是django仍然可以通过外键属性获取关联对象

### CRUD

- 基本增删改

```py
## 增
models.MyUser.objects.create(name='smalle', password='123')

obj = models.MyUser(name='smalle', password='123')
obj.save()

# 可以接受字典类型数据 **kwargs
dic = {'name':'smalle','password':'123'}
models.tb.objects.create(**dic)

## 查
# 获取单条数据，不存在则报错（不建议）
models.MyUser.objects.get(id=1)
# 获取全部
models.MyUser.objects.all()
#获取全部数据的第1条数据
models.tb.objects.all().first()
# 获取指定条件的数据
models.MyUser.objects.filter(name='smalle')
# filter可以接受字典类型数据 **kwargs(下同)
dic = {'name':'smalle','password':'123'}
models.tb.objects.filter(**dic)

# 改
models.MyUser.objects.filter(name='smalle').update(password='123456')

obj = models.MyUser.objects.get(id=1)
obj.password = '123456'
obj.save()

# 删
models.MyUser.objects.filter(name='smalle').delete()
```

- 进阶查询

```py
# 获取个数
models.MyUser.objects.filter(sex='boy').count()

# 获取id大于1 且 小于10的值
models.MyUser.objects.filter(id__lt=10, id__gt=1)

# 获取id等于11、22、33的数据
models.MyUser.objects.filter(id__in=[1, 2, 3])
# not in
models.MyUser.objects.exclude(id__in=[1, 2, 3])

# 包含/不包含
models.MyUser.objects.filter(name__contains="aezo")
models.MyUser.objects.filter(name__icontains="aezo") # icontains大小写不敏感
models.MyUser.objects.exclude(name__icontains="aezo")

# 范围bettwen and
models.MyUser.objects.filter(id__range=[1, 10])

# order by
models.MyUser.objects.filter(sex='boy').order_by('id')    # asc
models.MyUser.objects.filter(sex='boy').order_by('-id')   # desc

# limit、offset
models.MyUser.objects.all()[10:20]

# regex正则匹配，iregex 不区分大小写
models.MyUser.objects.get(name__regex=r'^(An?|The) +')
models.MyUser.objects.get(name__iregex=r'^(an?|the) +')

# 日期
models.MyUser.objects.filter(birth_date__date=datetime.date(2000, 1, 1))
models.MyUser.objects.filter(birth_date__date__gt=datetime.date(2000, 1, 1))
models.MyUser.objects.filter(pub_date__year=2000) # 同理 __month、__day、__week_day、__hour、__minute、__second
```

- 联表查询

```py
# 外键。查询子表
father = models.Father.objects.filter(id=1).first()
father.child_set.all() # 获取子表(子表Child中有一个外键，此时父表中默认会存储 `子表_set` 来获取子表；也可在子表中定义 related_name；如果子表中有某一个表的两个外键，则必须要定义related_name)
father.child_related_name.all() # child_related_name为子表中定义的 related_name 名称
```

## 自带App

### admin

- 必须写在每个app对应根目录下的`admin.py`文件中

```py
## party/admin.py
from django.contrib import admin
from smbiz.party import models

@admin.register(models.PartyType) # 同 admin.site.register(models.PartyType, PartyTypeAdmin)
class PartyTypeAdmin(admin.ModelAdmin):
    # 列表展示的字段(Table)，默认显示 ModelName object (PK)
    list_display = ('party_type_id', 'parent_type', 'party_type_name')
    # 列表查询字段（所有的字段通过一个搜索框输入）
    search_fields = ['party_type_name', 'description']
    # 列表右边显示的过滤器(基于字段值distinct后进行快速筛选链接)
    list_filter = ['party_type_name']
    # 修改时的表单字段(此处的parent_type外键不能写成parent_type_id)
    fields = ['party_type_id', 'parent_type', 'party_type_name', 'description']
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
from smbiz.party import models

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

- 中间件类型：process_request、process_view、process_response、process_exception、process_render_template
- 中间件执行顺序：用户请求 -> 经过所有process_request -> 视图函数 -> 经过所有process_view
- CSRF(Cross-site request forgery)跨站请求伪造
    - 全站开启或关闭，看中间件配置中是否有：'django.middleware.csrf.CsrfViewMiddleware'
    - 在process_view中检查视图是否有装饰器`@crsf_exempt`(全局有csrf时，此函数不考虑csrf)、`@crsf_protect`(全局无时，此函数考虑csrf)
    - 需要csrf检查时，从前请求体或cookies中获取token
    - 在csrf存在时，且未CBV模式下，去掉某个url的csrf功能，有两种方式
        - View子类上加`@method_decorator(csrf_exempt, name='dispatch')`
        - View子类重写dispatch方法，并在dispatch方法上加`@method_decorator(csrf_exempt)`(加在其他方法上无效)

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

## 杂项

### 静态资源

- django在配置文件中设置`DEBUG = False`后静态资源404问题 
    - `python manage.py runserver --insecure` 启动加参数`--insecure`（正式环境中不建议）
    - 通过nginx获取静态资源
        - 配置文件中加 `STATIC_ROOT = os.path.join(BASE_DIR, 'static')`
        - 执行`python manage.py collectstatic`会自动生成静态资源文件到上述目录。正式环境中可配置STATIC_ROOT为nginx的静态资源目录

### 请求生命周期

![django-request](/data/images/lang/django-request.png)

### FBV/CBV模式：函数作为视图或类作为视图

> 源码参考【A02_DjangoTest】

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
        fun = getattr(self, "hello") # 获取对象的属性或方法
        fun()

    def hello(self):
        print('hello...')
```



---

参考文章

[^1]: http://www.nanerbang.com/article/5488/ (DateTimeField如何自动设置为当前时间并且能被修改)