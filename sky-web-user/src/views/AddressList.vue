<template>
  <div class="address-page">
    <header class="page-header">
      <el-button link @click="router.back()">&lt; 返回</el-button>
      <span class="title">地址管理</span>
    </header>

    <div class="content" v-loading="loading">
      <el-empty v-if="!loading && addresses.length === 0" description="暂无收货地址" />
      <div v-for="addr in addresses" :key="addr.id" class="address-card">
        <div class="address-main">
          <span class="consignee">{{ addr.consignee }}</span>
          <span class="phone">{{ addr.phone }}</span>
          <el-tag v-if="addr.isDefault === 1" size="small" type="warning">默认</el-tag>
        </div>
        <div class="address-detail">
          {{ addr.provinceName }}{{ addr.cityName }}{{ addr.districtName }}{{ addr.detail }}
        </div>
        <div class="address-actions">
          <el-button
            v-if="addr.isDefault !== 1"
            size="small"
            @click="handleSetDefault(addr)"
          >
            设为默认
          </el-button>
          <el-button size="small" @click="goEdit(addr.id)">编辑</el-button>
          <el-button size="small" type="danger" @click="handleDelete(addr.id)">删除</el-button>
        </div>
      </div>

      <el-button type="primary" class="add-btn" @click="goEdit()">+ 新增收货地址</el-button>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { getAddressList, deleteAddress, setDefaultAddress } from '../api/address'

const router = useRouter()
const addresses = ref([])
const loading = ref(false)

async function loadAddresses() {
  loading.value = true
  try {
    const res = await getAddressList()
    addresses.value = res.data || []
  } finally {
    loading.value = false
  }
}

function goEdit(id) {
  router.push(id ? { path: '/address/edit', query: { id } } : { path: '/address/edit' })
}

async function handleSetDefault(addr) {
  await setDefaultAddress({ ...addr, isDefault: 1 })
  ElMessage.success('已设为默认地址')
  loadAddresses()
}

async function handleDelete(id) {
  await ElMessageBox.confirm('确认删除该地址吗？', '提示', { type: 'warning' })
  await deleteAddress(id)
  ElMessage.success('删除成功')
  loadAddresses()
}

onMounted(() => {
  loadAddresses()
})
</script>

<style scoped>
.address-page {
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
  max-width: 640px;
  margin: 16px auto;
  padding: 0 16px;
}
.address-card {
  background: #fff;
  border-radius: 8px;
  padding: 16px 20px;
  margin-bottom: 12px;
}
.address-main {
  display: flex;
  align-items: center;
  gap: 12px;
  font-weight: 600;
}
.address-detail {
  color: #666;
  font-size: 13px;
  margin-top: 8px;
}
.address-actions {
  margin-top: 12px;
  display: flex;
  gap: 8px;
  justify-content: flex-end;
}
.add-btn {
  width: 100%;
  margin-top: 12px;
}
</style>
