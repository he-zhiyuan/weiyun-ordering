<template>
  <div class="history-page">
    <header class="page-header">
      <el-button link @click="router.push('/')">&lt; 首页</el-button>
      <span class="title">我的订单</span>
    </header>

    <div class="content">
      <el-tabs v-model="activeStatus" @tab-change="handleTabChange">
        <el-tab-pane v-for="tab in tabs" :key="tab.value" :label="tab.label" :name="tab.value" />
      </el-tabs>

      <div v-loading="loading">
        <el-empty v-if="!loading && orders.length === 0" description="暂无订单" />
        <div v-for="order in orders" :key="order.id" class="order-card">
          <div class="order-card-header">
            <span class="order-number">订单号：{{ order.number }}</span>
            <span class="status" :class="'status-' + order.status">{{ statusText(order.status) }}</span>
          </div>
          <div class="order-dishes">{{ order.orderDishes }}</div>
          <div class="order-card-footer">
            <span class="order-time">{{ order.orderTime }}</span>
            <span class="order-amount">¥{{ order.amount }}</span>
          </div>
          <div class="order-actions">
            <el-button size="small" @click="goDetail(order.id)">查看详情</el-button>
            <el-button v-if="order.status === 1" size="small" type="primary" @click="goPay(order)">
              去支付
            </el-button>
            <el-button
              v-if="[2, 3, 4].includes(order.status)"
              size="small"
              @click="handleReminder(order.id)"
            >
              催单
            </el-button>
            <el-button
              v-if="order.status === 1 || order.status === 2"
              size="small"
              @click="handleCancel(order.id)"
            >
              取消订单
            </el-button>
            <el-button
              v-if="[5, 6].includes(order.status)"
              size="small"
              @click="handleRepeat(order.id)"
            >
              再来一单
            </el-button>
          </div>
        </div>

        <el-pagination
          v-if="total > pageSize"
          v-model:current-page="page"
          :page-size="pageSize"
          :total="total"
          layout="prev, pager, next"
          @current-change="loadOrders"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import {
  getHistoryOrders,
  cancelOrder,
  reminderOrder,
  repetitionOrder,
} from '../api/order'
import { useCartStore } from '../store/cart'
import { useOrderStore } from '../store/order'

const STATUS_MAP = {
  1: '待付款',
  2: '待接单',
  3: '已接单',
  4: '派送中',
  5: '已完成',
  6: '已取消',
}

const tabs = [
  { label: '全部', value: 0 },
  { label: '待付款', value: 1 },
  { label: '待接单', value: 2 },
  { label: '派送中', value: 4 },
  { label: '已完成', value: 5 },
  { label: '已取消', value: 6 },
]

const router = useRouter()
const cartStore = useCartStore()
const orderStore = useOrderStore()

const activeStatus = ref(0)
const orders = ref([])
const loading = ref(false)
const page = ref(1)
const pageSize = 10
const total = ref(0)

function statusText(status) {
  return STATUS_MAP[status] || '未知状态'
}

async function loadOrders() {
  loading.value = true
  try {
    const res = await getHistoryOrders({
      page: page.value,
      pageSize,
      status: activeStatus.value || undefined,
    })
    orders.value = res.data.records || []
    total.value = res.data.total || 0
  } finally {
    loading.value = false
  }
}

function handleTabChange() {
  page.value = 1
  loadOrders()
}

function goDetail(id) {
  router.push(`/order/${id}`)
}

function goPay(order) {
  orderStore.setPendingOrder({
    id: order.id,
    orderNumber: order.number,
    orderAmount: order.amount,
    orderTime: order.orderTime,
  })
  router.push('/pay')
}

async function handleReminder(id) {
  await reminderOrder(id)
  ElMessage.success('已提醒商家')
}

async function handleCancel(id) {
  await ElMessageBox.confirm('确认取消该订单吗？', '提示', { type: 'warning' })
  await cancelOrder(id)
  ElMessage.success('订单已取消')
  loadOrders()
}

async function handleRepeat(id) {
  await repetitionOrder(id)
  await cartStore.refresh()
  ElMessage.success('已加入购物车')
  router.push('/')
}

onMounted(() => {
  loadOrders()
})
</script>

<style scoped>
.history-page {
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
  padding: 0 16px;
}
.order-card {
  background: #fff;
  border-radius: 8px;
  padding: 16px 20px;
  margin-bottom: 12px;
}
.order-card-header {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: #666;
}
.status {
  font-weight: 600;
}
.status-1 {
  color: #f56c6c;
}
.status-2,
.status-3,
.status-4 {
  color: #ff9800;
}
.status-5 {
  color: #67c23a;
}
.status-6 {
  color: #999;
}
.order-dishes {
  margin: 12px 0;
  color: #333;
  font-size: 14px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.order-card-footer {
  display: flex;
  justify-content: space-between;
  color: #999;
  font-size: 12px;
}
.order-amount {
  color: #ff6600;
  font-weight: 600;
}
.order-actions {
  margin-top: 12px;
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}
</style>
