# QOS不稳定链路V版支持

[toc]

---

## 一. 靶场功能

实现：

- 上行带宽(kbps)
- 下行带宽(kbps)
- 延迟率
- 丢包率

## 二. 具体实现

### 2.1 下行带宽

下行带宽是指从外部流向虚拟机的网络报文能够达到的带宽。单位为kbps，范围为0~10000000（10Gbps）。下行带宽限制是由OVS支持的，作用在虚拟机与OVS交换机相连的接口上。以上行带宽1000（1Mbps）为例，指令如下：

```
ovs-vsctl set interface tap10699894-53 ingress_policing_rate=1000
ovs-vsctl set interface tap10699894-53 ingress_policing_burst=100
```

`ingress_policing_rate`：为接口最大收包速率，单位kbps，超过该速度的报文将被丢弃，默认值为0表示关闭该功能；
`ingress_policing_burst`：为最大突发流量大小，单位kb。默认值0表示1000kb，这个参数最小值应不小于接口的MTU，通常设置为`ingress_policing_rate`的10%更有利于tcp实现全速率；

查看配置：

```
ovs-vsctl list interface tap10699894-53
```

`注： neutron qos 原生已经实现`

### 2.2 上行带宽

上行带宽是指从虚拟机向外发出网络报文能够达到的带宽。单位为kbps，范围为0~10000000（10Gbps）。上行带宽限制的实现原理同下行带宽。


### 2.3 延迟

延迟是指网络报文从虚拟机发出之后，被延迟发送到下一个目标设备的时间。单位是毫秒，范围是0～60000（60秒）。延迟采用tc工具实现，作用在虚拟机网卡上。以延迟1秒为例，指令如下：

```
tc qdisc add dev tap10699894-53 root netem delay 1000ms 0ms
```

将 tap10699894-53 网卡的传输设置为延迟 1000 毫秒发送 后面的0ms表示1000ms ± 0ms

由于tc工具只能控制发包方向，而无法控制收包方向，因此目前只能做到延迟发送，而不能延迟接收。

### 2.4 丢包率

丢包率指网络报文从虚拟机发出之后，被丢弃而未送达下一个目标设备的比率。单位是%，范围是0～100。需要注意的是，由于算法实现精度问题，实际测得丢包率与指定的丢包率存在一定偏差。丢包率采用tc工具实现，作用在虚拟机网卡上。以丢包50%为例，指令如下：

```
tc qdisc add dev tap10699894-53 root netem loss random 50
```

命令将 tap10699894-53 网卡的传输设置为随机丢掉 50% 的数据包

同样由于tc工具只能控制发包方向，而无法控制收包方向，因此目前只能在虚拟机发出网络报文时丢包，而不能在接收网络报文时丢包。

## 三. 接口设计

### 3.1 delay

#### 3.1.1 qos-delay-rule-create

1.接口参数

| 参数名称               | 参数类型 | 参数说明       |
| ---------------------- | -------- | -------------- |
| --delay-ms             | int      | 延迟毫秒数     |
| --delay-correlation-ms | int      | 延迟抖动毫秒数 |

2.接口调用示例

请求URL:
`http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/delay_rules`

> 其中 `06e2c82b-0024-44d5-931b-221a8be3c3da`是policy的id，可以通过`neutron qos-policy-list` 进行查看

方法: `POST`

参数: 

```
{
    "delay_rule": {"delay_ms": 100, "delay_correlation_ms": 10}
}
```


返回值

```
{
    "delay_rule": {
        "delay_ms": 100,
        "delay_correlation_ms": 10,
        "id": "0783f59b-fbde-407b-86b2-81a74bb28b27"
    }
}
```


返回值字段说明

> delay_ms: 延迟毫秒数  1s=1000ms

> delay_correlation_ms: 延迟抖动毫秒数

> id: delay_rule 资源ID

#### 3.1.2 qos-delay-rule-delete

1.接口参数

无

2.接口示例

请求URL:
`http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/delay_rules/0783f59b-fbde-407b-86b2-81a74bb28b27`

> 06e2c82b-0024-44d5-931b-221a8be3c3da 是policy的id

> 0783f59b-fbde-407b-86b2-81a74bb28b27是delay-rule的id

方法: DELETE

参数: 无

返回值：
无

返回值字段说明

无

#### 3.1.3 qos-delay-rule-list

1.接口参数

无

2.请求示例

请求URL:
`http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/delay_rules`

方法: `GET`

参数: 无

返回值:

```
{
    "delay_rules": [
        {
            "delay_ms": 100,
            "delay_correlation_ms": 10,
            "id": "e42a4c3f-0d08-4286-947a-4b8052a36944"
        }
    ]
}
```

返回值字段说明:
参考3.1.1


#### 3.1.4 qos-delay-rule-show

1. 请求参数
   无

2. 请求示例
   请求URL:
   `http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/delay_rules/e42a4c3f-0d08-4286-947a-4b8052a36944`

> 其中e42a4c3f-0d08-4286-947a-4b8052a36944是delay-rule的id

请求方法: GET

请求参数:无

返回值：

```
{
    "delay_rule": {
        "delay_ms": 100,
        "delay_correlation_ms": 10,
        "id": "e42a4c3f-0d08-4286-947a-4b8052a36944"
    }
}
```

返回值字段说明：
参考3.1.1

#### 3.1.5 qos-delay-rule-update

1.请求参数


2.请求示例

请求URL:
`http://controller:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/delay_rules/e42a4c3f-0d08-4286-947a-4b8052a36944`

请求方法: PUT

请求参数:

```
{
    "delay_rule": {"delay_ms": 101, "delay_correlation_ms": 20}
}
```

返回值:

```
{
    "delay_rule": {
        "delay_ms": 101,
        "delay_correlation_ms": 20,
        "id": "e42a4c3f-0d08-4286-947a-4b8052a36944"
    }
}
```

返回值字段说明:
参考3.1.1

### 3.2 loss

#### 3.2.1 qos-loss-rule-create

1.请求参数


| 字段名称 | 字段类型 | 字段说明 |
| -------- | -------- | -------- |
| loss_pct | int      | 丢包率   |




2.请求示例

请求URL:
`http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/loss_rules`

> 06e2c82b-0024-44d5-931b-221a8be3c3da是policy的id, 通过 neutron qos-polily-list 可以查看

请求方法: POST

请求参数:

```
{"loss_rule": {"loss_pct": 10}}
```

> loss_pct: 是丢包率百分比，10表示丢包率为%10

返回值:

```
{
    "loss_rule": {
        "loss_pct": 10,
        "id": "6f2391df-735d-4fe5-b9b2-350652b062b0"
    }
}
```

返回值字段说明:

> loss_pct: 丢包率百分比

> id: 资源id

#### 3.2.2 qos-loss-rule-delete

1.请求参数
无
2.请求示例

请求URL:
`http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/loss_rules/6f2391df-735d-4fe5-b9b2-350652b062b0`

请求方法: DELETE

请求参数: 无

返回值: 无

#### 3.2.3 qos-loss-rule-list

1.请求参数
无
2.请求示例

请求URL:
`http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/loss_rules`

请求方法：GET

返回值：

```
{
    "loss_rules": [
        {
            "loss_pct": 10,
            "id": "74d8b202-77fb-4996-8a87-8c494769b759"
        }
    ]
}
```

返回值字段说明: 参考3.2.1

#### 3.2.4 qos-loss-rule-show

1.请求参数
无

2.请求示例

请求URL:
`http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/loss_rules/74d8b202-77fb-4996-8a87-8c494769b759`

方法: GET

返回值：

```
{
    "loss_rule": {
        "loss_pct": 10,
        "id": "74d8b202-77fb-4996-8a87-8c494769b759"
    }
}
```

返回值字段说明: 参考3.2.1

#### 3.2.5 qos-loss-rule-update

1.请求参数

```
{"loss_rule": {"loss_pct": 14}}
```

2.请求示例

请求URL:
`http://10.100.7.200:9696/v2.0/qos/policies/06e2c82b-0024-44d5-931b-221a8be3c3da/loss_rules/74d8b202-77fb-4996-8a87-8c494769b759`

请求参数：

```
{"loss_rule": {"loss_pct": 14}}
```

返回值：

```
{
    "loss_rule": {
        "loss_pct": 14,
        "id": "74d8b202-77fb-4996-8a87-8c494769b759"
    }
}
```

返回值字段说明: 参考3.2.1

## 四. 开发步骤

### 4.1 neutron代码修改

定义表结构

```
# neutron/db/qos/models.py
# new add qos
class QosLossRule(model_base.HasId, model_base.BASEV2):
    __tablename__ = 'qos_loss'
    qos_policy_id = sa.Column(sa.String(36),
                              sa.ForeignKey('qos_policies.id',
                                            ondelete='CASCADE'),
                              nullable=False,
                              unique=True)
    loss_pct = sa.Column(sa.Integer)
    revises_on_change = ('qos_policy',)
    qos_policy = sa.orm.relationship(QosPolicy, load_on_pending=True)


class QosDelayRule(model_base.HasId, model_base.BASEV2):
    __tablename__ = 'qos_delay'
    qos_policy_id = sa.Column(sa.String(36),
                              sa.ForeignKey('qos_policies.id',
                                            ondelete='CASCADE'),
                              nullable=False,
                              unique=True)
    delay_ms = sa.Column(sa.Integer)
    delay_correlation_ms = sa.Column(sa.Integer)
    revises_on_change = ('qos_policy',)
    qos_policy = sa.orm.relationship(QosPolicy, load_on_pending=True)

# new end qos
```

定义数据库操作

```
neutron/objects/qos/rule.py
# new add qos
@base.NeutronObjectRegistry.register
class QosLossRule(QosRule):

    db_model = qos_db_model.QosLossRule

    fields = {
        'loss_pct': obj_fields.IntegerField(nullable=False)
    }

    rule_type = qos_consts.RULE_TYPE_LOSS


@base.NeutronObjectRegistry.register
class QosDelayRule(QosRule):

    db_model = qos_db_model.QosDelayRule

    fields = {
        'delay_ms': obj_fields.IntegerField(nullable=False),
        'delay_correlation_ms': obj_fields.IntegerField(nullable=False),
    }

    rule_type = qos_consts.RULE_TYPE_DELAY
# new end qos
```

定义API

```
neutron/extensions/qos.py
class QoSPluginBase(service_base.ServicePluginBase, metaclass=abc.ABCMeta):

    path_prefix = apidef.API_PREFIX

    # The rule object type to use for each incoming rule-related request.
    rule_objects = {'bandwidth_limit': rule_object.QosBandwidthLimitRule,
                    'dscp_marking': rule_object.QosDscpMarkingRule,
                    # new add qos
                    'loss': rule_object.QosLossRule,
                    'delay': rule_object.QosDelayRule,
                    # new end qos
                    'minimum_bandwidth': rule_object.QosMinimumBandwidthRule}
```

定义plugins

```
# neutron/plugins/ml2/drivers/openvswitch/agent/extension_drivers/qos_driver.py

# Copyright (c) 2015 OpenStack Foundation
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

import collections

from neutron_lib import constants
from neutron_lib.services.qos import constants as qos_consts
from oslo_config import cfg
from oslo_log import log as logging

from neutron.agent.l2.extensions import qos_linux as qos
from neutron.services.qos.drivers.openvswitch import driver
# new add qos
from neutron.agent.common.utils import execute
# new end qos
LOG = logging.getLogger(__name__)


class QosOVSAgentDriver(qos.QosLinuxAgentDriver):

    SUPPORTED_RULES = driver.SUPPORTED_RULES

    def __init__(self):
        super(QosOVSAgentDriver, self).__init__()
        self.br_int_name = cfg.CONF.OVS.integration_bridge
        self.br_int = None
        self.agent_api = None
        self.ports = collections.defaultdict(dict)

    def consume_api(self, agent_api):
        self.agent_api = agent_api

    def _minimum_bandwidth_initialize(self):
        """Clear QoS setting at agent restart.

        This is for clearing stale settings (such as ports and QoS tables
        deleted while the agent is down). The current implementation
        can not find stale settings. The solution is to clear everything and
        rebuild. There is no performance impact however the QoS feature will
        be down until the QoS rules are rebuilt.
        """
        self.br_int.clear_minimum_bandwidth_qos()

    def initialize(self):
        self.br_int = self.agent_api.request_int_br()
        self.cookie = self.br_int.default_cookie
        self._minimum_bandwidth_initialize()

    def create_bandwidth_limit(self, port, rule):
        self.update_bandwidth_limit(port, rule)

    def update_bandwidth_limit(self, port, rule):
        vif_port = port.get('vif_port')
        if not vif_port:
            port_id = port.get('port_id')
            LOG.debug("update_bandwidth_limit was received for port %s but "
                      "vif_port was not found. It seems that port is already "
                      "deleted", port_id)
            return
        self.ports[port['port_id']][(qos_consts.RULE_TYPE_BANDWIDTH_LIMIT,
                                     rule.direction)] = port
        if rule.direction == constants.INGRESS_DIRECTION:
            self._update_ingress_bandwidth_limit(vif_port, rule)
        else:
            self._update_egress_bandwidth_limit(vif_port, rule)

    def delete_bandwidth_limit(self, port):
        port_id = port.get('port_id')
        vif_port = port.get('vif_port')
        port = self.ports[port_id].pop((qos_consts.RULE_TYPE_BANDWIDTH_LIMIT,
                                        constants.EGRESS_DIRECTION),
                                       None)

        if not port and not vif_port:
            LOG.debug("delete_bandwidth_limit was received "
                      "for port %s but port was not found. "
                      "It seems that bandwidth_limit is already deleted",
                      port_id)
            return
        vif_port = vif_port or port.get('vif_port')
        self.br_int.delete_egress_bw_limit_for_port(vif_port.port_name)

    def delete_bandwidth_limit_ingress(self, port):
        port_id = port.get('port_id')
        vif_port = port.get('vif_port')
        port = self.ports[port_id].pop((qos_consts.RULE_TYPE_BANDWIDTH_LIMIT,
                                        constants.INGRESS_DIRECTION),
                                       None)
        if not port and not vif_port:
            LOG.debug("delete_bandwidth_limit_ingress was received "
                      "for port %s but port was not found. "
                      "It seems that bandwidth_limit is already deleted",
                      port_id)
            return
        vif_port = vif_port or port.get('vif_port')
        self.br_int.delete_ingress_bw_limit_for_port(vif_port.port_name)

    def create_dscp_marking(self, port, rule):
        self.update_dscp_marking(port, rule)

    def update_dscp_marking(self, port, rule):
        self.ports[port['port_id']][qos_consts.RULE_TYPE_DSCP_MARKING] = port
        vif_port = port.get('vif_port')
        if not vif_port:
            port_id = port.get('port_id')
            LOG.debug("update_dscp_marking was received for port %s but "
                      "vif_port was not found. It seems that port is already "
                      "deleted", port_id)
            return
        port = self.br_int.get_port_ofport(vif_port.port_name)
        self.br_int.install_dscp_marking_rule(port=port,
                                              dscp_mark=rule.dscp_mark)

    def delete_dscp_marking(self, port):
        vif_port = port.get('vif_port')
        dscp_port = self.ports[port['port_id']].pop(qos_consts.
                                                    RULE_TYPE_DSCP_MARKING, 0)

        if not dscp_port and not vif_port:
            LOG.debug("delete_dscp_marking was received for port %s but "
                      "no port information was stored to be deleted",
                      port['port_id'])
            return

        vif_port = vif_port or dscp_port.get('vif_port')
        port_num = vif_port.ofport
        self.br_int.uninstall_flows(in_port=port_num, table_id=0, reg2=0)

    def _update_egress_bandwidth_limit(self, vif_port, rule):
        max_kbps = rule.max_kbps
        # NOTE(slaweq): According to ovs docs:
        # http://openvswitch.org/support/dist-docs/ovs-vswitchd.conf.db.5.html
        # ovs accepts only integer values of burst:
        max_burst_kbps = int(self._get_egress_burst_value(rule))

        self.br_int.create_egress_bw_limit_for_port(vif_port.port_name,
                                                    max_kbps,
                                                    max_burst_kbps)

    def _update_ingress_bandwidth_limit(self, vif_port, rule):
        port_name = vif_port.port_name
        max_kbps = rule.max_kbps or 0
        max_burst_kbps = rule.max_burst_kbps or 0

        self.br_int.update_ingress_bw_limit_for_port(
            port_name,
            max_kbps,
            max_burst_kbps
        )

    def create_minimum_bandwidth(self, port, rule):
        self.update_minimum_bandwidth(port, rule)

    def update_minimum_bandwidth(self, port, rule):
        vif_port = port.get('vif_port')
        if not vif_port:
            LOG.debug('update_minimum_bandwidth was received for port %s but '
                      'vif_port was not found. It seems that port is already '
                      'deleted', port.get('port_id'))
            return

        self.ports[port['port_id']][(qos_consts.RULE_TYPE_MINIMUM_BANDWIDTH,
                                     rule.direction)] = port

        # queue_num is used to identify the port which traffic come from,
        # it needs to be unique across br-int. It is convenient to use ofport
        # as queue_num because it is unique in br-int and start from 1.
        egress_port_names = []
        for phy_br in self.agent_api.request_phy_brs():
            ports = phy_br.get_bridge_ports('')
            if not ports:
                LOG.warning('Bridge %s does not have a physical port '
                            'connected', phy_br.br_name)
            egress_port_names.extend(ports)
        qos_id = self.br_int.update_minimum_bandwidth_queue(
            port['port_id'], egress_port_names, vif_port.ofport, rule.min_kbps)
        LOG.debug('Minimum bandwidth rule was updated/created for port '
                  '%(port_id)s and rule %(rule_id)s. QoS ID: %(qos_id)s. '
                  'Egress ports with QoS applied: %(ports)s',
                  {'port_id': port['port_id'], 'rule_id': rule.id,
                   'qos_id': qos_id, 'ports': egress_port_names})

    def delete_minimum_bandwidth(self, port):
        rule_port = self.ports[port['port_id']].pop(
            (qos_consts.RULE_TYPE_MINIMUM_BANDWIDTH,
             constants.EGRESS_DIRECTION), None)
        if not rule_port:
            LOG.debug('delete_minimum_bandwidth was received for port %s but '
                      'no port information was stored to be deleted',
                      port['port_id'])
            return
        self.br_int.delete_minimum_bandwidth_queue(port['port_id'])
        LOG.debug("Minimum bandwidth rule was deleted for port: %s.",
                  port['port_id'])

    def delete_minimum_bandwidth_ingress(self, port):
        rule_port = self.ports[port['port_id']].pop(
            (qos_consts.RULE_TYPE_MINIMUM_BANDWIDTH,
             constants.INGRESS_DIRECTION), None)
        if not rule_port:
            LOG.debug('delete_minimum_bandwidth_ingress was received for port '
                      '%s but no port information was stored to be deleted',
                      port['port_id'])
            return
        LOG.debug("Minimum bandwidth rule for ingress direction was deleted "
                  "for port %s", port['port_id'])

    # new add qos
    def create_loss(self, port, rule):
        LOG.info("create_loss %s %s" % (port['port_id'], rule))
        vif_port = port.get('vif_port')
        # LOG.info("vif_port %s %s" % (vif_port.port_name, vif_port.ofport))
        if not vif_port:
            port_id = port.get('port_id')
            LOG.debug("create_loss was received for port %s but "
                      "vif_port was not found. It seems that port is already "
                      "deleted", port_id)
            return
        self.ports[port['port_id']][qos_consts.RULE_TYPE_LOSS] = port
        cmd_add = ['sudo', 'tc', 'qdisc', 'add', 'dev', vif_port.port_name, 'root', 'netem', 'loss', 'random',
                   str(rule.loss_pct)]
        LOG.info("create_loss cmd %s" % ' '.join(cmd_add))
        execute(cmd_add, run_as_root=False)

    def update_loss(self, port, rule):
        LOG.info("update_loss %s %s" % (port['port_id'], rule))
        vif_port = port.get('vif_port')
        if not vif_port:
            port_id = port.get('port_id')
            LOG.debug("update_loss was received for port %s but "
                      "vif_port was not found. It seems that port is already "
                      "deleted", port_id)
            return
        self.ports[port['port_id']][qos_consts.RULE_TYPE_LOSS] = port
        cmd_del = ['sudo', 'tc', 'qdisc', 'del', 'dev', vif_port.port_name, 'root']
        LOG.info("update_loss cmd %s" % ' '.join(cmd_del))
        execute(cmd_del, run_as_root=False, check_exit_code=False, log_fail_as_error=False)
        cmd_add = ['sudo', 'tc', 'qdisc', 'add', 'dev', vif_port.port_name, 'root', 'netem', 'loss', 'random',
                   str(rule.loss_pct)]
        LOG.info("update_loss cmd %s" % ' '.join(cmd_add))
        execute(cmd_add, run_as_root=False)

    def delete_loss(self, port):
        LOG.info("delete_loss %s" % (port['port_id'],))
        port_id = port.get('port_id')
        port = self.ports[port_id].pop(qos_consts.RULE_TYPE_LOSS, None)
        if not port:
            LOG.debug("delete_loss was received "
                      "for port %s but port was not found. "
                      "It seems that bandwidth_limit is already deleted",
                      port_id)
            return
        vif_port = port.get('vif_port')
        cmd_del = ['sudo', 'tc', 'qdisc', 'del', 'dev', vif_port.port_name, 'root']
        LOG.info("delete_loss cmd %s" % ' '.join(cmd_del))
        execute(cmd_del, run_as_root=False)

    def create_delay(self, port, rule):
        LOG.info("create_delay %s %s" % (port['port_id'], rule))
        vif_port = port.get('vif_port')
        if not vif_port:
            port_id = port.get('port_id')
            LOG.debug("create_delay was received for port %s but "
                      "vif_port was not found. It seems that port is already "
                      "deleted", port_id)
            return
        self.ports[port['port_id']][qos_consts.RULE_TYPE_DELAY] = port
        cmd_add = ['sudo', 'tc', 'qdisc', 'add', 'dev', vif_port.port_name, 'root', 'netem', 'delay',
                   '%sms' % rule.delay_ms, '%sms' % rule.delay_correlation_ms]
        LOG.info("create_delay cmd %s" % ' '.join(cmd_add))
        execute(cmd_add, run_as_root=False)

    def update_delay(self, port, rule):
        LOG.info("update_delay %s %s" % (port['port_id'], rule))
        vif_port = port.get('vif_port')
        if not vif_port:
            port_id = port.get('port_id')
            LOG.debug("update_delay was received for port %s but "
                      "vif_port was not found. It seems that port is already "
                      "deleted", port_id)
            return
        self.ports[port['port_id']][qos_consts.RULE_TYPE_DELAY] = port
        cmd_del = ['sudo', 'tc', 'qdisc', 'del', 'dev', vif_port.port_name, 'root']
        LOG.info("update_delay cmd %s" % ' '.join(cmd_del))
        execute(cmd_del, run_as_root=False, check_exit_code=False, log_fail_as_error=False)
        cmd_add = ['sudo', 'tc', 'qdisc', 'add', 'dev', vif_port.port_name, 'root', 'netem', 'delay',
                   '%sms' % rule.delay_ms, '%sms' % rule.delay_correlation_ms]
        LOG.info("update_delay cmd %s" % ' '.join(cmd_add))
        execute(cmd_add, run_as_root=False)

    def delete_delay(self, port):
        LOG.info("delete_delay %s" % (port['port_id'],))
        port_id = port.get('port_id')
        port = self.ports[port_id].pop(qos_consts.RULE_TYPE_DELAY, None)
        if not port:
            LOG.debug("delete_delay was received "
                      "for port %s but port was not found. "
                      "It seems that bandwidth_limit is already deleted",
                      port_id)
            return
        vif_port = port.get('vif_port')
        cmd_del = ['sudo', 'tc', 'qdisc', 'del', 'dev', vif_port.port_name, 'root']
        LOG.info("delete_delay cmd %s" % ' '.join(cmd_del))
        execute(cmd_del, run_as_root=False)
    # new end qos

```

修改services

```
# neutron/services/qos/drivers/openvswitch/driver.py
# Copyright (c) 2016 Red Hat Inc.
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from neutron_lib.api.definitions import portbindings
from neutron_lib import constants
from neutron_lib.db import constants as db_consts
from neutron_lib.services.qos import base
from neutron_lib.services.qos import constants as qos_consts
from oslo_log import log as logging

from neutron.objects import network as network_object


LOG = logging.getLogger(__name__)

DRIVER = None

SUPPORTED_RULES = {
    qos_consts.RULE_TYPE_BANDWIDTH_LIMIT: {
        qos_consts.MAX_KBPS: {
            'type:range': [0, db_consts.DB_INTEGER_MAX_VALUE]},
        qos_consts.MAX_BURST: {
            'type:range': [0, db_consts.DB_INTEGER_MAX_VALUE]},
        qos_consts.DIRECTION: {
            'type:values': constants.VALID_DIRECTIONS}
    },
    qos_consts.RULE_TYPE_DSCP_MARKING: {
        qos_consts.DSCP_MARK: {'type:values': constants.VALID_DSCP_MARKS}
    },
    # new add qos
    qos_consts.RULE_TYPE_LOSS: {
            qos_consts.LOSS_PCT: {
                'type:range': [0, 100]
            },
        },
        qos_consts.RULE_TYPE_DELAY: {
            qos_consts.DELAY_MS: {
                'type:range': [0, 60000]
            },
            qos_consts.DELAY_CORRELATION_MS: {
                'type:range': [0, 10000]
            }
        },
    # new end qos
    qos_consts.RULE_TYPE_MINIMUM_BANDWIDTH: {
        qos_consts.MIN_KBPS: {
            'type:range': [0, db_consts.DB_INTEGER_MAX_VALUE]},
        qos_consts.DIRECTION: {'type:values': constants.VALID_DIRECTIONS}
    }
}


class OVSDriver(base.DriverBase):

    @staticmethod
    def create():
        return OVSDriver(
            name='openvswitch',
            vif_types=[portbindings.VIF_TYPE_OVS,
                       portbindings.VIF_TYPE_VHOST_USER],
            vnic_types=[portbindings.VNIC_NORMAL, portbindings.VNIC_DIRECT],
            supported_rules=SUPPORTED_RULES,
            requires_rpc_notifications=True)

    def validate_rule_for_port(self, context, rule, port):
        # Minimum-bandwidth rule is only supported on networks whose
        # first segment is backed by a physnet.
        if rule.rule_type == qos_consts.RULE_TYPE_MINIMUM_BANDWIDTH:
            net = network_object.Network.get_object(
                context, id=port.network_id)
            physnet = net.segments[0].physical_network
            if physnet is None:
                return False
        return True


def register():
    """Register the driver."""
    global DRIVER
    if not DRIVER:
        DRIVER = OVSDriver.create()
    LOG.debug('Open vSwitch QoS driver registered')

```

### 4.2 neutron-lib修改

```
# neutron_lib/api/definitions/qos.py
# Copyright (c) 2015 Red Hat Inc.
# All rights reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from neutron_lib.api import converters
from neutron_lib.api.definitions import network
from neutron_lib.api.definitions import port
from neutron_lib import constants
from neutron_lib.db import constants as db_const
from neutron_lib.services.qos import constants as qos_const


BANDWIDTH_LIMIT_RULES = "bandwidth_limit_rules"
RULE_TYPES = "rule_types"
POLICIES = 'policies'
POLICY = 'policy'
DSCP_MARKING_RULES = 'dscp_marking_rules'
MIN_BANDWIDTH_RULES = 'minimum_bandwidth_rules'
# new add qos
LOSS_RULES = 'loss_rules'
DELAY_RULES = 'delay_rules'
# new end qos
_QOS_RULE_COMMON_FIELDS = {
    'id': {
        'allow_post': False, 'allow_put': False,
        'validate': {'type:uuid': None},
        'is_visible': True,
        'is_filter': True,
        'is_sort_key': True,
        'primary_key': True
    },
    'tenant_id': {
        'allow_post': True, 'allow_put': False,
        'required_by_policy': True,
        'is_visible': True
    }
}

ALIAS = 'qos'
IS_SHIM_EXTENSION = False
IS_STANDARD_ATTR_EXTENSION = False
NAME = 'Quality of Service'
API_PREFIX = '/' + ALIAS
DESCRIPTION = 'The Quality of Service extension.'
UPDATED_TIMESTAMP = '2015-06-08T10:00:00-00:00'
RESOURCE_ATTRIBUTE_MAP = {
    POLICIES: {
        'id': {
            'allow_post': False, 'allow_put': False,
            'validate': {'type:uuid': None},
            'is_filter': True, 'is_sort_key': True,
            'is_visible': True, 'primary_key': True
        },
        'name': {
            'allow_post': True, 'allow_put': True,
            'is_visible': True, 'default': '',
            'is_filter': True, 'is_sort_key': True,
            'validate': {'type:string': db_const.NAME_FIELD_SIZE}},
        constants.SHARED: {
            'allow_post': True, 'allow_put': True,
            'is_visible': True, 'default': False,
            'is_filter': True,
            'convert_to': converters.convert_to_boolean
        },
        'tenant_id': {
            'allow_post': True, 'allow_put': False,
            'required_by_policy': True,
            'validate': {'type:string': db_const.PROJECT_ID_FIELD_SIZE},
            'is_filter': True, 'is_sort_key': True,
            'is_visible': True
        },
        'rules': {
            'allow_post': False,
            'allow_put': False,
            'is_visible': True
        }
    },
    RULE_TYPES: {
        'type': {
            'allow_post': False, 'allow_put': False,
            'is_visible': True
        }
    },
    port.COLLECTION_NAME: {
        qos_const.QOS_POLICY_ID: {
            'allow_post': True,
            'allow_put': True,
            'is_visible': True,
            'default': None,
            'validate': {'type:uuid_or_none': None}
        }
    },
    network.COLLECTION_NAME: {
        qos_const.QOS_POLICY_ID: {
            'allow_post': True,
            'allow_put': True,
            'is_visible': True,
            'default': None,
            'validate': {'type:uuid_or_none': None}
        }
    }
}
_PARENT = {
    'collection_name': POLICIES,
    'member_name': POLICY
}
SUB_RESOURCE_ATTRIBUTE_MAP = {
    BANDWIDTH_LIMIT_RULES: {
        'parent': _PARENT,
        'parameters': dict(
            _QOS_RULE_COMMON_FIELDS,
            **{qos_const.MAX_KBPS: {
                'allow_post': True, 'allow_put': True,
                'convert_to': converters.convert_to_int,
                'is_visible': True,
                'is_filter': True,
                'is_sort_key': True,
                'validate': {
                    'type:range': [0, db_const.DB_INTEGER_MAX_VALUE]}
            },
                qos_const.MAX_BURST: {
                    'allow_post': True, 'allow_put': True,
                    'is_visible': True, 'default': 0,
                    'is_filter': True,
                    'is_sort_key': True,
                    'convert_to': converters.convert_to_int,
                    'validate': {
                        'type:range': [0, db_const.DB_INTEGER_MAX_VALUE]}}}),
    },
    DSCP_MARKING_RULES: {
        'parent': _PARENT,
        'parameters': dict(
            _QOS_RULE_COMMON_FIELDS,
            **{qos_const.DSCP_MARK: {
                'allow_post': True, 'allow_put': True,
                'convert_to': converters.convert_to_int,
                'is_visible': True,
                'is_filter': True,
                'is_sort_key': True,
                'validate': {
                    'type:values': constants.VALID_DSCP_MARKS}}})
    },
    # new add qos
    LOSS_RULES: {
            'parent': _PARENT,
            'parameters': dict(
                _QOS_RULE_COMMON_FIELDS,
                **{'loss_pct': {
                    'allow_post': True, 'allow_put': True,
                    'convert_to': converters.convert_to_int,
                    'is_visible': True,
                    #'validate': {'type:values': constants.VALID_DSCP_MARKS}
                }})
        },
    DELAY_RULES: {
        'parent': _PARENT,
        'parameters': dict(
            _QOS_RULE_COMMON_FIELDS,
            **{'delay_ms': {
                'allow_post': True, 'allow_put': True,
                'convert_to': converters.convert_to_int,
                'is_visible': True,
                #'validate': {'type:values': constants.VALID_DSCP_MARKS}
            }, 'delay_correlation_ms': {
                'allow_post': True, 'allow_put': True,
                'convert_to': converters.convert_to_int,
                'is_visible': True,
                #'validate': {'type:values': constants.VALID_DSCP_MARKS}
            }})
    },
    # new end qos
    MIN_BANDWIDTH_RULES: {
        'parent': _PARENT,
        'parameters': dict(
            _QOS_RULE_COMMON_FIELDS,
            **{qos_const.MIN_KBPS: {
                'allow_post': True, 'allow_put': True,
                'is_visible': True,
                'is_filter': True,
                'is_sort_key': True,
                'convert_to': converters.convert_to_int,
                'validate': {
                    'type:range': [0, db_const.DB_INTEGER_MAX_VALUE]}},
                qos_const.DIRECTION: {
                    'allow_post': True, 'allow_put': True,
                    'is_visible': True, 'default': constants.EGRESS_DIRECTION,
                    'is_filter': True,
                    'is_sort_key': True,
                    'validate': {
                        'type:values': [constants.EGRESS_DIRECTION]}}})
    }
}
ACTION_MAP = {}
REQUIRED_EXTENSIONS = []
OPTIONAL_EXTENSIONS = []
ACTION_STATUS = {}

```

```
# neutron_lib/services/qos/constants.py
# Copyright (c) 2015 Red Hat Inc.
# All rights reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

RULE_TYPE_BANDWIDTH_LIMIT = 'bandwidth_limit'
RULE_TYPE_DSCP_MARKING = 'dscp_marking'
RULE_TYPE_MINIMUM_BANDWIDTH = 'minimum_bandwidth'
# new add qos
RULE_TYPE_LOSS = 'loss'
RULE_TYPE_DELAY = 'delay'
# new end qos
VALID_RULE_TYPES = [RULE_TYPE_BANDWIDTH_LIMIT,
                    RULE_TYPE_DSCP_MARKING,
                    RULE_TYPE_MINIMUM_BANDWIDTH,
                    # new qos
                    RULE_TYPE_LOSS,
                    RULE_TYPE_DELAY,
                    # new end qos
                    ]

# Names of rules' attributes
MAX_KBPS = "max_kbps"
MAX_BURST = "max_burst_kbps"
MIN_KBPS = "min_kbps"
DIRECTION = "direction"
DSCP_MARK = "dscp_mark"
# new qos
LOSS_PCT = 'loss_pct'
DELAY_MS = 'delay_ms'
DELAY_CORRELATION_MS = 'delay_correlation_ms'
# new end qos

QOS_POLICY_ID = 'qos_policy_id'
QOS_NETWORK_POLICY_ID = 'qos_network_policy_id'

QOS_PLUGIN = 'qos_plugin'

# NOTE(slaweq): Value used to calculate burst value for egress bandwidth limit
# if burst is not given by user. In such case burst value will be calculated
# as 80% of bw_limit to ensure that at least limits for TCP traffic will work
# fine.
DEFAULT_BURST_RATE = 0.8

# Method names for QoSDriver
PRECOMMIT_POSTFIX = '_precommit'
CREATE_POLICY = 'create_policy'
CREATE_POLICY_PRECOMMIT = CREATE_POLICY + PRECOMMIT_POSTFIX
UPDATE_POLICY = 'update_policy'
UPDATE_POLICY_PRECOMMIT = UPDATE_POLICY + PRECOMMIT_POSTFIX
DELETE_POLICY = 'delete_policy'
DELETE_POLICY_PRECOMMIT = DELETE_POLICY + PRECOMMIT_POSTFIX

QOS_CALL_METHODS = (
    CREATE_POLICY,
    CREATE_POLICY_PRECOMMIT,
    UPDATE_POLICY,
    UPDATE_POLICY_PRECOMMIT,
    DELETE_POLICY,
    DELETE_POLICY_PRECOMMIT, )

```

```
# neutron_lib/tests/unit/api/definitions/test_qos.py
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

from neutron_lib.api.definitions import qos
from neutron_lib.services.qos import constants as q_const
from neutron_lib.tests.unit.api.definitions import base


class QoSDefinitionTestCase(base.DefinitionBaseTestCase):
    extension_module = qos
    extension_resources = (qos.POLICIES, qos.RULE_TYPES)
    extension_subresources = (qos.BANDWIDTH_LIMIT_RULES,
                              qos.DSCP_MARKING_RULES,
                              # new add qos
                              qos.DELAY_RULES,
                              qos.LOSS_RULES,
                              # new end qos
                              qos.MIN_BANDWIDTH_RULES)
    extension_attributes = (q_const.DIRECTION, q_const.MAX_BURST, 'type',
                            q_const.DSCP_MARK, q_const.MIN_KBPS, 'rules',
                            q_const.MAX_KBPS, q_const.QOS_POLICY_ID,
                            # new add qos
                            q_const.DELAY_CORRELATION_MS, q_const.DELAY_MS, q_const.LOSS_PCT)
                            # new end qos

```

### 4.3 neutronclient修改

neutronclient入口

```
# entry_points.txt
qos-delay-rule-create = neutronclient.neutron.v2_0.qos.delay_rule:CreateQoSDelayRule
qos-delay-rule-delete = neutronclient.neutron.v2_0.qos.delay_rule:DeleteQoSDelayRule
qos-delay-rule-list = neutronclient.neutron.v2_0.qos.delay_rule:ListQoSDelayRules
qos-delay-rule-show = neutronclient.neutron.v2_0.qos.delay_rule:ShowQoSDelayRule
qos-delay-rule-update = neutronclient.neutron.v2_0.qos.delay_rule:UpdateQoSDelayRule
qos-loss-rule-create = neutronclient.neutron.v2_0.qos.loss_rule:CreateQoSLossRule
qos-loss-rule-delete = neutronclient.neutron.v2_0.qos.loss_rule:DeleteQoSLossRule
qos-loss-rule-list = neutronclient.neutron.v2_0.qos.loss_rule:ListQoSLossRules
qos-loss-rule-show = neutronclient.neutron.v2_0.qos.loss_rule:ShowQoSLossRule
qos-loss-rule-update = neutronclient.neutron.v2_0.qos.loss_rule:UpdateQoSLossRule
```

```
# neutronclient/neutron/v2_0/qos/delay_rule.py
from neutronclient._i18n import _
from neutronclient.common import exceptions
from neutronclient.neutron import v2_0 as neutronv20
from neutronclient.neutron.v2_0.qos import rule as qos_rule


DELAY_RESOURCE = 'delay_rule'

def add_delay_arguments(parser):
    parser.add_argument(
        '--delay-ms',
        required=True,
        type=int,
        help=_('Delay ms between 0 and 60000'))
    parser.add_argument(
        '--delay-correlation-ms',
        required=True,
        type=int,
        help=_('Delay correlation ms between 0 and 30000'))

def update_delay_args2body(parsed_args, body):
    delay_ms = parsed_args.delay_ms
    delay_correlation_ms = parsed_args.delay_correlation_ms
    if not 0 <= int(delay_ms) <= 60000:
        raise exceptions.CommandError(_("Delay ms %s not supported, should between 0 and 60000") % delay_ms)
    if not 0 <= int(delay_correlation_ms) <= 30000:
        raise exceptions.CommandError(_("Delay correlation ms %s not supported, should between 0 and 30000") % delay_correlation_ms)
    neutronv20.update_dict(parsed_args, body,
                           ['delay_ms', 'delay_correlation_ms'])


class CreateQoSDelayRule(qos_rule.QosRuleMixin,
                               neutronv20.CreateCommand):
    resource = DELAY_RESOURCE

    def add_known_arguments(self, parser):
        super(CreateQoSDelayRule, self).add_known_arguments(parser)
        add_delay_arguments(parser)

    def args2body(self, parsed_args):
        body = {}
        update_delay_args2body(parsed_args, body)
        return {self.resource: body}


class ListQoSDelayRules(qos_rule.QosRuleMixin,
                              neutronv20.ListCommand):

    _formatters = {}
    pagination_support = True
    sorting_support = True
    resource = DELAY_RESOURCE


class ShowQoSDelayRule(qos_rule.QosRuleMixin,
                             neutronv20.ShowCommand):

    resource = DELAY_RESOURCE
    allow_names = False


class UpdateQoSDelayRule(qos_rule.QosRuleMixin,
                               neutronv20.UpdateCommand):

    allow_names = False
    resource = DELAY_RESOURCE

    def add_known_arguments(self, parser):
        super(UpdateQoSDelayRule, self).add_known_arguments(parser)
        add_delay_arguments(parser)

    def args2body(self, parsed_args):
        body = {}
        update_delay_args2body(parsed_args, body)
        return {self.resource: body}


class DeleteQoSDelayRule(qos_rule.QosRuleMixin,
                               neutronv20.DeleteCommand):

    allow_names = False
    resource = DELAY_RESOURCE
```

```
from neutronclient._i18n import _
from neutronclient.common import exceptions
from neutronclient.neutron import v2_0 as neutronv20
from neutronclient.neutron.v2_0.qos import rule as qos_rule


LOSS_RESOURCE = 'loss_rule'


def add_loss_arguments(parser):
    parser.add_argument(
        '--loss-pct',
        required=True,
        type=int,
        help=_('Loss percentage between 0 and 100'))


def update_loss_args2body(parsed_args, body):
    loss_pct = parsed_args.loss_pct
    if int(loss_pct) not in range(0, 101):
        raise exceptions.CommandError(_("Loss percentage %s not supported, should between 0 and 100") % loss_pct)
    neutronv20.update_dict(parsed_args, body,
                           ['loss_pct'])


class CreateQoSLossRule(qos_rule.QosRuleMixin,
                               neutronv20.CreateCommand):
    resource = LOSS_RESOURCE

    def add_known_arguments(self, parser):
        super(CreateQoSLossRule, self).add_known_arguments(parser)
        add_loss_arguments(parser)

    def args2body(self, parsed_args):
        body = {}
        update_loss_args2body(parsed_args, body)
        return {self.resource: body}


class ListQoSLossRules(qos_rule.QosRuleMixin,
                              neutronv20.ListCommand):

    _formatters = {}
    pagination_support = True
    sorting_support = True
    resource = LOSS_RESOURCE


class ShowQoSLossRule(qos_rule.QosRuleMixin,
                             neutronv20.ShowCommand):

    resource = LOSS_RESOURCE
    allow_names = False


class UpdateQoSLossRule(qos_rule.QosRuleMixin,
                               neutronv20.UpdateCommand):

    allow_names = False
    resource = LOSS_RESOURCE

    def add_known_arguments(self, parser):
        super(UpdateQoSLossRule, self).add_known_arguments(parser)
        add_loss_arguments(parser)

    def args2body(self, parsed_args):
        body = {}
        update_loss_args2body(parsed_args, body)
        return {self.resource: body}


class DeleteQoSLossRule(qos_rule.QosRuleMixin,
                               neutronv20.DeleteCommand):

    allow_names = False
    resource = LOSS_RESOURCE
```

```
# neutronclient/v2.0/client.py
    # new add qos
    qos_loss_rules_path = "/qos/policies/%s/loss_rules"
    qos_loss_rule_path = "/qos/policies/%s/loss_rules/%s"
    qos_delay_rules_path = "/qos/policies/%s/delay_rules"
    qos_delay_rule_path = "/qos/policies/%s/delay_rules/%s"
    # new end qos
    # new add qos
    def list_loss_rules(self, policy_id,
                        retrieve_all=True, **_params):
        return self.list('loss_rules',
                         self.qos_loss_rules_path % policy_id,
                         retrieve_all, **_params)

    def show_loss_rule(self, rule, policy, **_params):
        return self.get(self.qos_loss_rule_path %
                        (policy, rule), params=_params)

    def create_loss_rule(self, policy, body=None):
        return self.post(self.qos_loss_rules_path % policy,
                         body=body)

    def update_loss_rule(self, rule, policy, body=None):
        return self.put(self.qos_loss_rule_path %
                        (policy, rule), body=body)

    def delete_loss_rule(self, rule, policy):
        return self.delete(self.qos_loss_rule_path %
                           (policy, rule))

    def list_delay_rules(self, policy_id,
                         retrieve_all=True, **_params):
        return self.list('delay_rules',
                         self.qos_delay_rules_path % policy_id,
                         retrieve_all, **_params)

    def show_delay_rule(self, rule, policy, **_params):
        return self.get(self.qos_delay_rule_path %
                        (policy, rule), params=_params)

    def create_delay_rule(self, policy, body=None):
        return self.post(self.qos_delay_rules_path % policy,
                         body=body)

    def update_delay_rule(self, rule, policy, body=None):
        return self.put(self.qos_delay_rule_path %
                        (policy, rule), body=body)

    def delete_delay_rule(self, rule, policy):
        return self.delete(self.qos_delay_rule_path %
                           (policy, rule))

    # new end qos
```