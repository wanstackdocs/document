菜单管理是用来管理系统中的URL信息，将系统URL全部存储到数据库，绑定角色，通过角色组来控制系统导航菜单的显示和URL的访问权限。
**为了让大家能够熟悉Django基于类视图的使用，本节将通过ajax调用接口请求json数据的方式改为Django普通数据渲染的方式，同时将会使用到更多Django通用类视图。**

## 1 菜单的添加视图

## 1.1 普通实现

按照通常方法，我们先要在sandboxMP/apps/system/forms.py中新建MenuForm，用于对提交的数据进行验证和保存：

```text
from .models import Structure, Menu

class MenuForm(forms.ModelForm):
    class Meta:
        model = Menu
        fields = '__all__'
```

然后在sandboxMP/apps/system/目录下创建新的文件views_menu.py，添加MenuCreateView：

```text
import json

from django.views.generic.base import View
from django.shortcuts import render
from django.shortcuts import HttpResponse

from .mixin import LoginRequiredMixin
from .models import Menu
from .forms import MenuForm


class MenuCreateView(LoginRequiredMixin, View):

    def get(self, request):
        ret = dict(menu_all=Menu.objects.all())
        return render(request, 'system/rbac/menu_create.html', ret)

    def post(self, request):
        res = dict(result=False)
        menu = Menu()
        menu_form = MenuForm(request.POST, instance=menu)
        if menu_form.is_valid():
            menu_form.save()
            res['result'] = True
        return HttpResponse(json.dumps(res), content_type='application/json')
```

最后配置URL和模板页，菜单的填加功能就完成了。

## 1.2 CreateView

1.1中是比较常用的添加视图的写法，接下来我们要在项目中使用CreateView来实现菜单的添加视图。在使用CreateView前先来了解下它的继承关系、数据以及方法

## 1.2.1 CreateView的继承关系

CreateView是通过多重继承组成的新类，它的继承关系如下图所示（其中打勾的是前面已经学习并使用过的类）：

![img](C:\Users\yujing\Desktop\yaml\images\v2-41868ffa2c561abd5bbc4c3af64f655d_1440w.jpg)



## 1.2.2 CreateView继承的属性

![img](https://pic4.zhimg.com/80/v2-4a3a63cb8aa40565c5ff2fbb37a4c93f_1440w.jpg)

## 1.2.3 CreateView继承的方法

![img](https://pic2.zhimg.com/80/v2-140882eafadb0e17fa6a4841d85a58d1_1440w.jpg)

![img](https://pic2.zhimg.com/80/v2-d0b5b77373822ef1bce6809e0ec13f79_1440w.jpg)

上面罗列出来的多重类继承关系、属性和方法，有空的时候建议看看源码，了解下具体实现和功能，梳理完CreateView的属性和方法后我们就开始使用CreateView重写MenuCreateView

## 1.3 使用CreateView实现菜单添加功能

1、修改sandboxMP/apps/system/views_create.py 内容：

```text
from django.views.generic import CreateView

from .mixin import LoginRequiredMixin
from .models import Menu


class MenuCreateView(LoginRequiredMixin, CreateView):
    model = Menu
    fields = '__all__'
    success_url = '/system/rbac/menu/create'
```

这样菜单添加视图就完成了，对比下1.1中的实现方式，代码精简了许多，同时这里也没有使用自定义的form。

知识点介绍(知识点中涉及的方法和属性，请对照前面统计表中内容，了解方法的继承来源)：

- model：指定了模型：Menu
- fields： 设置为all，将Menu模型所有字段都映射到了ModelForm
- success_url：定义数据添加成功后跳转到的页面
- get_template_names(self)：获取模板信息，如果没有指定template_name，则会根据规则推断出模板为："system/menu_form.html"，其中system来自模型的应用程序名称，menu是Memu模型的名称小写，_form是从template_name_suffix属性中获取的，当然我们也可以通过这个属性指定自己想要的名称，需要注意的是，在创建模板的时候一定要符合这个规则。
- form_class：使用自定义form作为要实例化的form类，使用form_class时候，fields放在form类中定义，不可再放到视图中定义
- get_form_class: 检索要实例化的表单类。 如果提供form_class，那么将使用该类。 否则，将使用与queryset或model关联的模型实例化ModelForm，上面代码中是通过Menu模型实例化的ModelForm

2、打开sandboxMP/apps/system/urls.py，添加新的url配置：

```text
urlpatterns = [
    '''原有内容省略'''
    path('rbac/menu/create/', views_menu.MenuCreateView.as_view(), name='rbac-menu-create'),
]
```

3、模板配置 新建 sandboxMP/templates/system/menu_form.html，内容如下：

```text
{% extends "base-left.html" %}
{% load staticfiles %}

{% block css %}

{% endblock %}

{% block content %}

    <!-- Main content -->
  <section class="content">
    <form action="" method="post">{% csrf_token %}
    {{ form.as_p }}
    <input type="submit" value="Save" />
</form>

  </section>

    <!-- /.content -->

{% endblock %}

{% block javascripts %}

{% endblock %}
```

**知识点介绍：**

- menu_form.html : 第11节中使用ListView的时候，没有定义template_name，视图根据规则自动生成了模板的路径和名称，这里也是同样的用法，按照一定的路径和规则放置和定义模板，通用视图会自动查找模板并进行渲染。
- {{ form.as_p }} : 使用django form进行前端表单数据的渲染（06：知识扩展-Django表单 一节已经介绍过这种用法）。

运行项目，访问菜单添加页面，可以看到，通过Django form已经成功渲染了一个表单，按照图中的内容，添加数据：



![img](C:\Users\yujing\Desktop\yaml\images\v2-72042cbfd8e68c810848237ed2a8672c_1440w.jpg)



系统URL的配置请一定要跟着我的配置，不可随意修改，不然后面渲染导航按钮的时候就会出问题了。
保存数据后，使用navicat连接数据库，可以看到菜单数据已经添加到数据库system_menu表中：

![img](C:\Users\yujing\Desktop\yaml\images\v2-d2a50c9bc8e744e01b9688014116c662_1440w.jpg)



## 1.4 菜单添加功能的优化

现在使用的Django form渲染的添加表单，样式比较丑陋，同时添加数据后还是跳转到添加页面，没有提示信息，接下来我们来优化下。

## 1.4.1 视图的优化

我想数据添加成功后，不是跳转页面，而是将添加成功或失败的结果序列化为Json格式返回，该怎么办呢？
答案是：我们可以重写post()方法，当然，更深入一层，你也可以去重写form_valid()方法。<

```text
import json

from django.views.generic import CreateView
from django.shortcuts import HttpResponse

from .mixin import LoginRequiredMixin
from .models import Menu


class MenuCreateView(LoginRequiredMixin, CreateView):
    model = Menu
    fields = '__all__'

    def post(self, request, *args, **kwargs):
        res = dict(result=False)
        form = self.get_form()
        if form.is_valid():
            form.save()
            res['result'] = True
        return HttpResponse(json.dumps(res), content_type='application/json')
```

这样就完成了视图的修改，我们也可以把重写的post方法单独拿出来，作为扩展的通用类，这样后面项目中所有需要添加数据的视图都可以继承我们自己扩展的通用类。

## 1.4.2 通用视图的扩展

我们把具有共同特性的代码抽象出来，扩展通用视图，达到可复用的目的，回顾项目前面几节，组织架构的添加、用户的添加。在项目中写添加功能的时候我采用了两种模式，一种是根据添加结果返回True或者False，前端根据结果提示 “添加成功”或者“添加失败”，另一种是添加失败时候，返回form表单中的自定义错误信息，后面还会多次使用到添加视图，这里先把共性拿出来扩展通用视图。
新建 sandboxMP/apps/custom.py，扩展的自定义视图都放到这里面，我们先写第一个我们自定义扩展视图：

```text
import json

from django.views.generic import CreateView
from django.shortcuts import HttpResponse

from system.mixin import LoginRequiredMixin


class SimpleInfoCreateView(LoginRequiredMixin, CreateView):

    def post(self, request, *args, **kwargs):
        res = dict(result=False)
        form = self.get_form()
        if form.is_valid():
            form.save()
            res['result'] = True
        return HttpResponse(json.dumps(res), content_type='application/json')
```

删除sandboxMP/apps/system/views_menu.py 里面原有内容，替换成下面内容：

```text
from apps.custom import SimpleInfoCreateView
from .models import Menu


class MenuCreateView(SimpleInfoCreateView):
    model = Menu
    fields = '__all__'
```

是不是很简单了，后面所有的只需要简单返回True或False结果的添加视图，都这么写就OK啦！
上面的视图还需要稍作修饰，Menu模型中有一个外键parent(父菜单)，我们在添加的时候希望能够通过列表来选择父菜单，所有还需要传递额外的上下文，前面已经介绍过了，你是否已经掌握了呢？

```text
from apps.custom import SimpleInfoCreateView
from .models import Menu


class MenuCreateView(SimpleInfoCreateView):
    model = Menu
    fields = '__all__'
    extra_context = dict(menu_all=Menu.objects.all())
```

这就是我们最终菜单管理功能中的添加视图啦。

## 1.4.3 模板的配置

接下来优化我们的模板配置吧，在模板中使用自定义的html form， 同时通过ajax提交数据到添加视图，更具后端返回的状态，提示相应的信息。
打开 sandboxMP/templates/system/menu_form.html，清空原有内容，添加如下内容：

```text
{% extends 'base-layer.html' %}
{% load staticfiles %}
{% block css %}
    <link rel="stylesheet" href="{% static 'plugins/select2/select2.min.css' %}">
    <!-- iCheck for checkboxes and radio inputs -->
{% endblock %}
{% block main %}
    <div class="box box-danger">
        <form class="form-horizontal" id="addForm" method="post">
            {% csrf_token %}
            <div class="box-body">
                <fieldset>
                    <legend>
                        <h4>添加菜单</h4>
                    </legend>
                    <div class="form-group has-feedback">
                        <label class="col-sm-2 control-label">名称</label>
                        <div class="col-sm-3">
                            <input class="form-control" name="name" type="text"/>
                        </div>
                        <label class="col-sm-2 control-label">代码</label>
                        <div class="col-sm-3">
                            <input class="form-control" name="code" type="text"/>
                        </div>
                    </div>
                    <div class="form-group has-feedback">
                        <label class="col-sm-2 control-label">图标</label>
                        <div class="col-sm-3">
                            <input class="form-control" name="icon" type="text" />
                        </div>
                        <label class="col-sm-2 control-label">父菜单</label>
                        <div class="col-sm-3">
                            <select class="form-control select2" name="parent">
                                <option value="{{ menu.parent.id }}">{{ menu.parent.name }}</option>
                                {% for parent_menu in menu_all %}
                                    <option value={{ parent_menu.id }}> {{ parent_menu.name }} </option>
                                {% endfor %}
                            </select>
                        </div>
                    </div>
                    <div class="form-group has-feedback">
                        <label class="col-sm-2 control-label">URL</label>
                        <div class="col-sm-8">
                            <input class="form-control" name="url" type="text" />
                        </div>

                    </div>
                </fieldset>
            </div>
            <div class="box-footer ">
                <div class="row span7 text-center ">
                    <button type="button" id="btnCancel" class="btn btn-default margin-right ">重置</button>
                    <button type="button" id="btnSave" class="btn btn-info margin-right ">保存</button>
                </div>
            </div>

        </form>
    </div>

{% endblock %}

{% block javascripts %}
    <script src="{% static 'plugins/select2/select2.full.min.js' %}"></script>
    <script type="text/javascript">

        $("#btnSave").click(function () {
            var data = $("#addForm").serialize();
            $.ajax({
                type: $("#addForm").attr('method'),
                url: "{% url 'system:rbac-menu-create' %}",
                data: data,
                cache: false,
                success: function (msg) {
                    if (msg.result) {
                        layer.alert('数据保存成功！', {icon: 1}, function (index) {
                            parent.layer.closeAll(); //关闭所有弹窗
                        });
                    } else {
                        layer.alert('数据保存失败', {icon: 5});
                        //$('errorMessage').html(msg.message)
                    }
                    return;
                }
            });
        });


        /*点取消刷新新页面*/
        $("#btnCancel").click(function () {
            window.location.reload();

        });

        $(function () {
            //Initialize Select2 Elements
            $(".select2").select2();
        });

    </script>

{% endblock %}
```

运行项目，访问菜单添加页面：[http://127.0.0.1:8000/system/rbac/menu/create/](https://link.zhihu.com/?target=http%3A//127.0.0.1%3A8000/system/rbac/menu/create/)， 效果如下：



![img](C:\Users\yujing\Desktop\yaml\images\v2-a332aaa36a57b5ae22da9e35d5fcf7be_1440w.jpg)

经过测试，菜单添加共功能可以正常使用，同时会返回提示信息，至此菜单管理中的添加功能已经完成，后面添加页面会被作为弹窗调用





确实没有menu_create.html。看了源代码，你在这里说的，似乎应该是sandboxMP/templates/system/menu_form.html这个文件。还有1.3说的sandboxMP/apps/system/views_create.py这个文件，似乎也应该是view_menu.py这个文件。