在项目中我们已经使用到Django Form和ModelForm的验证功能，这一节我通过一些例子来了解更多Django表单的用法（本节代码非项目代码，测试完后既可删除）。

## 1 使用表单
在【Django实战1-权限管理功能实现-03：用户认证】一节，已经使用到HTML表单功能，通过HTML表单向后台提交用户信息，完成用户的登陆认证。
我们来看下sandboxMP/templates/system/users/login.html内容：
```html
{% extends "system/users/user-base.html" %}

{% block user-content %}
<!-- /.login-logo -->
<div class="login-box-body form-">
    <p class="login-box-msg"></p>
    <p></p>
    <form action="" method="post">
      <div class="form-group has-feedback {% if login_form.errors.username %}has-error{% endif %}">
        <input name="username" class="form-control" placeholder="用户名或手机号" value="{{ login_form.username.value }}">  <!--type="email"前端控制email输入验证-->
        <span class="glyphicon glyphicon-envelope form-control-feedback"></span>
      </div>
      <div class="form-group has-feedback {% if login_form.errors.password %}has-error{% endif %}">
        <input name="password" type="password" class="form-control" placeholder="密码"
               value="{{ login_form.password.value }}">
        <span class="glyphicon glyphicon-lock form-control-feedback"></span>
      </div>
      <div class="row">
        <div class="col-xs-8">
        </div>
        <!-- /.col -->
        <div class="col-xs-4">
          <button type="submit" class="btn btn-primary btn-block btn-flat">登录</button>
        </div>
        <!-- /.col -->
      </div>
        {% csrf_token %}
    </form>
    {% if msg %} <!--判断如果后端返回用户验证错误信息,前端页面输出错误信息-->

        <p class="text-red">{{ msg }}</p>

    {% endif %}


  </div>
  <!-- /.login-box-body -->
</div>
<!-- /.login-box -->
{% endblock %}
```

登陆页面标签说明：

1、<form action="" method="post"> ：定义了form的HTTP方法为POST, 和请求地址为当前页
2、<input name="username"> ：input类型，用户接收用户输入内容，其中name属性定义了input元素的名称，用于对提交到服务器后的表单数据进行识别。
3、<button type="submit">登录</button>：提交按钮
4、{% csrf_token %}：当提交一个启用CSRF防护的POST表单时，必须使用上面的csrf_token 模板标签

### 1.1 在django中创建表单
前面使用到的表单，是通过在模板中创建的HTML表单，我们还可以使用Djang提供的Form类来自动生成表单，并渲染到HTML中。
1、修改sandboxMP/apps/system/forms.py，加入如下内容：
```python
from django import forms

class UserTestForm(forms.Form):
    username = forms.CharField(label='用户名', max_length=10)
    password = forms.CharField(label='密码'， max_length=10)
```

上面通过Form类定义了两个字段，max_length定义了输入字段的最大长度。
Form的实例具有一个is_valid()方法，可以对输入的字段进行验证，当调用这个方法时，如果所有字段输入都合法，它将返回True，并将表单的数据存放到cleaned_data属性中。

### 1.2 视图处理
通过视图将定义好的表单数据进行实例化，实现如下功能：
1、如果访问视图的是一个GET请求，创建一个空的表单，并将它渲染到模板中
2、如果是POST请求提交表单，接收表单数据，并使用is_valid()方法进行验证
3、数据验证合法则执行正常业务逻辑，数据不合法则返回错误信息
修改sandboxMP/apps/system/tests.py，加入下面内容：
```python
from django.shortcuts import render, HttpResponseRedirect
from django.views.generic.base import View
from .forms import UserTestForm


class FormTestView(View):

    def get(self, request):
        test_form = UserTestForm()
        return render(request, 'system/users/form_test.html', {'test_form': test_form})

    def post(self, request):
        test_form = UserTestForm(request.POST)
        ret = dict(test_form=test_form)
        if test_form.is_valid():
            # form验证通过后，重定向到项目首页，由于项目IndexView限制登陆访问了，如果系统没有登陆，这个重定向会先跳到登陆页面。
            return HttpResponseRedirect('/')

        return render(request, 'system/users/form_test.html', ret)
```
请注意：视图中只是为了演示Form类渲染和验证功能，只要输入数据合法即跳转到首页，并未对用户的登陆进行认证。

### 1.3 URL配置
修改sandboxMP/sandboxMP/urls.py，添加Form类测视图访问的URL:
```python
from system.tests import FormTestView

urlpatterns = [
    '''原有内容省略'''
    path('form_test/', FormTestView.as_view()),

]
```

### 1.4 模板的配置
新建模板：sandboxMP/templates/users/form_test.html，内容如下：
```html
<form action="" method="post" novalidate>
    {% csrf_token %}
    {{ test_form }}
    <input type="submit" value="Submit" />
</form>
```
运行项目，访问http://127.0.0.1:8000/form_test, 可以看到Django会根据模型类的字段和属性，在HTML中自动生成对应表单标签和标签属性。生成的标签会被放置到{{ test_form }}所在的位置。


### 1.5 表单字段
除了上面演示的forms.CharField字段外，Django的表单内置了很多的表单字段，表单内建字段查询：https://docs.djangoproject.com/en/2.1/ref/forms/fields/

### 1.6 获取表单数据
通过表单提交的数据，一旦通过调用is_valid()成功验证，然后表单的数据将存放到form.cleaned_data字典中。当然，我们依然可以从reques.POST中直接获取到未验证的数据。
1、修改sandboxMP/apps/system/tests.py，分别通过form.cleaned_data和request.POST来获取表单输入的数据：
```python
class FormTestView(View):

    def get(self, request):
        test_form = UserTestForm()
        return render(request, 'system/users/form_test.html', {'test_form': test_form})

    def post(self, request):
        test_form = UserTestForm(request.POST)
        ret = dict(test_form=test_form)
        ret['errors'] = test_form.errors.as_json()
        if test_form.is_valid():
            # 通过form.cleaned_data获取通过表单验证的数据
            username = test_form.cleaned_data['username']
            password = test_form.cleaned_data['password']
            # 依然可以通过request.POST来获取数据
            username1= request.POST['username']
            return HttpResponseRedirect('/')

        return render(request, 'system/users/form_test.html', ret)
```
2、运行调试，参照下图进行运行调试：

- 在pycharm中开启debug模式
- 在form.is_valid()验证位置打上断点
- 打开浏览器访问http://127.0.0.1:8000/form_test
- 在网页中输入用户名，密码，点击【Submit】提交表单数据
- 在pycharm中按F6进行程序调试，可以看到通过is_valid()验证后，可以通过clean_data来获取表单数据，同样也可以通过request.POST来获取表单数据
- 最后记得去掉debug断点

## 2、模型表单ModelForm
### 2.1 使用ModelForm
在【Django实战1-权限管理功能实现-05：组织架构的添加】一节中我们已经使用到了ModelForm, 通过ModelForm可以创建与Djang模型紧密映射的表单。ModelForm的优势在于，我们已经在ORM中定义好了model模型，不用再写一个forms.Form类来一个一个定义表单中的字段。
。 例如：sandboxMP/apps/system/forms.py中的StructureForm：

```python
from django import forms
from .models import Structure


class StructureForm(forms.ModelForm):
    class Meta:
        model = Structure
        fields = ['type', 'name', 'parent']
```

上面的例子中
1、创建一个类：StructureForm，它继承了forms.ModelForm；
2、在StructureForm中设置了元类Meta，设置了model属性关联到ORM模型中的Structure;
3、在Meta中设置了fields属性，定义在表单中使用的字段列表，列表里面的值是ORM模型Structure中的字段名。

### 2.2 ModelForm的字段选择
2.1中我们通过ModelForm的fields属性，通过列表的形式，添加了要使用的字段。然而有的时候要使用的字段过多，可以将fields属性设置为all，将映射的模型中的全部字段都添加到表单中。

```python
from django import forms
from .models import Structure


class StructureForm(forms.ModelForm):
    class Meta:
        model = Structure
        fields = '__all__'
```
当然也可以使用exclude属性排除某些字段，然后将剩下的字段作为表单字段。

```python
from django import forms
from .models import Structure


class StructureForm(forms.ModelForm):
    class Meta:
        model = Structure
        exclude = ['parent', ]
```
### 2.3 ModelForm的验证
与普通的表单验证类似，模型表单也可以调用is_valid()方法。

### 2.4 save()方法的使用
ModelForm有一个save()方法，这个方法根据表单绑定的数据创建并保存数据库对象。ModelForm的子类可以接受现有的模型实例作为关键字参数instance；如果提供了实例，则save()将更新该实例。 如果没有提供，save() 将创建模型的一个新实例。
在【Django实战1-权限管理功能实现-05：组织架构的添加】一节中，我们已经使用过ModelForm的save()方法。

```python
# sandboxMP/apps/system/views_structure.py中 save()方法的使用
class StructureCreateView(LoginRequiredMixin, View):

    def get(self, request):
        ret = dict(structure_all=Structure.objects.all())
        return render(request, 'system/structure/structure_create.html', ret)

    def post(self, request):
        res = dict(result=False)
        structure = Structure()
        structure_form = StructureForm(request.POST, instance=structure)
        if structure_form.is_valid():
            # 表单提交的组织架构信息数据通过structure_form验证后，调用save()方法保存到数据库对象中。
            structure_form.save()
            res['result'] = True
        return HttpResponse(json.dumps(res), content_type='application/json')
```

