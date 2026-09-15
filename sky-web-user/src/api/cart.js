import request from './request'

export function addToCart(data) {
  return request({ url: '/user/shoppingCart/add', method: 'post', data })
}

export function getCartList() {
  return request({ url: '/user/shoppingCart/list', method: 'get' })
}

export function cleanCart() {
  return request({ url: '/user/shoppingCart/clean', method: 'delete' })
}

export function subCart(data) {
  return request({ url: '/user/shoppingCart/sub', method: 'post', data })
}
