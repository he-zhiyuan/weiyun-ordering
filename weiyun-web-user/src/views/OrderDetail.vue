<template>
  <div class="detail-page" v-loading="loading">
    <header class="page-header">
      <el-button link @click="router.back()">&lt; 返回</el-button>
      <span class="title">订单详情</span>
    </header>

    <div v-if="order" class="content">
      <section class="card status-card">
        <div class="status-text">{{ statusText }}</div>
        <div v-if="order.status === 1" class="countdown">
          请在 <span class="time">{{ countdownText }}</span> 内完成支付
        </div>
      </section>

      <section class="card">
        <div class="card-title">收货信息</div>
        <div class="info-row">收货人：{{ order.consignee }}</div>
        <div class="info-row">联系电话：{{ order.phone }}</div>
        <div class="info-row">收货地址：{{ order.address }}</div>
      </section>

      <section class="card">
        <div class="card-title">商品清单</div>
        <div v-for="d in order.orderDetailList" :key="d.id" class="dish-row">
          <img :src="d.image || DISH_PLACEHOLDER" @error="onImageError" />
          <div class="dish-row-info">
            <div>{{ d.name }}</div>
            <div v-if="d.dishFlavor" class="flavor">{{ d.dishFlavor }}</div>
          </div>
          <div class="dish-row-qty">x{{ d.number }}</div>
          <div class="dish-row-amount">¥{{ (d.amount * d.number).toFixed(2) }}</div>
        </div>
      </section>

      <section class="card">
        <div class="card-title">订单信息</div>
        <div class="info-row">订单号：{{ order.number }}</div>
        <div class="info-row">下单时间：{{ order.orderTime }}</div>
        <div class="info-row" v-if="order.remark">备注：{{ order.remark }}</div>
        <div class="info-row amount-row">实收金额：<span class="amount">¥{{ order.amount }}</span></div>
      </section>

      <div class="actions">
        <el-button v-if="order.status === 1" type="primary" @click="goPay">去支付</el-button>
        <el-button v-if="[2, 3, 4].includes(order.status)" @click="handleReminder">催单</el-button>
        <el-button v-if="order.status === 1 || order.status === 2" @click="handleCancel">
          取消订单
        </el-button>
        <el-button v-if="[5, 6].includes(order.status)" @click="handleRepeat">再来一单</el-button>
        <el-button @click="callShop">联系商家</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  getOrderDetail,
  cancelOrder,
  reminderOrder,
  repetitionOrder,
} from '../api/order'
import { getShopPhone } from '../api/shop'
import { useCartStore } from '../store/cart'
import { useOrderStore } from '../store/order'
import { DISH_PLACEHOLDER, onImageError } from '../utils/image'

const STATUS_MAP = {
  1: '待付款',
  2: '待接单',
  3: '商家已接单',
  4: '派送中',
  5: '已完成',
  6: '已取消',
}
const PAY_WINDOW_SECONDS = 15 * 60

const props = defineProps({ id: { type: [String, Number], required: true } })
const route = useRoute()
const router = useRouter()
const cartStore = useCartStore()
const orderStore = useOrderStore()

const order = ref(null)
const loading = ref(false)
const shopPhone = ref('')
const remainSeconds = ref(PAY_WINDOW_SECONDS)
let timer = null

const statusText = computed(() => (order.value ? STATUS_MAP[order.value.status] : ''))
const countdownText = computed(() => {
  const m = Math.floor(remainSeconds.value / 60)
  const s = remainSeconds.value % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
})

async function loadDetail() {
  loading.value = true
  try {
    const res = await getOrderDetail(route.params.id)
    order.value = res.data
    if (order.value.status === 1) startCountdown()
  } finally {
    loading.value = false
  }
}

function startCountdown() {
  const orderTime = new Date(order.value.orderTime.replace(/-/g, '/')).getTime()
  timer = setInterval(() => {
    const elapsed = Math.floor((Date.now() - orderTime) / 1000)
    const remain = PAY_WINDOW_SECONDS - elapsed
    if (remain <= 0) {
      remainSeconds.value = 0
      clearInterval(timer)
    } else {
      remainSeconds.value = remain
    }
  }, 1000)
}

function goPay() {
  orderStore.setPendingOrder({
    id: order.value.id,
    orderNumber: order.value.number,
    orderAmount: order.value.amount,
    orderTime: order.value.orderTime,
  })
  router.push('/pay')
}

async function handleReminder() {
  await reminderOrder(order.value.id)
  ElMessage.success('已提醒商家')
}

async function handleCancel() {
  await ElMessageBox.confirm('确认取消该订单吗？', '提示', { type: 'warning' })
  await cancelOrder(order.value.id)
  ElMessage.success('订单已取消')
  loadDetail()
}

async function handleRepeat() {
  await repetitionOrder(order.value.id)
  await cartStore.refresh()
  ElMessage.success('已加入购物车')
  router.push('/')
}

async function callShop() {
  if (!shopPhone.value) {
    const res = await getShopPhone()
    shopPhone.value = res.data
  }
  ElMessageBox.alert(shopPhone.value, '商家联系电话')
}

onMounted(() => {
  loadDetail()
})
onBeforeUnmount(() => {
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.detail-page {
  min-height: 100%;
  background: #f8f8f8;
}
.page-header {
  height: 56px;
  background: #fff;
  display: flex;
  align-items: center;
  padding: 0 24px;
  gap: 16px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}
.title {
  font-weight: 600;
}
.content {
  max-width: 720px;
  margin: 16px auto;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 0 16px 24px;
}
.card {
  background: #fff;
  border-radius: 8px;
  padding: 16px 20px;
}
.status-card {
  text-align: center;
  padding: 24px;
}
.status-text {
  font-size: 20px;
  font-weight: 700;
  color: var(--brand-primary);
}
.countdown {
  margin-top: 8px;
  color: #666;
  font-size: 13px;
}
.time {
  color: #f56c6c;
  font-weight: 600;
}
.card-title {
  font-weight: 600;
  margin-bottom: 12px;
}
.info-row {
  color: #666;
  font-size: 13px;
  line-height: 1.8;
}
.amount-row {
  margin-top: 8px;
}
.amount {
  color: #ff6600;
  font-weight: 700;
}
.dish-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px solid #f5f5f5;
}
.dish-row img {
  width: 44px;
  height: 44px;
  border-radius: 6px;
  object-fit: cover;
  background: #f0f0f0;
}
.dish-row-info {
  flex: 1;
}
.flavor {
  font-size: 11px;
  color: #999;
}
.dish-row-amount {
  color: #ff6600;
  min-width: 70px;
  text-align: right;
}
.actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}
</style>
