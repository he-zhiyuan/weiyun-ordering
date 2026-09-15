import request from './request'

export function getAddressList() {
  return request({ url: '/user/addressBook/list', method: 'get' })
}

export function addAddress(data) {
  return request({ url: '/user/addressBook', method: 'post', data })
}

export function getAddressById(id) {
  return request({ url: `/user/addressBook/${id}`, method: 'get' })
}

export function updateAddress(data) {
  return request({ url: '/user/addressBook', method: 'put', data })
}

export function setDefaultAddress(data) {
  return request({ url: '/user/addressBook/default', method: 'put', data })
}

export function deleteAddress(id) {
  return request({ url: '/user/addressBook', method: 'delete', params: { id } })
}

export function getDefaultAddress() {
  return request({ url: '/user/addressBook/default', method: 'get' })
}
