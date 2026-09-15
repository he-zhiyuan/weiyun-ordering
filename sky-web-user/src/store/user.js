import { defineStore } from 'pinia'

export const useUserStore = defineStore('user', {
  state: () => ({
    token: '',
    userId: null,
    phone: '',
    name: '',
  }),
  getters: {
    isLoggedIn: (state) => !!state.token,
  },
  actions: {
    setUser({ token, id, phone, name }) {
      this.token = token
      this.userId = id
      this.phone = phone
      this.name = name
    },
    logout() {
      this.token = ''
      this.userId = null
      this.phone = ''
      this.name = ''
    },
  },
  persist: true,
})
