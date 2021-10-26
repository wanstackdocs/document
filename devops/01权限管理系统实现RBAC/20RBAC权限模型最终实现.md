前面章节已经完成了权限三元组（用户、角色、菜单）的功能实现，本节将会完成权限数据的配置、权限验证、导航菜单的生成和其他优化配置。

## 1、权限三元组初始化数据配置

权限三元组（用户、角色、菜单）初始数据是保障系统权限管理功能正常运行的基础数据，无论是将系统部署上线，还是对系统进行扩展移植，都应该保障三元组初始数据的完整性。

## 1.1 删除三元组中的测试数据

测试数据的删除有两种方法，第一种是删除三元组和关联三元组的数据表中数据
使用Navicat连接数据库文件（第5节已介绍过Navicat的使用），依次删除下列表中数据： - 删除system_userprofile_roles 表中所有测试数据 - 删除system_userprofile 表中除admin以外的用户数据 - 删除system_role_permissions 表中所有数据 - 删除system_role 表中所有数据 - 删除system_menu 表中所有数据

第二种方法是使用Navicat连接数据库，删除数据库中所有表，重新migrate，然后使用python manage.py createsuperuser创建admin用户。
我使用的是第二种方法，因为我需要保持权限数据初始数据的干净，同时还要给菜单模型新增加一个字段，详细操作方法如下： - 使用Navicat连接数据库文件，删除数据库中所有表，因为表中的关联关系，删除时会报错，多删几遍。(使用sqlite数据库的，sqlite_sequence表不用删除) - 打开sandboxMP/apps/system/models.py文件，在Menu模型中添加一个新的字段number:

```python
number = models.FloatField(null=True, blank=True, verbose_name="编号")
```

- 打开sandboxMP/apps/system/models.py，修改Menu模下的Meta和get_menu_by_request_url

```python
class Meta:
    verbose_name = '菜单'
    verbose_name_plural = verbose_name
    ordering = ['number']  

@classmethod
def get_menu_by_request_url(cls, url):
    try:
        return dict(menu=Menu.objects.get(url=url))
    except:
        return None
```

- 在pycharm中打开【Tools】→【Run manage.py Task...】，在manage.py窗口中运行：makemigrations 和migrate
- 接着在manage.py窗口运行createsuperuser创建admin用户

## 1.2 菜单管理模板修改

菜单模型中新增加了一个number字段，我们需要在添加和修改的时候可以操作该字段。
打开sandboxMP/templates/system/menu_form.html， 根据下面备注替换内容：

```html
<!-- 替换说明：以下内容用来替换form标签下的原有的<div class="box-body">内容，一直到<div class="box-footer"> -->
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
            <label class="col-sm-2 control-label">编号</label>
            <div class="col-sm-3">
                <input class="form-control" name="number" type="text"/>
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
        <div class="form-group has-feedback">
            <label class="col-sm-2 control-label">代码</label>
            <div class="col-sm-8">
                <input class="form-control" name="code" type="text"/>
            </div>
        </div>
    </fieldset>
</div>
```

打开sandboxMP/templates/system/menu_update.html， 根据下面备注替换内容：

```html
<!-- 替换说明：以下内容用来替换form标签下的原有的<div class="box-body">内容，一直到<div class="box-footer"> -->
<div class="box-body">
    <fieldset>
        <legend>
            <h4>修改菜单</h4>
        </legend>
        <div class="form-group has-feedback">
            <label class="col-sm-2 control-label">名称</label>
            <div class="col-sm-3">
                <input class="form-control" name="name" type="text" value="{{ menu.name }}"/>
            </div>
            <label class="col-sm-2 control-label">编号</label>
            <div class="col-sm-3">
                <input class="form-control" name="number" type="text" value="{{ menu.number }}"/>
            </div>
        </div>
        <div class="form-group has-feedback">
            <label class="col-sm-2 control-label">图标</label>
            <div class="col-sm-3">
                <input class="form-control" name="icon" type="text" value="{{ menu.icon | default:'' }}"/>
            </div>
            <label class="col-sm-2 control-label">父菜单</label>
            <div class="col-sm-3">
                <select class="form-control select2" name="parent">
                    <option value="{{ menu.parent.id }}">{{ menu.parent.name }}</option>
                    <option value=""> </option>
                    {% for parent_menu in menu_all %}
                        <option value={{ parent_menu.id }}> {{ parent_menu.name }} </option>
                    {% endfor %}
                </select>
            </div>
        </div>
        <div class="form-group has-feedback">
            <label class="col-sm-2 control-label">URL</label>
            <div class="col-sm-8">
                <input class="form-control" name="url" type="text" value="{{ menu.url | default:'' }}"/>
            </div>
        </div>
        <div class="form-group has-feedback">
            <label class="col-sm-2 control-label">代码</label>
            <div class="col-sm-8">
                <input class="form-control" name="code" type="text" value="{{ menu.code | default:'' }}"/>
            </div>
        </div>
    </fieldset>
</div>
```

## 1.3 修改菜单管理的视图

打开sandboxMP/apps/system/views_menu.py， 删除MenuCreateView和MenuUpdateView中的extra_context，改成通过get_context_data来添加额外的上下文：

```python
class MenuCreateView(SandboxCreateView):
    model = Menu
    fields = '__all__'

    def get_context_data(self, **kwargs):
        kwargs['menu_all'] = Menu.objects.all()
        return super().get_context_data(**kwargs)

'''中间内容省略'''


class MenuUpdateView(SandboxUpdateView):
    model = Menu
    fields = '__all__'
    template_name_suffix = '_update'

    def get_context_data(self, **kwargs):
        kwargs['menu_all'] = Menu.objects.all()
        return super().get_context_data(**kwargs)
```

## 1.4 完善admin用户信息

使用Navicat工具连接数据库，打开system_userprofile表，修改刚刚创建的admin用户，在name字段输入'管理员'，mobile字段添加手机号码'13800000000' 手机号随便满足11位数，最后点击Navicat 左下角的对号，保存修改。

## 1.5 添加URL数据

为了实现基于角色组权限的访问控制和动态导航生成，项目中所有的URL数据都是录入数据库的，除了权限管理包含的三元组的访问URL之外，项目中每次新增应用，都需要将URL录入数据库，并绑定授权访问的角色组。

## 1.5.1 URL数据录入规范

看图说话：



![img](D:\文档整理\devops\01权限管理系统实现RBAC\images\v2-823bb60aca4bc2a22806642346914e1d_1440w.jpg)

在项目中URL的定义是遵循一定规范的，具体规范如下：
**1、一级菜单：** 使用 app名称来命名的，看下sandboxMP/sandboxMP/urls.py中配置：

```python
path('system/', include('system.urls', namespace='system')),
```

**2、二级菜单：** 是在具体app应用的urls.py中配置，通过include导入一级菜单定义的URLconf文件，二级菜单可以是一个功能URL也可以是一个分组，项目中把菜单管理和角色管理两个功能划分到一个分组rbac ，看下sandboxMP/apps/system/urls.py中配置：

```python
path('rbac/menu/', views_menu.MenuListView.as_view(), name='rbac-menu'),
path('rbac/role/', views_role.RoleView.as_view(), name='rbac-role'),
```

菜单管理和角色管理两个功能都划分到rbac分组，rbac就是我们的二级菜单，它在导航栏中是一个折叠菜单，录入数据库时URL字段是空的。二级菜单通过外键绑定到一级菜单

**3、三级菜单：** 三级菜单是具体的功能菜单，通过三级菜单可以跳转到具体功能页面。三级菜单通过外键关联到二级菜单，注意：如果功能菜单直接关联到一级菜单，它将直接在左侧导航栏显示，不再属于任何折叠的菜单分组。当二级菜单是一个功能菜单，而不是分组时，录入系统时需要配置功能菜单的访问URL。

**4、四级菜单：** 具体的功能操作菜单，它属于某一个功能菜单，例如下面角色创建，列表，更新，和删除这些菜单都属于角色管理：

```python
path('rbac/role/create/', views_role.RoleCreateView.as_view(), name='rbac-role-create'),
path('rbac/role/list/', views_role.RoleListView.as_view(), name='rbac-role-list'),
path('rbac/role/update/', views_role.RoleUpdateView.as_view(), name='rbac-role-update'),
path('rbac/role/delete/', views_role.RoleDeleteView.as_view(), name='rbac-role-delete'),
```

功能操作菜单通过外键关联到功能菜单，当功能菜单被定义为二级菜单时，该功能菜单下对应的操作菜单就是三级。

**5、菜单编号：** 用来作为菜单排序使用 
- 一级菜单编号为1，2，3，4等，例如系统管理编号为1，工程项目编号为2 
- 二级菜单编号以一级菜单编号开头，例如基础设置编号为1.1， 权限管理编号为1.2 
- 三级菜单编号以二级菜单编号开头，例如菜单管理编号为1.21， 角色管理编号为1.22 
- 四级菜单编号以三级菜单编号开头，例如菜单管理中的添加功能编号为1.211 ，修改功能编号为1.212

**6、菜单图标：** 导航上菜单显示的图标
只有二级菜单才会定义图标，图标使用的是Font Awesome图标库，具体图标案例可访问官方网站查询：

```text
http://fontawesome.dashgame.com/
```

**7、菜单名称：** 用来标识菜单具体作用，角色绑定时菜单树形结构显示的具体名称。
**8、父菜单：** 定义菜单层级关系，输入菜单时一定不要搞错层级。
**9、菜单编码:** 前端通过菜单编码来给当前访问的菜单添加激活的高亮样式

## 1.5.2 录入菜单数据

我对当前系统已经存在的菜单做了下统计，请根据统计内容，访问菜单管理页面，将以下菜单内容添加到数据库(注意不要有空格)：

```text
http://127.0.0.1:8000/system/rbac/menu/
```

看到这么多菜单需要添加，不要慌，我都添加好了，你只需要在github上本节对应的代码中找到db.sqlite3下载下来，替换你项目中的db.sqlite3即可，下载地址：

```text
# 访问下面连接，选择Download按钮，下载已经输入菜单db.sqlite3
https://github.com/RobbieHan/sandboxMP/blob/v1.18/db.sqlite3
```

![img](D:\文档整理\devops\01权限管理系统实现RBAC\images\v2-a7a9ccf15e65c6cc102262ceddbbd5c9_1440w.jpg)

![img](D:\文档整理\devops\01权限管理系统实现RBAC\images\v2-bc99b2bd777c0a2fdc1c7b8ac23ac221_1440w.jpg)

URL添加需要注意的地方: 明确层级划分的菜单，父菜单关联关系不要出错；如果功能访问没有问题，但是通过菜单渲染的导航使用有问题，检查菜单录入的是否正确。
新增加app的时候按照以上规范添加到数据库中。

## 2 根据角色组权限生成导航菜单

菜单的生成和权限的验证时通过中间件middleware来完成的，有关中间件的内容，文档中没有专门介绍，有兴趣的可以去查阅官方文档，下面两个博文也做了细致介绍：

```text
https://www.cnblogs.com/forsaken627/p/8550826.html
https://www.cnblogs.com/felo/p/5600549.html
```

## 2.1 创建角色组和用户

1、在用户管理里面添加几个测试用户：

```text
http://127.0.0.1:8000/system/basic/user/
```

2、在角色管理里面添加几个不同的角色，并将给角色绑定不同菜单权限，同时关联用户

```text
http://127.0.0.1:8000/system/rbac/role/
```

如果你是从github上下载本节对应的数据库文件的话，里面已经创建好了用户和角色，关系如下：

用户 | 密码 | 角色 | 权限

---|---|---|---|

admin | !qaz@wsx | 系统管理员 | 全部权限

zhenglu | 000000 | 用户管理员 | 用户管理和组织架构管理

当然，你也可以创建更多的用户，划分更多的角色，然后给没给角色分配不同的权限，一个用户可以绑定多个角色，继承它们全部权限。

## 2.2 根据角色生成导航菜单

## 2.2.1 自定义middleware

项目中已经创建了28个URL，同时所有菜单信息已经全部录入到数据库，前面一直都是通过手动指定要访问的URL来访问系统，接下来就来实现导航菜单的生成。
新建sandboxMP/apps/system/middleware.py ，内容如下：

```python
import re

from django.utils.deprecation import MiddlewareMixin


class MenuCollection(MiddlewareMixin):

    def get_user(self, request):
        return request.user
    # 注释1：
    def get_menu_from_role(self, request, user=None):
        if user is None:
            user = self.get_user(request)
        try:
            menus = user.roles.values(
                'permissions__id',
                'permissions__name',
                'permissions__url',
                'permissions__icon',
                'permissions__code',
                'permissions__parent'
            ).distinct()
            return [menu for menu in menus if menu['permissions__id'] is not None]
        except AttributeError:
            return None
    # 注释2：
    def get_permission_url(self, request):
        role_menus = self.get_menu_from_role(request)
        if role_menus is not None:
            permission_url_list = [menu['permissions__url'] for menu in role_menus]
            return permission_url_list
    #注释3：
    def get_permission_menu(self, request):
        permission_menu_list = []
        role_menus = self.get_menu_from_role(request)
        if role_menus is not None:
            for item in role_menus:
                menu = {
                    'id': item['permissions__id'],
                    'name': item['permissions__name'],
                    'url': item['permissions__url'],
                    'icon': item['permissions__icon'],
                    'code': item['permissions__code'],
                    'parent': item['permissions__parent'],
                    'status': False,
                    'sub_menu': [],
                }
                permission_menu_list.append(menu)
            return permission_menu_list
    # 注释4：
    def get_top_reveal_menu(self, request):
        top_menu = []
        permission_menu_dict = {}
        request_url = request.path_info
        permission_menu_list = self.get_permission_menu(request)
        if permission_menu_list is not None:
            for menu in permission_menu_list:

                url = menu['url']
                if url and re.match(url, request_url):
                    menu['status'] = True
                if menu['parent'] is None:
                    top_menu.insert(0, menu)
                permission_menu_dict[menu['id']] = menu

            menu_data = []
            for i in permission_menu_dict:
                if permission_menu_dict[i]['parent']:
                    pid = permission_menu_dict[i]['parent']
                    parent_menu = permission_menu_dict[pid]
                    parent_menu['sub_menu'].append(permission_menu_dict[i])
                else:
                    menu_data.append(permission_menu_dict[i])
            if [menu['sub_menu'] for menu in menu_data if menu['url'] in request_url]:
                reveal_menu = [menu['sub_menu'] for menu in menu_data if menu['url'] in request_url][0]
            else:
                reveal_menu = None
            return top_menu, reveal_menu
    # 注释5：
    def process_request(self, request):

        if self.get_top_reveal_menu(request):
            request.top_menu, request.reveal_menu = self.get_top_reveal_menu(request)
            request.permission_url_list = self.get_permission_url(request)
```

上面代码主要实现了从登陆用户角色组中获取菜单数据，然后对菜单进行组合排列，提取出头部（一级菜单），侧边栏菜单和角色组中的URL数据。这段代码逻辑有些乱，如果有好的实现方法，朋友们可以进行优化下。

> **注释1：** 从request中获取用户信息，获取用户角色组绑定的菜单信息，其中distinct()是用来去重，因为用户可继承多个角色组权限，有可能多个角色组都绑定了同一个菜单。后面的列表推到式是用来排除空角色组的菜单信息。如果用户没有登陆，则返回None，最终获取的数据格式是一个包含菜单字典的列表：
> [{'permissions**id': 1, 'permissions**name': '系统管理', 'permissions**url': '/system/', 'permissions**icon': None, 'permissions**code': 'SYSTEM', 'permissions**parent': None}, ...]。
> **注释2：** 从1中获取的列表中提取出url生成一个新的列表，这个列表中是从用户角色中获取的所有URL，用来比对用户访问的URL是否在这个列表中。获取的内容如下：
> ['/system/', None, '/system/basic/structure/', '/system/basic/structure/list', '/system/basic/structure/create', '/system/basic/structure/delete', ...]
> **注释3：** 对1中获取的列表重新组合，替换原有键的名称，换成和数据库中对应的字段名称，同时添加了两个新的键值对: status用来标识头部一级菜单的选中状态，默认False；sub_menu默认是一个列表，用来存放下级菜单数据。
> **注释4：** 获取头部导航和侧边栏导航数据，更具层级进行组合，最后返回数据格式如下：
> ([{'id': 1, 'name': '系统管理', 'url': '/system/', 'icon': None, 'code': 'SYSTEM', 'parent': None, 'status': True, 'sub_menu': [{'id': 2, 'name': '基础设置', 'url': None, 'icon': 'fa fa-gg', 'code': 'SYSTEM-BASIC', 'parent': 1, 'status': False, 'sub_menu': [{'id': 3, 'name': '组织架构', 'url': '/system/basic/structure/', 'icon': None, 'code': 'SYSTEM-BASIC-STRUCTURE', 'parent': 2, 'status': False, 'sub_menu': [{'id': 4, 'name': '组织架构：列表', 'url': '/system/basic/structure/list', 'icon': None, 'code': 'SYSTEM-BASIC-STRUCTURE-LIST', 'parent': 3, 'status': False, 'sub_menu': []}, {'id': 5, 'name': '组织架构：创建', 'url': '/system/basic/structure/create', 'icon': None, 'code': 'SYSTEM-BASIC-STRUCTURE-CREATE', 'parent': 3, 'status': False, 'sub_menu': []}, {'id': 6, 'name': '组织架构：删除', 'url': '/system/basic/structure/delete', 'icon': None, 'code': 'SYSTEM-BASIC-STRUCTURE-DELETE', 'parent': 3, 'status': False, 'sub_menu': []}, {'id': 7, 'name': '组织架构：关联用户', 'url': '/system/basic/structure/add_user', 'icon': None, 'code': 'SYSTEM-BASIC-STRUCTURE-ADD_USER', 'parent': 3, 'status': False, 'sub_menu': []}]}, }])
> **注释5：** process_request()是在将request请求传递给view前执行，所有在这里我们把整理组合好的菜单数据写入request。

## 2.2.2 使用自定义middleware

修改sandboxMP/sandboxMP/settings.py，在MIDDLEWARE配置项最后一行添加如下内容：

```python
MIDDLEWARE = [
    '''原有内容省略'''
    'apps.system.middleware.MenuCollection',
]
```

## 2.2.3 导航模板配置

配置模板将菜单数据渲染到导航栏
打开sandboxMP/templates/head-footer.html，按照备注修改：

```html
# 删除 <div class="collapse navbar-collapse pull-left" ...> 标签下的<ul ...></ul>内容，替换成下面内容
{% for menu in request.top_menu %}
    <ul class="nav navbar-nav">
        <li {% ifequal menu.status True %}class="active" {% endifequal %}>
            <a href="{{ menu.url }}" id="{{ menu.code }}">{{ menu.name | default_if_none:"" }}</a>
        </li>
    </ul>
{% endfor %}
```

打开sandboxMP/templates/base-left.html，按照备注修改：

```html
# 删除 <li class="header"></li>到 </ul>标签之间的内容，替换成下面内容
 {% for menu in request.reveal_menu %}
    {% if not menu.url %} 
    <!--如果菜单没有url则这个二级菜单是一个菜单组，样式设置为treeview-->
        <li class="treeview" id="{{ menu.code }}">
            <a href="">
                <i class="{{ menu.icon }}"></i><span>{{ menu.name }}</span>
                <span class="pull-right-container"><i class="fa fa-angle-left pull-right"></i>
                </span>
            </a>
            <ul class="treeview-menu">
                {% for sub in  menu.sub_menu %}
                <!--获取二级菜单的子菜单，作为折叠组中的三级菜单 -->
                    <li id="{{ sub.code }}">
                        <a href="{{ sub.url }}"><i class="fa fa-caret-right"></i>{{ sub.name }}</a>
                    </li>
                {% endfor %}
            </ul>
        </li>
    {% else %}
    <!-- 如果二级菜单有URL，则这是一个功能菜单，直接作为导航菜单，不再添加折叠样式 -->
        <li id="{{ menu.code }}">
            <a href="{{ menu.url }}"><i class="{{ menu.icon }}"></i><span>{{ menu.name }}</span>
            </a>
        </li>
    {% endif %}
{% endfor %}
```

## 2.2.4 导航的展开和高亮

在项目中一共创建了四个功能页面：组织架构管理、用户管理、菜单管理、角色管理，我们想在选中不同导航时可以展开折叠菜单和当前导航高亮显示。
sandboxMP/templates/system/menu_list.html 中在{% block javascripts %} 下已经添加了菜单展开好高亮的配置，内容如下：

```js
<script type="text/javascript">
    $(function () {
        $('#SYSTEM-RBAC').addClass('active');
        $('#SYSTEM-RBAC-MENU').addClass('active');
    });
</script>
```

接下来需要在其它三个功能页添加相同配置，具体添加位置参照menu_list.html。
在sandboxMP/templates/system/structure/structure.html 中{% block javascripts %} 标签下添加如下内容：

```js
<script type="text/javascript">
    $(function () {
        $('#SYSTEM-BASIC').addClass('active');
        $('#SYSTEM-BASIC-STRUCTURE').addClass('active');
    });
</script>
```

在sandboxMP/templates/system/users/user.html 中{% block javascripts %} 标签下添加如下内容：

```js
<script type="text/javascript">
    $(function () {
        $('#SYSTEM-BASIC').addClass('active');
        $('#SYSTEM-BASIC-USER').addClass('active');
    });
</script>
```

在sandboxMP/templates/system/role.html 中{% block javascripts %} 标签下添加如下内容：

```js
<script type="text/javascript">
    $(function () {
        $('#SYSTEM-RBAC').addClass('active');
        $('#SYSTEM-RBAC-ROLE').addClass('active');
    });
</script>
```

运行系统，使用上面给出的两个不同权限的用户分别登陆系统，点击头部的【系统】导航，进入系统模块，你将会看到不同的导航栏信息。
现在已经可以根据用户角色组权限生成导航菜单，但是我们还没有做访问权限验证，也就是说虽然登陆的用户看不到自己角色组中没有的URL导航信息，但是他可以直接访问对应的URL。

## 3 用户权限的验证

## 3.1 配置URL白名单

URL白名单的作用是针对系统中不适合做权限验证的一些访问URL，例如媒体文件的访问，每次上传文件URL都是不固定的，还有登陆、登出的URL，下面定义的所有URL白名单请务必不要改动。
将下面内容添加到sandboxMP/sandboxMP/settings.py中：

```python
# safe url
SAFE_URL = [r'^/$',
            '/login/',
            '/logout',
            '/index/',
            '/media/',
            '/admin/',
            '/ckeditor/',
            ]
```

## 3.2 RbacMiddleware

打开sandboxMP/apps/system/middleware.py ，添加如下内容：

```python
import re

from django.utils.deprecation import MiddlewareMixin
from django.conf import settings
from django.shortcuts import render


class RbacMiddleware(MiddlewareMixin):

    def process_request(self, request):
        if hasattr(request, 'permission_url_list'):
            request_url = request.path_info
            permission_url = request.permission_url_list
            for url in settings.SAFE_URL:
                if re.match(url, request_url):
                    return None
            if request_url in permission_url:
                return None
            else:
                return render(request, 'page404.html')
```

通过上面代码检验用户访问的URL， 如果URL在白名单或者在permission_url中返回None，如果不在则跳返回404页面

打开sandboxMP/sandboxMP/settings.py文件，在MIDDLEWARE最后一行添加如下内容：

```python
MIDDLEWARE = [
    '''原有内容省略'''
    'apps.system.middleware.RbacMiddleware',
    ]
```

运行系统，不同用户登陆后只能看到自己权限范围内的导航菜单，如果通过URL访问非授权数据，则会转到404页面。

**到这里完整的权限管理功能便实现了，如果你需要在原有app（system）基础上添加新的功能，参考权限管理三元组功能的实现和URL的配置，最后把URL添加到菜单管理中，并且绑定角色授权给需要使用的用户，注意一定要遵循菜单管理中URL层级关系，和添加规范。增加一个新的应用就和开始创建system应用方法一样**