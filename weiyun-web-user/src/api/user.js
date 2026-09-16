import request from './request'

export function webLogin(data) {
  return request({ url: '/user/user/webLogin', method: 'post', data })
}
