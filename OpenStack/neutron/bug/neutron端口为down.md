neutron端口为down ——创建的虚拟机网络端口down，导致虚拟机起不来

1. 获取token

- 请求方式: POST
- 请求URL: http://10.100.7.50:5000/v3/auth/tokens
- 请求的body格式为 raw,JSON格式
- body具体内容如下:
{
    "auth": {
        "identity": {
            "methods": [
                "password"
            ],
            "password": {
                "user": {
                    "name": "admin",
                    "password": "NmU0OGVmZDIyMTl",
                    "domain": {
                        "name": "default"
                    }
                }
            }
        },
        "scope": {
            "project": {
                "name": "admin",
                "domain": {
                    "name": "default"
                }
            }
        }
    }
}


返回:
Headers中的 【X-Subject-Token】
gAAAAABhlMtk_-KbCSQBiHTmWZubaM2QtuMyjlV9Xav0l2_uC1dC-CHPyg9XxgB-mpo-YUSUWPZ5rBlSlsIi1Wf96NMXHxxXrZTgD6tSx07CtBfXaPTzR9oKCZYxQ1IRJgBgtn5TIb9CoQpC2eHkvg2FCsryKug-TyTZ1HTjWktutozN_5EsFJE

2. 批量创建网络
- 请求方式: POST
- 请求URL: http://10.100.7.50:9696/v2.0/networks
- Headers: X-Auth-Token : gAAAAABhlMtk_-KbCSQBiHTmWZubaM2QtuMyjlV9Xav0l2_uC1dC-CHPyg9XxgB-mpo-YUSUWPZ5rBlSlsIi1Wf96NMXHxxXrZTgD6tSx07CtBfXaPTzR9oKCZYxQ1IRJgBgtn5TIb9CoQpC2eHkvg2FCsryKug-TyTZ1HTjWktutozN_5EsFJE
- 请求的body格式为 raw,JSON格式
- body具体内容如下:
{
    "networks": [
        {
            "admin_state_up": true,
            "name": "t1"
        },
        {
            "admin_state_up": true,
            "name": "t2"
        },
        {
            "admin_state_up": true,
            "name": "t3"
        },
        {
            "admin_state_up": true,
            "name": "t4"
        },
        {
            "admin_state_up": true,
            "name": "t5"
        }
    ]
}


3. 批量创建subnet
- 请求方式: POST
- 请求URL: http://10.100.7.50:9696//v2.0/subnets
- Headers: X-Auth-Token : gAAAAABhlMtk_-KbCSQBiHTmWZubaM2QtuMyjlV9Xav0l2_uC1dC-CHPyg9XxgB-mpo-YUSUWPZ5rBlSlsIi1Wf96NMXHxxXrZTgD6tSx07CtBfXaPTzR9oKCZYxQ1IRJgBgtn5TIb9CoQpC2eHkvg2FCsryKug-TyTZ1HTjWktutozN_5EsFJE
- 请求的body格式为 raw,JSON格式
- body具体内容如下:
{
    "subnets": [
        {
            "cidr": "10.0.1.0/24",
            "ip_version": 4,
            "network_id": "82d65378-31d6-4dac-9f16-29cc4ae49275"
        },
        {
            "cidr": "10.0.2.0/24",
            "ip_version": 4,
            "network_id": "169cfa1d-acde-464a-8990-461693f93103"
        },
        {
            "cidr": "10.0.3.0/24",
            "ip_version": 4,
            "network_id": "10c965bb-7bc9-45f4-833d-202de54266f7"
        },
        {
            "cidr": "10.0.4.0/24",
            "ip_version": 4,
            "network_id": "98c2e352-9cd3-4879-87a6-aeb5ce4c8ae5"
        },
        {
            "cidr": "10.0.5.0/24",
            "ip_version": 4,
            "network_id": "515b1960-204e-48d6-a0f9-139019e93e73"
        }
    ]
}

4. 查询List