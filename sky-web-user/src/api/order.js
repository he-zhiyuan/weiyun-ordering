import request from './request'

export function submitOrder(data) {
  return request({ url: '/user/order/submit', method: 'post', data })
}

export function payOrder(data) {
  return request({ url: '/user/order/payment', method: 'put', data })
}

export function getHistoryOrders(params) {
  return request({ url: '/user/order/historyOrders', method: 'get', params })
}

export function getOrderDetail(id) {
  return request({ url: `/user/order/orderDetail/${id}`, method: 'get' })
}

export function cancelOrder(id) {
  return request({ url: `/user/order/cancel/${id}`, method: 'put' })
}

export function repetitionOrder(id) {
  return request({ url: `/user/order/repetition/${id}`, method: 'post' })
}

export function reminderOrder(id) {
  return request({ url: `/user/order/reminder/${id}`, method: 'get' })
}
