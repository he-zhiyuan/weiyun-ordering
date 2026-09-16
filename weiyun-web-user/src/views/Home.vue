<template>
  <div class="home">
    <header class="navbar">
      <div class="brand">味云点餐</div>
      <div class="shop-status">
        <el-tag :type="shopOpen ? 'success' : 'info'" effect="dark">
          {{ shopOpen ? '营业中' : '已打烊' }}
        </el-tag>
        <span class="phone">客服电话：{{ shopPhone }}</span>
      </div>
      <div class="nav-actions">
        <span class="greeting">你好，{{ userStore.name || userStore.phone }}</span>
        <el-button link @click="router.push('/orders')">我的订单</el-button>
        <el-button link @click="router.push('/address')">地址管理</el-button>
        <el-button link @click="router.push('/profile')">个人中心</el-button>
        <el-button link @click="handleLogout">退出登录</el-button>
      </div>
    </header>

    <div class="body">
      <aside class="category-list">
        <div
          v-for="cat in categories"
          :key="cat.id"
          class="category-item"
          :class="{ active: cat.id === activeCategoryId }"
          @click="handleSelectCategory(cat)"
        >
          {{ cat.name }}
        </div>
      </aside>

      <main class="dish-grid" v-loading="loading">
        <el-empty v-if="!loading && items.length === 0" description="该分类暂无商品" />
        <DishCard
          v-for="item in items"
          :key="item.id"
          :item="item"
          :type="activeCategoryType === 1 ? 'dish' : 'setmeal'"
        />
      </main>
    </div>

    <CartBar />
  </div>
</template>

<script setup>
import { onMounted, provide, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getCategoryList } from '../api/category'
import { getDishList } from '../api/dish'
import { getSetmealList } from '../api/setmeal'
import { getShopStatus, getShopPhone } from '../api/shop'
import { useUserStore } from '../store/user'
import { useCartStore } from '../store/cart'
import DishCard from '../components/DishCard.vue'
import CartBar from '../components/CartBar.vue'

const router = useRouter()
const userStore = useUserStore()
const cartStore = useCartStore()

const categories = ref([])
const activeCategoryId = ref(null)
const activeCategoryType = ref(1)
const items = ref([])
const loading = ref(false)
const shopOpen = ref(true)
const shopPhone = ref('')

provide('shopOpen', shopOpen)

async function loadCategories() {
  const res = await getCategoryList()
  categories.value = res.data || []
  if (categories.value.length > 0) {
    handleSelectCategory(categories.value[0])
  }
}

async function handleSelectCategory(cat) {
  activeCategoryId.value = cat.id
  activeCategoryType.value = cat.type
  loading.value = true
  try {
    if (cat.type === 1) {
      const res = await getDishList(cat.id)
      items.value = res.data || []
    } else {
      const res = await getSetmealList(cat.id)
      items.value = res.data || []
    }
  } finally {
    loading.value = false
  }
}

async function loadShopStatus() {
  const res = await getShopStatus()
  shopOpen.value = res.data === 1
}

async function loadShopPhone() {
  const res = await getShopPhone()
  shopPhone.value = res.data
}

async function handleLogout() {
  await ElMessageBox.confirm('确认退出登录吗？', '提示', { type: 'warning' })
  userStore.logout()
  cartStore.clear()
  ElMessage.success('已退出登录')
  router.replace('/login')
}

onMounted(() => {
  loadCategories()
  loadShopStatus()
  loadShopPhone()
  cartStore.refresh()
})
</script>

<style scoped>
.home {
  min-height: 100%;
  background: #f8f8f8;
}
.navbar {
  height: 64px;
  background: #fff;
  display: flex;
  align-items: center;
  padding: 0 32px;
  gap: 24px;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
  position: sticky;
  top: 0;
  z-index: 10;
}
.brand {
  font-size: 20px;
  font-weight: 700;
  color: var(--brand-primary);
}
.shop-status {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #666;
  font-size: 13px;
}
.nav-actions {
  margin-left: auto;
  display: flex;
  align-items: center;
  gap: 8px;
}
.greeting {
  color: #666;
  margin-right: 8px;
  font-size: 13px;
}
.body {
  display: flex;
  max-width: 1200px;
  margin: 0 auto;
  gap: 16px;
  padding: 16px;
}
.category-list {
  width: 160px;
  flex-shrink: 0;
  background: #fff;
  border-radius: 8px;
  overflow: hidden;
}
.category-item {
  padding: 14px 16px;
  cursor: pointer;
  font-size: 14px;
  color: #333;
  border-left: 3px solid transparent;
}
.category-item:hover {
  background: #f5f5f5;
}
.category-item.active {
  background: #eaf2fc;
  color: var(--brand-primary);
  font-weight: 600;
  border-left-color: var(--brand-primary);
}
.dish-grid {
  flex: 1;
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  align-content: start;
  min-height: 300px;
}
</style>
