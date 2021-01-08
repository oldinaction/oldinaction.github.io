---
layout: "post"
title: "行业概念"
date: "2017-10-12 11:22"
categories: [others]
tags: [business, conception]
---

## 通用

- `ERP` 企业资源计划(Enterprise Resource Planning)
- `CRM` 客户关系管理(Customer Relationship Management)
- `OMS` 订单管理系统
- `WMS` 仓库管理系统
- `TMS` 运输管理系统
- `OA` 办公自动化
- `BU` 业务单元(Business Units，公司的一个部门)，`Strategical Business Unit` 战略业务单元

## 物流

- `WMS` 仓库管理系统(Warehouse Management System)
- `MES` 制造执行系统(Manufacturing Execution System) [^1]
    - 功能：库房管理、生产调度、制造过程管理、质量管理、设备工装管理、文档管理、物料批次跟踪
- `FOB`、`CFR`、`CIF`
    - FOB(free on board)，船上交货
    - CFR(cost and freight)成本加运费，船上交货
    - CIF(cost, insurance and freight)成本加保险费加运费，船上交货
- `FBA` 亚马逊代发货服务(Fulfillment by Amazon)

## 营销/运营

- `MVP` 最小价值产品或最小可视化产品(Minimal Viable Product) [^2]

## 费用

- 费目、费目计算规则(影响因素)、费率本(将多个基础费目进行收付的组合方便输入)
- 费用表结构设计
    - 费用明细在对账时可以进行拆分(客户对总金额是同意的，可能由于账期将其中一部分金额放到下次。复制一条数据出来，保证金额数不变)，财务和业务对费用只要保证一个费目下面的总和是多少(业务不关心有几条费用)
    - 生成的对账单，可进行踢回（取消其中部分的对账）；多个对账单可以对应一个发票，一个对账单不能对应多个发票（对账单是开票的最小单位，如果对应多个发票，就可能对费用明细进行了拆分，最终可能导致无法明确费用明细和核销的关系）
    - 核销包括主子表。主表为每次实际到账时产生的，子表存放此次到账(水单)金额(100)与明细(10个10元)的拆分关系（费用明细ID存放在核销明细中，如果到账150，有两个100的费用明细，此时其中一个明细对应两次核销）
    - 发票最终对应的凭证的应收，核销最终对应的凭证的实收
    - 对账单和发票表需要子表主要是考虑到付款
    - 结算客户尽量保证一张表：如客户和供应商基于类型区分
    - 发票明细不需要和费用明细对应，可以理解为发票的小票下面的明细（如按照商品、费目等归类，可按照实际业务归类）
    - 结算客户应该保存在费用明细中，有可能一个订单给不同的客户结算
    - 对于多币种常见，费用明细表存储原当时汇率、币种金额合计、本币金额(如保存时经过汇率计算后的人民币金额)




---

[^1]: [MES七大功能-MES解决方案](https://wenku.baidu.com/view/1627cd0a844769eae009edfe.html)
[^2]: [MVP是什么](https://www.zhihu.com/question/47489768?from=profile_question_card)
