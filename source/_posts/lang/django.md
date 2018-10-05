---
layout: "post"
title: "django"
date: "2018-09-24 21:29"
categories: [lang]
tags: [python, django]
---

## 简介

- [官网](https://www.djangoproject.com/)

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

## 自带App

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

## 杂项

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
