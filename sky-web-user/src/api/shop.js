import request from './request'

export function getShopStatus() {
  return request({ url: '/user/shop/status', method: 'get' })
}

export function getShopPhone() {
  return request({ url: '/user/shop/phone', method: 'get' })
}
