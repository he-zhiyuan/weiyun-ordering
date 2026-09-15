import request from './request'

export function getCategoryList(type) {
  return request({ url: '/user/category/list', method: 'get', params: { type } })
}
