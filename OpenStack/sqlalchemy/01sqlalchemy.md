pip install pymysql
pip install sqlalchemy


--modules # 文件夹
  --auth.py
  --db.py

在db.py中，代码如下：

```python
from sqlalchemy import create_engine


HOST_NAME = '127.0.0.1'	# 主机
PORT = '3306'	# 端口号
DB_NAME = '数据库名称，需提前创建好'
USERNAME = '用户名'
PASSWORD = '密码'

DB_URL = 'mysql+pymysql://{}:{}@{}:{}/{}?charset=utf8'.format(
    USERNAME, PASSWORD, HOST_NAME, PORT, DB_NAME
)
engine = create_engine(DB_URL)

if __name__ == '__main__':
    connection = engine.connect()
    result = connection.execute('select 1')
    print(result.fetchone())
```
直接运行这个文件，若结果为(1, )则表示连接数据库成功！！！若不是就检查一下你的配置信息是否填对了

在db.py中，加入如下代码：
```python
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base(engine)
```


在auth.py中，添加如下代码：

```python
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime
from models.db import Base


class User(Base):
    __tablename__ = 'user'	# 数据库中的表名
    id = Column(Integer, primary_key=True, autoincrement=True)	# 主键
    name = Column(String(50), unique=True, nullable=False)
    password = Column(String(50))
    create_time = Column(DateTime, default=datetime.now())

if __name__ == '__main__':
    # 创建表
    Base.metadata.create_all()

```
请注意这里我们不能直接运行auth.py这个文件，不然会报错，解决方法如下：
在项目目录下打开ipython,通过这样来完成表的创建





在之前的章节中的db.py中添加如下代码：

```python
from sqlalchemy.orm import sessionmaker

Session = sessionmaker(bind=engine)
```



### 增

![在这里插入图片描述](D:\文档整理\OpenStack\sqlalchemy\增)



一次性添加多条数据

![在这里插入图片描述](D:\文档整理\OpenStack\sqlalchemy\多个增)

### 查

![在这里插入图片描述](D:\文档整理\OpenStack\sqlalchemy\查)

### 改

![在这里插入图片描述](D:\文档整理\OpenStack\sqlalchemy\改)



### 删

![在这里插入图片描述](D:\文档整理\OpenStack\sqlalchemy\删)