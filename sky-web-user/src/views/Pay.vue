<template>
  <div class="pay-page">
    <div class="pay-card" v-if="order">
      <div class="amount">¥{{ Number(order.orderAmount).toFixed(2) }}</div>
      <div class="order-number">订单号：{{ order.orderNumber }}</div>
      <div class="countdown">
        请在 <span class="time">{{ countdownText }}</span> 内完成支付，超时订单将自动取消
      </div>

      <div class="pay-method">
        <div
          v-for="m in payMethods"
          :key="m.value"
          class="method-item"
          :class="{ active: payMethod === m.value }"
          @click="payMethod = m.value"
        >
          {{ m.label }}
        </div>
      </div>

      <el-button type="primary" size="large" style="width: 100%" :loading="paying" @click="handlePay">
        确认支付
      </el-button>
      <el-button link style="margin-top: 12px" @click="handleCancel">取消订单</el-button>
    </div>
    <el-empty v-else description="没有待支付的订单" />
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { payOrder, cancelOrder } from '../api/order'
import { useOrderStore } from '../store/order'

const PAY_WINDOW_SECONDS = 15 * 60

const router = useRouter()
const orderStore = useOrderStore()
const order = computed(() => orderStore.pendingOrder)

const payMethods = [
  { label: '微信支付', value: 1 },
  { label: '支付宝支付', value: 2 },
]
const payMethod = ref(1)
const paying = ref(false)
const remainSeconds = ref(PAY_WINDOW_SECONDS)
let timer = null

const countdownText = computed(() => {
  const m = Math.floor(remainSeconds.value / 60)
  const s = remainSeconds.value % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
})

function startCountdown() {
  if (!order.value) return
  const orderTime = new Date(order.value.orderTime.replace(/-/g, '/')).getTime()
  timer = setInterval(() => {
    const elapsed = Math.floor((Date.now() - orderTime) / 1000)
    const remain = PAY_WINDOW_SECONDS - elapsed
    if (remain <= 0) {
      remainSeconds.value = 0
      clearInterval(timer)
      handleTimeout()
    } else {
      remainSeconds.value = remain
    }
  }, 1000)
}

async function handleTimeout() {
  ElMessage.warning('支付超时，订单已自动取消')
  try {
    await cancelOrder(order.value.id)
  } catch (e) {
    // 订单可能已被处理，忽略取消异常
  }
  orderStore.setPendingOrder(null)
  router.replace('/orders')
}

async function handlePay() {
  if (!order.value) return
  paying.value = true
  try {
    const res = await payOrder({ orderNumber: order.value.orderNumber, payMethod: payMethod.value })
    if (res.data && res.data.mockPayment) {
      router.replace({ path: '/pay-success', query: { id: order.value.id } })
    } else {
      ElMessage.success('支付成功')
      router.replace({ path: '/pay-success', query: { id: order.value.id } })
    }
  } finally {
    paying.value = false
  }
}

async function handleCancel() {
  await ElMessageBox.confirm('确认取消该订单吗？', '提示', { type: 'warning' })
  await cancelOrder(order.value.id)
  ElMessage.success('订单已取消')
  orderStore.setPendingOrder(null)
  router.replace('/')
}

onMounted(() => {
  startCountdown()
})
onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.pay-page {
  min-height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8f8f8;
}
.pay-card {
  width: 400px;
  background: #fff;
  border-radius: 12px;
  padding: 40px 32px;
  text-align: center;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.08);
}
.amount {
  font-size: 36px;
  font-weight: 700;
  color: #ff6600;
}
.order-number {
  color: #999;
  font-size: 13px;
  margin-top: 8px;
}
.countdown {
  margin: 16px 0 24px;
  color: #666;
  font-size: 13px;
}
.time {
  color: #f56c6c;
  font-weight: 600;
}
.pay-method {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 24px;
}
.method-item {
  border: 1px solid #e5e5e5;
  border-radius: 8px;
  padding: 14px;
  cursor: pointer;
}
.method-item.active {
  border-color: #ff9800;
  color: #ff9800;
  background: #fff7ec;
}
</style>
