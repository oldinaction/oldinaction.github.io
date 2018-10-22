---
layout: "post"
title: "django-rest-framework"
date: "2018-09-24 21:29"
categories: [lang]
tags: [python, django, restful]
---

## 简介

- django-rest-framework，是一套基于Django 的 REST 框架，是一个强大灵活的构建 Web API 的工具包
- [官网](https://www.django-rest-framework.org/)
- `pip3 install djangorestframework` 安装
- 10大特性：权限、认证、节流、版本控制、解析器、序列化、分页、视图、路由、渲染器
- `rest framework` **主要基于CBV模式，且大部分特性是基于必须是继承了APIView；FBV模式时上述特性无法体现。** FBV/CBV参考：[http://blog.aezo.cn/2018/09/24/lang/django/](/_posts/lang/django)

## 认证

> 可参看下文rest framework 源码解析【封装request和认证】。源码参考[A03_DjangoRestFrameworkTest]

- 自定义认证类

```py
from rest_framework import exceptions
from rest_framework.authentication import BaseAuthentication

class MyAuthentication(BaseAuthentication):
    def authenticate(self, request):
        token = request._request.GET.get('token')
        if not token:
            raise exceptions.AuthenticationFailed('无效的token')
        return ('hello', None)
    
    # 由于继承了BaseAuthentication，其中包含必须的authenticate_header方法，否则需要定义此方法
    # def authenticate_header(self, val):
    #     pass
```
- 全局认证类配置

```bash
# setting.py
REST_FRAMEWORK = {
    # 全局认证类：从第一个顺序执行认证，直到认证成功/失败
    'DEFAULT_AUTHENTICATION_CLASSES': [
        # 使用自定自定义认证类
        'smtest.utils.auth.MyFirstAuthentication',
        'smtest.utils.auth.MyAuthentication',
        # 使用rest_framework提供认证类
        'rest_framework.authentication.TokenAuthentication'
    ]
}
```
- 局部认证类配置

```py
class NoAuthView(APIView):
    # 配置局部认证类
    authentication_classes = [] # 此时则不会进行认证
    # authentication_classes = [MyAuthentication,] # 此时只执行MyAuthentication这个认证器

    def get(self,request,*args,**kwargs):
        return HttpResponse('GET...')
```
- 基于token生成的认证

```py
## smtest/models.py 实体
from django.db import models

class UserInfo(models.Model):
    roles = (
        (1, '普通用户'),
        (2, 'VIP'),
        (3, 'SVIP')
    )
    role = models.IntegerField(choices=roles)
    username = models.CharField(max_length=64, unique=True)
    password = models.CharField(max_length=64)

class UserToken(models.Model):
    user = models.OneToOneField(to='UserInfo', on_delete=models.CASCADE) # 外键的名称为此关联对象引用名加`_id`
    token = models.CharField(max_length=64)


## smtest/views.py 登录
def md5(username):
    import hashlib
    import time

    ctime = str(time.time())
    m = hashlib.md5(bytes(username, encoding='utf-8'))
    m.update(bytes(ctime, encoding='utf-8'))
    return m.hexdigest()

# 用户名密码认证, 获取token(rest_framework内部已经实现了生成token的方法)
class AuthView(APIView):
    authentication_classes = [] # 此时则不会进行认证
    # permission_classes = [] # 此时不会校验权限(尽管不校验登录, 但是rest framework默认认为是一个匿名用户) # 权限相关代码
    # throttle_classes = [VisitThrottle,] # 节流控制相关代码

    def post(self,request,*args,**kwargs):
        ret = {'code': 1000, 'msg': None}
        try:
            username = request._request.POST.get('username')
            password = request._request.POST.get('password')
            user = models.UserInfo.objects.filter(username=username, password=password).first()
            if not user:
                ret['code'] = 1001
                ret['msg'] = "用户名或密码错误"
                return JsonResponse(ret)

            # 生成token
            token = md5(username)
            models.UserToken.objects.update_or_create(user=user, defaults={'token': token})
            ret['token'] = token
        except Exception as e:
            print(e)
            ret['code'] = 1002
            ret['msg'] = "未知错误"
        return JsonResponse(ret)


## smtest/utils/auth.py 认证
class MyAuthentication(BaseAuthentication):
    def authenticate(self, request):
        token = request._request.GET.get('token')
        user_token = models.UserToken.objects.filter(token=token).first()
        if not user_token:
            raise exceptions.AuthenticationFailed('无效的token')
        return (user_token.user, user_token)
```

### 使用rest framework认证模块

- setting.py配置

```py
INSTALLED_APPS = [
    # ...
    'rest_framework',
    # 会生成表 authtoken_token
    'rest_framework.authtoken',
]

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        # 优先基于session认证，然后基于Token认证。session登录成功则不会产生token
        # 'rest_framework.authentication.SessionAuthentication',
        # 根据token认证 -> 获取用户信息 (header中加：-H 'authorization: Token eb1957411275098fffdea0570fcce8817dbbb556')
        # 如果header中无token相关信息则返回None ->> django.contrib.auth.models.AnonymousUser
        'rest_framework.authentication.TokenAuthentication',
        # 解决 rest_framework.authentication.TokenAuthentication 中无token也可访问问题
        'myproject.utils.auths.MyTokenAuthentication',
    ]
}
```
- MyTokenAuthentication

```py
# myproject/utils/auths.py
from rest_framework import authentication
from rest_framework import exceptions

class MyTokenAuthentication(authentication.TokenAuthentication):
    keyword = 'access_token'

    def authenticate(self, request):
        auth = authentication.get_authorization_header(request).split()
        if not auth or auth[0].lower() != self.keyword.lower().encode():
            # 也可在对应请求类型中加参数，如GET：?access_token=a9074b1fd0ef2c0f2a6f96dab7963de17d4efa91
            data = getattr(request, request._request.method)
            token = data.get(self.keyword)
            if token:
                return self.authenticate_credentials(token)
            if not token:
                msg = "请在header中添加access_token信息。如：-H 'Authorization: Token a9074b1fd0ef2c0f2a6f96dab7963de17d4efa91'"
                raise exceptions.AuthenticationFailed(msg)

# 基于用户名密码获取时不校验token
from rest_framework.authtoken.views import ObtainAuthToken

class BizTokenBackend(ObtainAuthToken):
    """基于用户名/密码获取Token"""
    # 登录不进行验证(ObtainAuthToken会走所有的authentication_classes)
    authentication_classes = ()
```

- urls.py

```py
from myproject.utils.auths import BizTokenBackend

urlpatterns = [
    # 基于session认证的登录界面和登录/登出处理
    # 引入rest_framework的登录界面(此视图是基于django的backends进行验证, 会在api主页添加Login/Logout超链接)
    # rest_framework的登录界面中提交认证form表单的action为 api-auth/login。登录/登出处理不走APIView的dispatch
    # url(r'^api-auth/', include('rest_framework.urls', namespace='rest_framework')),
    
    # 根据用户名/密码获取Token
    # curl获取token: curl -X POST http://127.0.0.1:8000/api-auth-token/ -F username=admin -F password=admin
    # 返回 {"token": "a9074b1fd0ef2c0f2a6f96dab7963de17d4efa91"} # token保存在表 authtoken_token
    url(r'^api-auth-token/', BizTokenBackend.as_view()),
    # ...
]
```

## 权限

> 可参看下文rest framework 源码解析【封装request和认证，权限】。源码参考[A03_DjangoRestFrameworkTest]

- 自定义权限类

```py
## smtest/utils/permission.py
from rest_framework.permissions import BasePermission

# 可不继承BasePermission，但是习惯继承此类
class VIPPermission(BasePermission):
    # 无权访问时的提示信息
    message = '您尚不是VIP用户'

    def has_permission(self, request, view):
        if request.user.role >= 2:
            return True

class SVIPPermission(BasePermission):
    def has_permission(self, request, view):
        if request.user.role == 3:
            return True
```
- 全局权限类配置

```bash
# setting.py
REST_FRAMEWORK = {
    # 全局权限类
    'DEFAULT_PERMISSION_CLASSES': [
        'smtest.utils.permission.VIPPermission'
    ]
}
```
- 局部权限类配置

```py
class OrderView(APIView):
    # 局部权限类配置
    permission_classes = [SVIPPermission,]

    def get(self,request,*args,**kwargs):
        return HttpResponse('svip order...')
```

## 访问控制/节流

> 可参看下文源码解析【封装request和认证，权限】。源码参考[A03_DjangoRestFrameworkTest]

- 自定义节流类

```py
from rest_framework.throttling import BaseThrottle, SimpleRateThrottle
import time

ADDR_VISIT = {}

class TestThrottle(object):
    """自定义节流类(根据IP实现).也可简单继承BaseThrottle"""
    def __init__(self):
        self.history = []

    def allow_request(self, request, view):
        ctime = time.time()
        # 获取IP。如果从request取某个属性取不到，则会到request._request中去取
        remote_addr = request.META.get('REMOTE_ADDR')
        if remote_addr not in ADDR_VISIT:
            ADDR_VISIT[remote_addr] = [ctime,]
            return True
        history = ADDR_VISIT.get(remote_addr)
        self.history = history
        # 最早的一个访问时间如果如果小于当前时间减60秒则移除掉此访问时间记录
        while history and history[-1] < ctime - 60:
            history.pop()
        # 多长时间内最多访问的次数
        if len(history) < 3:
            history.insert(0, ctime)
            return True

    def wait(self):
        '''还需要等多长时间才可访问'''
        ctime = time.time()
        return 60 - (ctime - self.history[-1])

class VisitThrottle(SimpleRateThrottle):
    """继承SimpleRateThrottle节流类：可简单配置访问频率"""
    # 配置文件中 DEFAULT_THROTTLE_RATES 的key名. 'THROTTLE_RATES': {'MyThrottleVIP': '10/m'} # 10/m表示每分钟访问10次
    scope = 'VisitThrottle'

    def get_cache_key(self, request, view):
        # 返回IP地址
        return self.get_ident(request)

class VIPThrottle(SimpleRateThrottle):
    scope = 'VIPThrottle'

    def get_cache_key(self, request, view):
        # 返回用户名为缓存key
        return request.user.username
```
- 全局限流配置

```bash
REST_FRAMEWORK = {
    # 节流
    'DEFAULT_THROTTLE_CLASSES': [
        'smtest.utils.throttle.VIPThrottle'
    ],
    # 节流频率配置。继承SimpleRateThrottle节流类时，配置的节流频率
    'DEFAULT_THROTTLE_RATES': {
        'VisitThrottle': '5/m',
        'VIPThrottle': '10/m'
    }
}
```
- 局部限流配置

```py
class OrderView(APIView):
    # permission_classes = [SVIPPermission,]
    # 局部限流类
    throttle_classes = [TestThrottle,]

    def get(self,request,*args,**kwargs):
        return HttpResponse('svip order...')
```

## 版本控制

> 原理类似认证。源码参考[A03_DjangoRestFrameworkTest2]

- 全局配置

```bash
REST_FRAMEWORK = {
    # 版本控制类(基于路径)。还有基于url参数的控制类QueryParameterVersioning、基于域名的HostNameVersioning(v1.aezo.cn)
    'DEFAULT_VERSIONING_CLASS': 'rest_framework.versioning.URLPathVersioning',
    # 默认版本
    'DEFAULT_VERSION': 'v1',
    # 允许的版本
    'ALLOWED_VERSIONS': ['v1', 'v2'],
    # 版本字段名称(url中正则表达式会用到)
    'VERSION_PARAM': 'version'
}
```
- url配置

```py
urlpatterns = [
    # name='t_version'在反向生成url时会用到
    url(r'^(?P<version>[v1|v2]+)/test_version/$', views.VersionTest.as_view(), name='t_version'),
]
```
- 版本获取

```py
from django.shortcuts import render, HttpResponse
from rest_framework.views import APIView
from django.urls import reverse

class VersionTest(APIView):
    def get(self, request, *args, **kwargs):
        # self.dispatch

        # rest_framework.versioning.QueryParameterVersioning
        # GET /something/?version=v1 HTTP/1.1
        # request._request.GET.get('version')
        # request.query_params.get('version')

        # GET /v1/something/ HTTP/1.1
        # 获取版本
        print(request.version)
        # 获取版本处理对象(rest_framework.versioning.URLPathVersioning)
        print(request.versioning_scheme)

        # 基于rest_framework反向生成url. http://127.0.0.1:8000/api/v1/test_version/
        u1 = request.versioning_scheme.reverse(viewname='t_version', request=request)
        print(u1)

        # 基于django反向生成url. /api/v2/test_version/
        u2 = reverse(viewname='t_version', kwargs={'version': 'v2'})
        print(u2)

        return HttpResponse('GET...')
```

## 解析器

> 源码参考[A03_DjangoRestFrameworkTest2]

- 全局配置

```py
REST_FRAMEWORK = {
    # 全局解析器配置(还有上传文件的 MultiPartParser 等)
    'DEFAULT_PARSER_CLASSES': ['rest_framework.parsers.JSONParser', 'rest_framework.parsers.FormParser']
}
```

- 局部配置及获取数据

```py
class ParserTest(APIView):
    # parser_classes = [JSONParser, FormParser] # 局部解析器配置

    def post(self, request, *args, **kwargs):
        # self.dispatch
        """
        只有执行request.data时才会执行下列流程(源码从request.data开始查看)

        request.data ->> self._load_data_and_files ->> self._parse ->> self.negotiator.select_parser(self, self.parsers)
            ->> select_parser(DefaultContentNegotiation) ->> parser.parse

        1.获取请求
        2.获取用户请求体
        3.获取用户请求头，到parser_classes = [JSONParser, FormParser]中循环比较解析器是否支持此请求头(根据media_type判断)
        4.相应解析器将请求体进行解析
        5.获取数据
            JSONParser: application/json <<- {'name': 'smalle'}
            FormParser: application/x-www-form-urlencoded <<- <QueryDict: {'name': ['smalle']}>
            MultiPartParser: multipart/form-data(普通的表单提交)
        """
        print(request.data)

        return HttpResponse('ParserTest...')
```
- django请求头相关
    - `request.POST`中有值(从`request.body`中取值的)的前提
        - 请求头必须是`application/x-www-form-urlencoded`
        - 请求数据格式必须是`name=smalle&age=18`
    - `<form>`和`ajax`默认都是`application/x-www-form-urlencoded`
        - `<form>`的请求格式即为`name=smalle&age=18`
        - `jquery`中`ajax`的`data`属性传入的值尽管是json对象，但是jquery内部会转换成`name=smalle&age=18`
    - 将ajax的请求头改成`application/json`，此时`request.POST`中无值(data何种形式都不行)，`request.body`中有值

## 序列化

> 原理参考下文。源码参考[A03_DjangoRestFrameworkTest2]

### 定义序列化操作器

-继承`Serializer`或`ModelSerializer`

```py
from rest_framework import serializers
from . import models
import json

class UserRoleSerializer(serializers.Serializer):
    """简单类序列化示例"""
    # 默认属性名为字段名
    id = serializers.IntegerField()
    title = serializers.CharField()

class UserInfoSerializer(serializers.Serializer):
    """复杂类序列化示例"""
    id = serializers.IntegerField()
    username = serializers.CharField()

    level = serializers.IntegerField()
    # source指向了model的字段名，此时序列话的key名才可定义成其他。此时结果同上面的level
    level_2 = serializers.CharField(source='level')
    # 内部执行了 row.get_xxx_display()
    level_name = serializers.CharField(source='get_level_display')

    group = serializers.CharField(source='group.title')
    # 自定义显示，必须定义个方法名为`get_序列化字段名`
    roles = serializers.SerializerMethodField()

    def get_roles(self, row):
        roles = row.role.all()
        ret = []
        for item in roles:
            ret.append({
                'id': item.id,
                'title': item.title
            })
        return ret

class UserInfoSerializer2(serializers.ModelSerializer):
    """继承ModelSerializer"""
    level_name = serializers.CharField(source='get_level_display')
    group = serializers.CharField(source='group.title')
    roles = serializers.SerializerMethodField()

    class Meta:
        model = models.UserInfo
        # 映射model的全部字段
        # fields = '__all__'
        fields = ['id', 'username', 'level_name', 'group', 'roles']

    def get_roles(self, row):
        roles = row.role.all()
        ret = []
        for item in roles:
            ret.append({
                'id': item.id,
                'title': item.title
            })
        return ret

class UserInfoSerializer3(serializers.ModelSerializer):
    """继承ModelSerializer，且定义深度"""
    class Meta:
        model = models.UserInfo
        # 映射model的全部字段
        fields = '__all__'
        # fields = ['id', 'username', 'group', 'role']

        # 默认值为0，即当前model字段。如果为1则向下再查询一层(解析此model的关系表基本字段)
        depth = 1

class UserInfoSerializer4(serializers.ModelSerializer):
    """返回链接示例"""
    # 需要定义url: url(r'^(?P<version>[v1|v2]+)/group_serializer/(?P<my_pk>\d+)$', views.SerializerGroup.as_view(), name='group_url')
    # 此相当于根据group的id反向生成url. lookup_field默认为pk(转换的字段名); lookup_url_kwarg默认取lookup_field的值(即pk)
    group = serializers.HyperlinkedIdentityField(view_name='group_url', lookup_field='group_id', lookup_url_kwarg='my_pk')

    class Meta:
        model = models.UserInfo
        # fields = '__all__'
        fields = ['id', 'username', 'group', 'role']
        depth = 0

class GroupSerializer(serializers.ModelSerializer):
    """简单类序列化示例"""
    class Meta:
        model = models.UserGroup
        fields = '__all__'

class SerializerUserRole(APIView):
    def get(self, request, *args, **kwargs):
        roles = models.UserRole.objects.all()
        # <QuerySet [<UserRole: UserRole object (1)>, <UserRole: UserRole object (2)>]> . 不能通过json转换
        print(roles)

        # 1.基于django实现序列化
        roles2 = models.UserRole.objects.all().values('id', 'title')
        roles2 = list(roles2)
        # [{"id": 1, "title": "\u8001\u5e08"}, {"id": 2, "title": "\u540c\u5b66"}]
        ret2 = json.dumps(roles2)
        # [{"id": 1, "title": "老师"}, {"id": 2, "title": "同学"}]
        ret2 = json.dumps(roles2, ensure_ascii=False)

        # 2.基于rest framework实现序列化
        ser = UserRoleSerializer(instance=roles, many=True)
        # [OrderedDict([('id', 1), ('title', '老师')]), OrderedDict([('id', 2), ('title', '同学')])]
        print(ser.data)
        # [{"id": 1, "title": "老师"}, {"id": 2, "title": "同学"}]
        ret3 = json.dumps(ser.data, ensure_ascii=False)

        role = models.UserRole.objects.all().first()
        # 此时只有一条数据，many必须为False
        ser2 = UserRoleSerializer(instance=role, many=False)
        # {"id": 1, "title": "老师"}
        ret4 = json.dumps(ser2.data, ensure_ascii=False)

        return HttpResponse(ret4)

class SerializerUserInfo(APIView):
    def get(self, request, *args, **kwargs):
        # [
        #     {
        #         "id": 1,
        #         "username": "smalle",
        #         "level": 1,
        #         "level_2": "1",
        #         "level_name": "普通用户",
        #         "group": "A组",
        #         "roles": [
        #             {
        #                 "id": 1,
        #                 "title": "老师"
        #             },
        #             {
        #                 "id": 2,
        #                 "title": "同学"
        #             }
        #         ]
        #     },
        #     {
        #         "id": 2,
        #         "username": "aezo",
        #         "level": 2,
        #         "level_2": "2",
        #         "level_name": "VIP",
        #         "group": "A组",
        #         "roles": [
        #             {
        #                 "id": 1,
        #                 "title": "老师"
        #             }
        #         ]
        #     }
        # ]
        # 复杂类序列化
        users = models.UserInfo.objects.all()
        ser = UserInfoSerializer(instance=users, many=True)
        ret = json.dumps(ser.data, ensure_ascii=False)

        # 继承ModelSerializer序列化复杂类
        ser2 = UserInfoSerializer2(instance=users, many=True)
        ret2 = json.dumps(ser2.data, ensure_ascii=False)

        # ModelSerializer中depth的使用
        # [{"id": 1, "level": 1, "username": "smalle", "password": "123", "group": {"id": 1, "title": "A组"}, "role": [{"id": 1, "title": "老师"}, {"id": 2, "title": "同学"}]}, {"id": 2, "level": 2, "username": "aezo", "password": "123", "group": {"id": 1, "title": "A组"}, "role": [{"id": 1, "title": "老师"}]}]
        ser3 = UserInfoSerializer3(instance=users, many=True)
        ret3 = json.dumps(ser3.data, ensure_ascii=False)

        # 生成超链接. [{"id": 1, "username": "smalle", "group": "http://127.0.0.1:8000/api/v1/group_serializer/1", "role": [1, 2]}, {"id": 2, "username": "aezo", "group": "http://127.0.0.1:8000/api/v1/group_serializer/1", "role": [1]}]
        ser4 = UserInfoSerializer4(instance=users, many=True, context={'request': request})
        ret4 = json.dumps(ser4.data, ensure_ascii=False)

        return HttpResponse(ret4)

class SerializerGroup(APIView):
    """序列化超链接相关示例"""
    def get(self, request, *args, **kwargs):
        pk = kwargs.get('my_pk')
        group = models.UserGroup.objects.filter(pk=pk).first()
        ser = GroupSerializer(instance=group, many=False)
        ret = json.dumps(ser.data, ensure_ascii=False)
        return HttpResponse(ret)
```

### 提交数据验证

```py
class StartsWithValidator:
    """自定义验证器(一般不使用这种方法验证, 而使用钩子函数)"""
    def __init__(self, base):
        self.base = base

    def __call__(self, value):
        '''序列化执行器会自动调用此方法, value即为提交的参数值'''
        if not value.startswith(self.base):
            message = '用户名必须以 %s 开头' % self.base
            raise serializers.ValidationError(message)

class UserInfoValidateSerializer(serializers.Serializer):
    # username = serializers.CharField()
    # username = serializers.CharField(error_messages={'required': '用户名不能为空'})
    # username = serializers.CharField(error_messages={'required': '用户名不能为空'}, validators=[StartsWithValidator('aezo_'),])
    username = serializers.CharField(error_messages={'required': '用户名不能为空'})

    # 验证器钩子函数(validate_属性名)
    def validate_username(self, value):
        if not value.startswith('aezocn_'):
            message = '用户名必须以 aezocn_ 开头'
            raise serializers.ValidationError(message)
        else:
            # 此时验证通过需要将原始值返回
            return value

class SerializerUserInfoValidate(APIView):
    def post(self, request, *args, **kwargs):
        ser = UserInfoValidateSerializer(data=request.data)
        if ser.is_valid():
            print(ser.validated_data['username'])
        else:
            # {'username': [ErrorDetail(string='This field is required.', code='required')]}
            # {'username': [ErrorDetail(string='用户名必须以 aezocn_ 开头', code='invalid')]}
            print(ser.errors)

        return HttpResponse('SerializerUserInfoValidate...')
```

## 分页

> 源码参考[A03_DjangoRestFrameworkTest2]

```py
from rest_framework.pagination import PageNumberPagination, LimitOffsetPagination, CursorPagination

class PageSerializer(serializers.ModelSerializer):
    class Meta:
        model = models.UserGroup
        fields = '__all__'

class MyPageNumberPagination(PageNumberPagination):
    # 基于页面和页大小分页. http://127.0.0.1:8000/api/v1/group_page/?page=2&size=3
    page_query_param = 'page'
    page_size_query_param = 'size'
    page_size = 2
    max_page_size = 10

class MyLimitOffsetPagination(LimitOffsetPagination):
    # 基于起始位置和显示大小分页. http://127.0.0.1:8000/api/v1/group_page/?offset=2&limit=3
    limit_query_param = 'limit'
    offset_query_param = 'offset'
    default_limit = 2
    max_limit = 10

class MyCursorPagination(CursorPagination):
    # 页码加密分页. http://127.0.0.1:8000/api/v1/group_page/?cursor=cD02&size=3
    cursor_query_param = 'cursor'
    page_size_query_param = 'size'
    ordering = '-id' # id降序排列
    page_size = 2
    max_page_size = 10

class GroupPage(APIView):
    def get(self, request, *args, **kwargs):
        groups = models.UserGroup.objects.all()

        # page = PageNumberPagination() # 默认的分页类，需在配置文件中加`PAGE_SIZE`
        # page = MyPageNumberPagination()
        # page = MyLimitOffsetPagination()
        page = MyCursorPagination()

        page_groups = page.paginate_queryset(queryset=groups, request=request, view=self)
        ser = PageSerializer(instance=page_groups, many=True)

        # ret = json.dumps(ser.data, ensure_ascii=False)
        # return HttpResponse(ret)

        # 基于页面加密返回必须使用此返回(其中包含了下一页/上一页的cursor值)
        return page.get_paginated_response(ser.data)
```

## 渲染器

> 源码参考[A03_DjangoRestFrameworkTest2]

- 注册rest_framework

```bash
INSTALLED_APPS = [
    # ...
    # 注册之后可使用器渲染器
    'rest_framework'
]
```

- 全局配置

```bash
REST_FRAMEWORK = {
    # ...
    # 全局渲染器(可省略，默认即为这两个渲染器)
    'DEFAULT_RENDERER_CLASSES': ['rest_framework.renderers.JSONRenderer', 'rest_framework.renderers.BrowsableAPIRenderer']
}
```

- 使用`Response`返回数据

```py
from rest_framework.renderers import JSONRenderer, BrowsableAPIRenderer, AdminRenderer
from rest_framework.response import Response

class SerializerGroup(APIView):
    # 局部配置
    # renderer_classes = [JSONRenderer, BrowsableAPIRenderer]

    def get(self, request, *args, **kwargs):
        pk = kwargs.get('my_pk')
        group = models.UserGroup.objects.filter(pk=pk).first()
        ser = GroupSerializer(instance=group, many=False)

        # 只能返回json
        # ret = json.dumps(ser.data, ensure_ascii=False)
        # return HttpResponse(ret)

        # 可进行判断是返回json还是api(页面展示)
        return Response(ser.data)
```

- 访问 `http://127.0.0.1:8000/api/v1/group_serializer/1` **在浏览器(api页面)和postman(json数据)中可自动识别**
    - `http://127.0.0.1:8000/api/v1/group_serializer/1?format=api` 返回api页面
    - `http://127.0.0.1:8000/api/v1/group_serializer/1?format=json` **只返回json数据**
- 修改api模板可参看下文渲染器源码解析

## 视图

> 源码参考[A03_DjangoRestFrameworkTest2]

- 继承关系
    - `django`应该可以继承`View`，`rest framework`应用可以使用下面所有视图类。常用：`ModelViewSet`、`GenericViewSet`、`APIView`

```mermaid
classDiagram
    View <|-- APIView
    APIView <|-- GenericAPIView

    ViewSetMixin <|-- GenericViewSet
    GenericAPIView <|-- GenericViewSet

    CreateModelMixin <|-- ModelViewSet
    RetrieveModelMixin <|-- ModelViewSet
    UpdateModelMixin <|-- ModelViewSet
    DestroyModelMixin <|-- ModelViewSet
    ListModelMixin <|-- ModelViewSet
    GenericViewSet <|-- ModelViewSet
```

- `ModelViewSet`使用
    - 路由配置

        ```py
        url(r'^(?P<version>[v1|v2]+)/view_test/$', views.ViewTest.as_view({'get': 'list', 'post': 'create'})),
        # 如果是get类型的请求，则执行retrieve方法(RetrieveModelMixin)；如果是put类型请求则全部更新，执行update方法；如果是patch类型请求则局部更新，执行partial_update(UpdateModelMixin)
        url(r'^(?P<version>[v1|v2]+)/view_test/(?P<pk>\d+)/$', views.ViewTest.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'})),
        ```
    - 视图

        ```py
        from rest_framework.generics import GenericAPIView
        from rest_framework.viewsets import GenericViewSet, ModelViewSet

        class UserRoleSerializer2(serializers.ModelSerializer):
            class Meta:
                model = models.UserRole
                fields = '__all__'

        class ViewTest(ModelViewSet):
            queryset = models.UserRole.objects.all()
            # 序列化必须是ModelSerializer的，否则新增报错
            serializer_class = UserRoleSerializer2
            # pagination_class = api_settings.DEFAULT_PAGINATION_CLASS
            pagination_class = MyPageNumberPagination
        ```

## 路由

```py
## urls.py
urlpatterns = [
    path('admin/', admin.site.urls),
    url(r'^hello/', views.hello), # FBV
    url(r'^test/', views.TestView.as_view()), # CBV
    url(r'^api/', include('smtest2.urls')),
]

## smtest2/urls.py
from django.conf.urls import url, include
from rest_framework import routers
from . import views

router = routers.DefaultRouter()
router.register(r'url_test', views.ViewTest)

urlpatterns = [
    # 其中 (?P<version>[v1|v2]+) 参考上文版本控制
    # url(r'^(?P<version>[v1|v2]+)/test_version/$', views.VersionTest.as_view(), name='t_version'),
    # url(r'^(?P<version>[v1|v2]+)/test_parser/$', views.ParserTest.as_view()),
    # url(r'^(?P<version>[v1|v2]+)/user_role_serializer/$', views.SerializerUserRole.as_view()),
    # url(r'^(?P<version>[v1|v2]+)/user_info_serializer/$', views.SerializerUserInfo.as_view()),
    # url(r'^(?P<version>[v1|v2]+)/group_serializer/(?P<my_pk>\d+)/$', views.SerializerGroup.as_view(), name='group_url'),
    # url(r'^(?P<version>[v1|v2]+)/user_info_serializer_validate/$', views.SerializerUserInfoValidate.as_view()),
    # url(r'^(?P<version>[v1|v2]+)/group_page/$', views.GroupPage.as_view()),

    # url(r'^(?P<version>[v1|v2]+)/view_test/$', views.ViewTest.as_view({'get': 'list', 'post': 'create'})),
    # 如果是get类型的请求，则执行retrieve方法(RetrieveModelMixin)；如果是put类型请求则全部更新，执行update方法；如果是patch类型请求则局部更新，执行partial_update(UpdateModelMixin)
    # url(r'^(?P<version>[v1|v2]+)/view_test/(?P<pk>\d+)/$', views.ViewTest.as_view({'get': 'retrieve', 'put': 'update', 'patch': 'partial_update', 'delete': 'destroy'})),
    
    # 可访问 /group_page_format.json 和 /group_page_format.api 获取数据的不同展现形式
    # url(r'^(?P<version>[v1|v2]+)/group_page_format\.(?P<format>\w+)$', views.GroupPage.as_view()),

    # 自动生成ViewTest视图的url，其中包含了format。简单的增删查改可直接自动生成
    url(r'^(?P<version>[v1|v2]+)/', include(router.urls)),
]
```

## 其他

### 跨域

- 使用`corsheaders`，参考：https://github.com/ottoyiu/django-cors-headers/
- `pip install django-cors-headers` 安装
- setting.py配置

```py
INSTALLED_APPS = (
    ...
    'corsheaders',
    ...
)

MIDDLEWARE = [  # Or MIDDLEWARE_CLASSES on Django < 1.10
    ...
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    ...
]

# 开启所有
CORS_ORIGIN_ALLOW_ALL = True
# 允许部分
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
```

### 异常处理

```py
## settings.py
REST_FRAMEWORK = {
    # ...
    'EXCEPTION_HANDLER': 'myproject.utils.exceptions.custom_exception_handler',
}

## myproject/utils/exceptions.py
from rest_framework.views import exception_handler, Response

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)
    if response is not None:
        response.data['status_code'] = response.status_code
        return response
    else:
        return Response({'status_code': 500})
```

### 禁用crsf

```py
MIDDLEWARE = [
    # ...
    # 注释crsf中间件
    # 'django.middleware.csrf.CsrfViewMiddleware',
    # ...
]
```

## rest framework 源码解析

### 封装request和认证 [^1]

- CBV模式下视图类继承rest_framework的`APIView`对象(继承了django的View对象)，所有的请求也会先进入到`self.dispatch()`方法。封装request和认证过程如下

```py
## rest_framework/views.py
def dispatch(self, request, *args, **kwargs):
    self.args = args
    self.kwargs = kwargs
    # 1.对原始request重新组装。return Request(request, parsers=self.get_parsers(), authenticators=self.get_authenticators(), negotiator=self.get_content_negotiator(), parser_context=parser_context)
    # 1.1 新request中包含了原始request(request._request)、authenticators认证类对象数组([TokenAuthentication(),])
    # 1.2 authenticators=self.get_authenticators()返回的是return [auth() for auth in self.authentication_classes]
    request = self.initialize_request(request, *args, **kwargs)
    self.request = request
    self.headers = self.default_response_headers  # deprecate?

    try:
        # 2.认证/权限/节流...。实现认证：self.perform_authentication(request) ->> request.user ->> self._authenticate() ->> authenticator.authenticate(self)
        self.initial(request, *args, **kwargs)
    # ...

## rest_framework/request.py
def _authenticate(self):
    for authenticator in self.authenticators:
        try:
            # 调用认证方法
            # 1.认证抛出异常，执行self._not_authenticated()，并将异常raise(向上抛出)
            # 2.认证方法返回一个元组，(user, auth) => (request.user, request.auth)
            # 3.认证方法返回None，此时循环下一个认证器。如果都为None则执行self._not_authenticated()，此时默认返回匿名用户(AnonymousUser, None)
            user_auth_tuple = authenticator.authenticate(self)
        except exceptions.APIException:
            self._not_authenticated()
            raise

        if user_auth_tuple is not None:
            self._authenticator = authenticator
            self.user, self.auth = user_auth_tuple
            return

    self._not_authenticated()
```

### 权限

```py
## rest_framework/views.py
# 权限：dispatch ->> initial ->> check_permissions
def check_permissions(self, request):
    # get_permissions <<- return [permission() for permission in self.permission_classes]
    for permission in self.get_permissions():
        if not permission.has_permission(request, self):
            self.permission_denied(
                # 获取permission对象的message属性，用于返回错误
                request, message=getattr(permission, 'message', None)
            )
```

### 访问控制/节流

```py
## rest_framework/views.py
# 节流：dispatch ->> initial ->> check_throttles
def check_throttles(self, request):
    # return [throttle() for throttle in self.throttle_classes]
    for throttle in self.get_throttles():
        if not throttle.allow_request(request, self):
            self.throttled(request, throttle.wait())
```

- 内置节流类(`SimpleRateThrottle`)

```py
## rest_framework/throttling.py
class SimpleRateThrottle(BaseThrottle):
    cache = default_cache
    timer = time.time
    cache_format = 'throttle_%(scope)s_%(ident)s'
    scope = None
    THROTTLE_RATES = api_settings.DEFAULT_THROTTLE_RATES

    def __init__(self):
        if not getattr(self, 'rate', None):
            # 1.反射获取rate属性，没有则self.get_rate()
            self.rate = self.get_rate()
        # 2.配置文件中配置self.rate = '10/m', 进行self.parse_rate解析
        self.num_requests, self.duration = self.parse_rate(self.rate)

    def get_cache_key(self, request, view):
        raise NotImplementedError('.get_cache_key() must be overridden')

    def get_rate(self):
        # ...
        # 通过scope值到self.THROTTLE_RATES(api_settings.DEFAULT_THROTTLE_RATES)配置文件中取值
        return self.THROTTLE_RATES[self.scope]
        # ...

    def parse_rate(self, rate):
        # ...
        num, period = rate.split('/')
        num_requests = int(num)
        # period[0]表示period的第一个字母，此时得到duration=60(s)
        duration = {'s': 1, 'm': 60, 'h': 3600, 'd': 86400}[period[0]]
        return (num_requests, duration)

    def allow_request(self, request, view):
        # ...
        # self.get_cache_key获取一个缓存key(此方法有子类实现)
        self.key = self.get_cache_key(request, view)
        if self.key is None:
            return True

        # 从缓存中获取访问历史(使用django缓存)
        self.history = self.cache.get(self.key, [])
        # ...

    # ...
```

### 序列化

```py
# 1.序列化处理对象
## rest_framework/serializers.py
class BaseSerializer(Field):
    # 继承关系：UserInfoSerializer -> ModelSerializer -> Serializer -> BaseSerializer
    # python类实例化：Foo() ->> 先执行 __new__ ->> 再执行此 __new__ 方法返回对象的 __init__(如果此时返回的是Bar，那么只会执行Bar的 __init__，而不会执行Foo中的__init__)。如果Foo中没有定义__new__，则直接执行Foo的 __init__ 方法
    def __init__(self, instance=None, data=empty, **kwargs):
        self.instance = instance
        if data is not empty:
            self.initial_data = data
        self.partial = kwargs.pop('partial', False)
        self._context = kwargs.pop('context', {})
        kwargs.pop('many', None)
        super(BaseSerializer, self).__init__(**kwargs)

    def __new__(cls, *args, **kwargs):
        if kwargs.pop('many', False):
            # many=True 处理QuerySet时，获取序列化处理对象
            return cls.many_init(*args, **kwargs)
        # many = False 处理单个对象时，返回实例化对象(self)
        return super(BaseSerializer, cls).__new__(cls, *args, **kwargs)

    @classmethod
    def many_init(cls, *args, **kwargs):
        # ...
        # 获取 Meta 类
        meta = getattr(cls, 'Meta', None)
        # 如果 Meta 类没有 list_serializer_class 属性，则默认使用 ListSerializer 实例化对象(处理虚拟化)
        list_serializer_class = getattr(meta, 'list_serializer_class', ListSerializer)
        return list_serializer_class(*args, **list_kwargs)

# 2.从ser.data(ser = UserRoleSerializer(instance=roles, many=True))开始解读源码。此时只考虑解析单个对象，List同理
# ser.data ->> self.to_representation ->> field.to_representation
## rest_framework/serializers.py
class Serializer(BaseSerializer):
    @property
    def data(self):
        # 返回父类data
        ret = super(Serializer, self).data
        return ReturnDict(ret, serializer=self)

class BaseSerializer(Field):
    @property
    def data(self):
        # ...
        if not hasattr(self, '_data'):
            # 执行self.to_representation方法
            if self.instance is not None and not getattr(self, '_errors', None):
                self._data = self.to_representation(self.instance)
            elif hasattr(self, '_validated_data') and not getattr(self, '_errors', None):
                self._data = self.to_representation(self.validated_data)
            else:
                self._data = self.get_initial()
        return self._data

class ModelSerializer(Serializer):
    def to_representation(self, instance):
        ret = OrderedDict()
        fields = self._readable_fields

        # fields为序列化中定义的字段 [id = serializers.IntegerField(), username = serializers.CharField(), ...]
        for field in fields:
            try:
                # CharField().get_attribute(user对象), 对象.username
                attribute = field.get_attribute(instance)
            except SkipField:
                continue

            check_for_none = attribute.pk if isinstance(attribute, PKOnlyObject) else attribute
            if check_for_none is None:
                ret[field.field_name] = None
            else:
                # 执行每个字段类型的to_representation获取数据的展现值
                # CharField().to_representation()
                # HyperlinkedIdentityField().to_representation() # 包含了反向生成url
                ret[field.field_name] = field.to_representation(attribute)

        return ret

## rest_framework/fields.py
# 继承关系 CharField -> Field
class Field(Field):
    def get_attribute(self, instance):
        try:
            # self.source_attrs = self.source.split('.')
            # instance对象：user。source：group.title/get_level_display/role.all
            return get_attribute(instance, self.source_attrs)
        # ...

def get_attribute(instance, attrs):
    # attrs = [group, title]/[get_level_display]/[role, all]
    for attr in attrs:
        try:
            # 是否为字典(字段必须用 [] 取值，class对象可通过 . 取值)
            if isinstance(instance, collections.Mapping):
                instance = instance[attr]
            else:
                # 第一次循环相当于 instance = instance.group
                # 第二次循环相当于 instance = group.title
                # 如果是 get_level_display, 则第一次循环相当于 instance = instance.get_level_display
                instance = getattr(instance, attr)
        except ObjectDoesNotExist:
            return None
        if is_simple_callable(instance):
            try:
                # instance.get_level_display 是一个可执行的方法，则执行方法获取
                instance = instance()
            # ...

    # 返回属性值(此时instance已经变成属性值)
    return instance        

# 3.验证
# ser.is_valid() ->> self.run_validation ->> Serializer().run_validation() ->> self.to_internal_value ->> validate_xxx() ->> self.run_validators
## rest_framework/serializers.py
class BaseSerializer(Field):
    def is_valid(self, raise_exception=False):
        # ...
        if not hasattr(self, '_validated_data'):
            try:
                # 执行 run_validation 方法(从SerializerUserInfo -> ModelSerializer -> Serializer -> BaseSerializer -> Field依次查询此方法。注意不要使用PyCharm左键点击，这样找到的不准确)。比如此时执行Serializer().run_validation()
                self._validated_data = self.run_validation(self.initial_data)
            except ValidationError as exc:
                self._validated_data = {}
                self._errors = exc.detail
            else:
                self._errors = {}

        if self._errors and raise_exception:
            raise ValidationError(self.errors)

        return not bool(self._errors)

@six.add_metaclass(SerializerMetaclass)
class Serializer(BaseSerializer):
    def run_validation(self, data=empty):
        (is_empty_value, data) = self.validate_empty_values(data)
        if is_empty_value:
            return data

        # 获取内部值(获取执行用户验证器钩子函数后的值)
        value = self.to_internal_value(data)
        try:
            # 执行 validators 参数中的验证器
            self.run_validators(value)
            value = self.validate(value)
            assert value is not None, '.validate() should return the validated data'
        except (ValidationError, DjangoValidationError) as exc:
            raise ValidationError(detail=as_serializer_error(exc))

        return value

    def to_internal_value(self, data):
        # ...
        for field in fields:
            # 获取此序列化执行器的验证器钩子函数 `validate_序列化类属性名`
            validate_method = getattr(self, 'validate_' + field.field_name, None)
            primitive_value = field.get_value(data)
            try:
                # 执行字段验证器。如 serializers.EmailField
                validated_value = field.run_validation(primitive_value)
                if validate_method is not None:
                    # 执行验证器钩子函数
                    validated_value = validate_method(validated_value)
            except ValidationError as exc:
                errors[field.field_name] = exc.detail
            # ...

        if errors:
            raise ValidationError(errors)

        return ret
```

### 渲染器

```py
# rest_framework/renderers.py
class BrowsableAPIRenderer(BaseRenderer):
    media_type = 'text/html'
    format = 'api'
    
    # 继承此类，重新指定以下两个模板，即可修改api页面排版
    template = 'rest_framework/api.html'
    filter_template = 'rest_framework/filters/base.html'
    
    code_style = 'emacs'
    charset = 'utf-8'
    form_renderer_class = HTMLFormRenderer
    # ...
```




---

参考文章

[^1]: https://www.bilibili.com/video/av28871471/?p=11
