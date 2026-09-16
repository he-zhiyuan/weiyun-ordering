import request from './request'

export function getDishList(categoryId) {
  return request({ url: '/user/dish/list', method: 'get', params: { categoryId } })
}
