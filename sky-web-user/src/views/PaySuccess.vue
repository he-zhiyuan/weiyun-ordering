<template>
  <div class="success-page">
    <div class="success-card">
      <el-icon :size="64" color="#67c23a"><CircleCheckFilled /></el-icon>
      <h2>支付成功</h2>
      <p>商家正在努力备餐，请耐心等待</p>
      <div class="actions">
        <el-button @click="router.push('/')">返回首页</el-button>
        <el-button type="primary" @click="goDetail">查看订单</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useRoute, useRouter } from 'vue-router'
import { CircleCheckFilled } from '@element-plus/icons-vue'

const route = useRoute()
const router = useRouter()

function goDetail() {
  const id = route.query.id
  if (id) {
    router.push(`/order/${id}`)
  } else {
    router.push('/orders')
  }
}
</script>

<style scoped>
.success-page {
  min-height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8f8f8;
}
.success-card {
  width: 400px;
  background: #fff;
  border-radius: 12px;
  padding: 48px 32px;
  text-align: center;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.08);
}
.success-card h2 {
  margin: 16px 0 8px;
}
.success-card p {
  color: #999;
  font-size: 13px;
}
.actions {
  margin-top: 24px;
  display: flex;
  gap: 12px;
  justify-content: center;
}
</style>
