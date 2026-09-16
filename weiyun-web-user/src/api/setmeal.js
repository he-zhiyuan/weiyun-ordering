import request from './request'

export function getSetmealList(categoryId) {
  return request({ url: '/user/setmeal/list', method: 'get', params: { categoryId } })
}

export function getSetmealDishes(id) {
  return request({ url: `/user/setmeal/dish/${id}`, method: 'get' })
}
