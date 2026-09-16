import { defineStore } from 'pinia'

// 下单流程中的临时状态：选中的地址、备注、送达时间等，
// 以及提交订单后 / 支付前用到的订单号、金额等信息
export const useOrderStore = defineStore('order', {
  state: () => ({
    selectedAddress: null,
    remark: '',
    deliveryStatus: 1, // 1立即送出 0选择具体时间
    estimatedDeliveryTime: '',
    tablewareStatus: 1, // 1按餐量提供 0选择具体数量
    tablewareNumber: 1,
    packAmount: 1,
    pendingOrder: null, // { id, orderNumber, orderAmount, orderTime }
  }),
  actions: {
    setSelectedAddress(address) {
      this.selectedAddress = address
    },
    setPendingOrder(order) {
      this.pendingOrder = order
    },
    resetCheckoutForm() {
      this.remark = ''
      this.deliveryStatus = 1
      this.estimatedDeliveryTime = ''
      this.tablewareStatus = 1
      this.tablewareNumber = 1
      this.packAmount = 1
    },
  },
})
