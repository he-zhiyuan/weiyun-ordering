# 模拟支付说明

项目支持通过配置切换真实微信支付和本地模拟支付。开发环境 `sky-server/src/main/resources/application-dev.yml` 已设置：

```yaml
sky:
  wechat:
    mock-payment: true
```

开启后调用用户端 `PUT /user/order/payment` 仍使用原来的请求格式：

```json
{"orderNumber":"订单号","payMethod":1}
```

服务端会校验当前用户、订单状态和订单归属，然后在同一个事务中把订单更新为 `payStatus=1`（已支付）、`status=2`（待接单），并返回 `data.mockPayment=true`。返回的支付参数仅用于兼容原有响应结构，不要再传给 `wx.requestPayment`；小程序应在该字段为 `true` 时直接按支付成功处理并刷新订单列表。模拟支付也会发送管理端来单 WebSocket 通知。

关闭开关（`mock-payment: false`）后，接口恢复微信 JSAPI 下单，并使用订单实际金额；微信支付回调 `/notify/paySuccess` 可在没有用户 JWT 的情况下通过订单号完成状态更新。

模拟支付下的用户取消、商家拒单和商家取消会跳过微信退款网络请求，并把已支付订单标记为退款，便于本地完整演示订单流程。
