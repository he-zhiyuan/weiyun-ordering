<template>
  <div v-if="cartStore.list.length > 0" class="cart-bar-wrapper">
    <transition name="el-zoom-in-bottom">
      <div v-if="expanded" class="cart-panel">
        <div class="cart-panel-header">
          <span>购物车</span>
          <el-button link type="danger" @click="handleClear">清空</el-button>
        </div>
        <div class="cart-panel-list">
          <div v-for="line in cartStore.list" :key="line.id" class="cart-line">
            <img :src="line.image || DISH_PLACEHOLDER" @error="onImageError" />
            <div class="cart-line-info">
              <div class="cart-line-name">{{ line.name }}</div>
              <div v-if="line.dishFlavor" class="cart-line-flavor">{{ line.dishFlavor }}</div>
              <div class="cart-line-price">¥{{ line.amount }}</div>
            </div>
            <div class="stepper">
              <el-button circle size="small" :icon="Minus" @click="handleSub(line)" />
              <span class="qty">{{ line.number }}</span>
              <el-button circle size="small" type="primary" :icon="Plus" @click="handleAdd(line)" />
            </div>
          </div>
        </div>
      </div>
    </transition>

    <div class="cart-bar">
      <div class="cart-bar-left" @click="expanded = !expanded">
        <el-badge :value="cartStore.totalCount" :max="99">
          <el-icon :size="28"><ShoppingCart /></el-icon>
        </el-badge>
        <span class="total-amount">¥{{ cartStore.totalAmount.toFixed(2) }}</span>
      </div>
      <el-button
        type="primary"
        size="large"
        class="checkout-btn"
        :disabled="!shopOpen"
        @click="handleCheckout"
      >
        {{ shopOpen ? '去结算' : '店铺已打烊' }}
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { inject, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessageBox, ElMessage } from 'element-plus'
import { Plus, Minus, ShoppingCart } from '@element-plus/icons-vue'
import { addToCart, subCart, cleanCart } from '../api/cart'
import { useCartStore } from '../store/cart'
import { DISH_PLACEHOLDER, onImageError } from '../utils/image'

const router = useRouter()
const cartStore = useCartStore()
const expanded = ref(false)
const shopOpen = inject('shopOpen', ref(true))

async function handleAdd(line) {
  await addToCart({ dishId: line.dishId, setmealId: line.setmealId, dishFlavor: line.dishFlavor })
  await cartStore.refresh()
}

async function handleSub(line) {
  await subCart({ dishId: line.dishId, setmealId: line.setmealId, dishFlavor: line.dishFlavor })
  await cartStore.refresh()
}

async function handleClear() {
  await ElMessageBox.confirm('确认清空购物车吗？', '提示', { type: 'warning' })
  await cleanCart()
  await cartStore.refresh()
  expanded.value = false
}

function handleCheckout() {
  if (!shopOpen.value) {
    ElMessage.warning('店铺已打烊，暂不可下单')
    return
  }
  router.push('/checkout')
}
</script>

<style scoped>
.cart-bar-wrapper {
  position: fixed;
  right: 32px;
  bottom: 24px;
  z-index: 100;
  width: 380px;
}
.cart-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #2c2c2c;
  border-radius: 32px;
  padding: 8px 8px 8px 24px;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.25);
}
.cart-bar-left {
  display: flex;
  align-items: center;
  gap: 16px;
  color: #fff;
  cursor: pointer;
}
.total-amount {
  font-size: 18px;
  font-weight: 600;
}
.checkout-btn {
  border-radius: 24px;
  padding: 0 28px;
}
.cart-panel {
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
  margin-bottom: 12px;
  max-height: 400px;
  display: flex;
  flex-direction: column;
}
.cart-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid #f0f0f0;
  font-weight: 600;
}
.cart-panel-list {
  overflow-y: auto;
  padding: 8px 16px;
}
.cart-line {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 0;
  border-bottom: 1px solid #f5f5f5;
}
.cart-line img {
  width: 44px;
  height: 44px;
  border-radius: 6px;
  object-fit: cover;
  background: #f0f0f0;
}
.cart-line-info {
  flex: 1;
  min-width: 0;
}
.cart-line-name {
  font-size: 13px;
  color: #333;
}
.cart-line-flavor {
  font-size: 11px;
  color: #999;
}
.cart-line-price {
  font-size: 13px;
  color: #ff6600;
}
.stepper {
  display: flex;
  align-items: center;
  gap: 6px;
}
.qty {
  min-width: 16px;
  text-align: center;
}
</style>
