<template>
  <div class="profile-page">
    <header class="page-header">
      <el-button link @click="router.push('/')">&lt; 首页</el-button>
      <span class="title">个人中心</span>
    </header>

    <div class="content">
      <section class="card user-card">
        <el-avatar :size="64">{{ (userStore.name || userStore.phone || '用').slice(0, 1) }}</el-avatar>
        <div class="user-info">
          <div class="name">{{ userStore.name || '未设置昵称' }}</div>
          <div class="phone">{{ userStore.phone }}</div>
        </div>
      </section>

      <section class="card menu-card">
        <div class="menu-item" @click="router.push('/orders')">
          <span>我的订单</span>
          <span class="arrow">&gt;</span>
        </div>
        <div class="menu-item" @click="router.push('/address')">
          <span>地址管理</span>
          <span class="arrow">&gt;</span>
        </div>
        <div class="menu-item" @click="router.push('/')">
          <span>去点餐</span>
          <span class="arrow">&gt;</span>
        </div>
      </section>

      <el-button class="logout-btn" @click="handleLogout">退出登录</el-button>
    </div>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { useUserStore } from '../store/user'
import { useCartStore } from '../store/cart'

const router = useRouter()
const userStore = useUserStore()
const cartStore = useCartStore()

async function handleLogout() {
  await ElMessageBox.confirm('确认退出登录吗？', '提示', { type: 'warning' })
  userStore.logout()
  cartStore.clear()
  ElMessage.success('已退出登录')
  router.replace('/login')
}
</script>

<style scoped>
.profile-page {
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
  max-width: 480px;
  margin: 16px auto;
  padding: 0 16px;
}
.card {
  background: #fff;
  border-radius: 8px;
  margin-bottom: 12px;
}
.user-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 24px;
}
.user-info .name {
  font-size: 18px;
  font-weight: 600;
}
.user-info .phone {
  color: #999;
  margin-top: 4px;
}
.menu-item {
  display: flex;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f5f5f5;
  cursor: pointer;
}
.menu-item:last-child {
  border-bottom: none;
}
.arrow {
  color: #ccc;
}
.logout-btn {
  width: 100%;
}
</style>
