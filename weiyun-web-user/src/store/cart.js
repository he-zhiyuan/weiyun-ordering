import { defineStore } from 'pinia'
import { getCartList } from '../api/cart'

export const useCartStore = defineStore('cart', {
  state: () => ({
    list: [],
  }),
  getters: {
    totalCount: (state) => state.list.reduce((sum, item) => sum + item.number, 0),
    totalAmount: (state) =>
      state.list.reduce((sum, item) => sum + Number(item.amount) * item.number, 0),
  },
  actions: {
    async refresh() {
      const res = await getCartList()
      this.list = res.data || []
    },
    clear() {
      this.list = []
    },
  },
})
