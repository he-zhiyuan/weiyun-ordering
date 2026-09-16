<template>
  <div class="checkout-page">
    <header class="page-header">
      <el-button link @click="router.back()">&lt; 返回</el-button>
      <span class="title">确认订单</span>
    </header>

    <div class="content">
      <section class="card">
        <div class="card-title">收货地址</div>
        <div v-if="addresses.length === 0" class="empty-address">
          <span>暂无收货地址</span>
          <el-button type="primary" link @click="goAddAddress">去添加</el-button>
        </div>
        <el-radio-group v-else v-model="selectedAddressId" class="address-list">
          <el-radio
            v-for="addr in addresses"
            :key="addr.id"
            :value="addr.id"
            class="address-item"
          >
            <div class="address-main">
              <span class="consignee">{{ addr.consignee }} {{ addr.sex === '1' ? '先生' : '女士' }}</span>
              <span class="phone">{{ addr.phone }}</span>
              <el-tag v-if="addr.isDefault === 1" size="small" type="warning">默认</el-tag>
            </div>
            <div class="address-detail">
              {{ addr.provinceName }}{{ addr.cityName }}{{ addr.districtName }}{{ addr.detail }}
            </div>
          </el-radio>
        </el-radio-group>
        <el-button link type="primary" @click="goAddAddress">+ 新增收货地址</el-button>
      </section>

      <section class="card">
        <div class="card-title">商品清单</div>
        <div v-for="line in cartStore.list" :key="line.id" class="dish-row">
          <img :src="line.image || DISH_PLACEHOLDER" @error="onImageError" />
          <div class="dish-row-info">
            <div>{{ line.name }}</div>
            <div v-if="line.dishFlavor" class="flavor">{{ line.dishFlavor }}</div>
          </div>
          <div class="dish-row-qty">x{{ line.number }}</div>
          <div class="dish-row-amount">¥{{ (line.amount * line.number).toFixed(2) }}</div>
        </div>
      </section>

      <section class="card">
        <div class="card-title">配送时间</div>
        <el-radio-group v-model="orderStore.deliveryStatus">
          <el-radio :value="1">立即送出</el-radio>
          <el-radio :value="0">选择时间</el-radio>
        </el-radio-group>
        <el-date-picker
          v-if="orderStore.deliveryStatus === 0"
          v-model="orderStore.estimatedDeliveryTime"
          type="datetime"
          value-format="YYYY-MM-DD HH:mm:ss"
          placeholder="选择预计送达时间"
          style="margin-top: 8px; width: 100%"
        />
      </section>

      <section class="card row-card">
        <span class="row-label">餐具数量</span>
        <el-radio-group v-model="orderStore.tablewareStatus">
          <el-radio :value="1">按餐量提供</el-radio>
          <el-radio :value="0">选择数量</el-radio>
        </el-radio-group>
        <el-input-number
          v-if="orderStore.tablewareStatus === 0"
          v-model="orderStore.tablewareNumber"
          :min="1"
          :max="10"
          size="small"
        />
      </section>

      <section class="card row-card clickable" @click="remarkVisible = true">
        <span class="row-label">备注</span>
        <span class="row-value">{{ orderStore.remark || '添加备注' }} &gt;</span>
      </section>
    </div>

    <footer class="checkout-footer">
      <div class="amount-summary">
        <span>合计：</span>
        <span class="total">¥{{ totalAmount.toFixed(2) }}</span>
        <span class="breakdown">(含配送费¥{{ deliveryFee.toFixed(2) }}，打包费¥{{ packFee.toFixed(2) }})</span>
      </div>
      <el-button type="primary" size="large" :loading="submitting" @click="handleSubmit">
        提交订单
      </el-button>
    </footer>

    <RemarkDialog
      v-model="remarkVisible"
      :remark="orderStore.remark"
      @confirm="(val) => (orderStore.remark = val)"
    />
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { getAddressList } from '../api/address'
import { submitOrder } from '../api/order'
import { useCartStore } from '../store/cart'
import { useOrderStore } from '../store/order'
import { DISH_PLACEHOLDER, onImageError } from '../utils/image'
import RemarkDialog from '../components/RemarkDialog.vue'

const DELIVERY_FEE = 6

const router = useRouter()
const cartStore = useCartStore()
const orderStore = useOrderStore()

const addresses = ref([])
const selectedAddressId = ref(null)
const remarkVisible = ref(false)
const submitting = ref(false)

const deliveryFee = computed(() => DELIVERY_FEE)
const packFee = computed(() => orderStore.packAmount * cartStore.totalCount)
const totalAmount = computed(() => cartStore.totalAmount + deliveryFee.value + packFee.value)

async function loadAddresses() {
  const res = await getAddressList()
  addresses.value = res.data || []
  const defaultAddr = addresses.value.find((a) => a.isDefault === 1)
  selectedAddressId.value = defaultAddr ? defaultAddr.id : addresses.value[0]?.id || null
}

function goAddAddress() {
  router.push('/address/edit')
}

async function handleSubmit() {
  if (!selectedAddressId.value) {
    ElMessage.warning('请先选择收货地址')
    return
  }
  if (cartStore.list.length === 0) {
    ElMessage.warning('购物车为空')
    return
  }
  if (orderStore.deliveryStatus === 0 && !orderStore.estimatedDeliveryTime) {
    ElMessage.warning('请选择预计送达时间')
    return
  }
  submitting.value = true
  try {
    const res = await submitOrder({
      addressBookId: selectedAddressId.value,
      payMethod: 1,
      remark: orderStore.remark,
      estimatedDeliveryTime:
        orderStore.deliveryStatus === 0 ? orderStore.estimatedDeliveryTime : undefined,
      deliveryStatus: orderStore.deliveryStatus,
      tablewareNumber:
        orderStore.tablewareStatus === 1 ? cartStore.totalCount : orderStore.tablewareNumber,
      tablewareStatus: orderStore.tablewareStatus,
      packAmount: orderStore.packAmount,
      amount: totalAmount.value,
    })
    orderStore.setPendingOrder(res.data)
    orderStore.resetCheckoutForm()
    await cartStore.refresh()
    router.replace('/pay')
  } finally {
    submitting.value = false
  }
}

onMounted(() => {
  loadAddresses()
})
</script>

<style scoped>
.checkout-page {
  min-height: 100%;
  background: #f8f8f8;
  padding-bottom: 90px;
}
.page-header {
  height: 56px;
  background: #fff;
  display: flex;
  align-items: center;
  padding: 0 24px;
  gap: 16px;
  position: sticky;
  top: 0;
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
}
.card {
  background: #fff;
  border-radius: 8px;
  padding: 16px 20px;
}
.card-title {
  font-weight: 600;
  margin-bottom: 12px;
}
.empty-address {
  display: flex;
  align-items: center;
  gap: 12px;
  color: #999;
}
.address-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.address-item {
  align-items: flex-start;
  height: auto;
  padding: 8px 0;
  white-space: normal;
}
.address-main {
  display: flex;
  align-items: center;
  gap: 8px;
}
.address-detail {
  color: #999;
  font-size: 12px;
  margin-top: 4px;
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
.row-card {
  display: flex;
  align-items: center;
  gap: 16px;
}
.row-card.clickable {
  justify-content: space-between;
  cursor: pointer;
}
.row-label {
  font-weight: 600;
}
.row-value {
  color: #999;
}
.checkout-footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 72px;
  background: #fff;
  box-shadow: 0 -2px 8px rgba(0, 0, 0, 0.08);
  display: flex;
  align-items: center;
  justify-content: flex-end;
  padding: 0 32px;
  gap: 24px;
}
.amount-summary {
  color: #333;
}
.total {
  color: #ff6600;
  font-size: 20px;
  font-weight: 700;
  margin: 0 8px;
}
.breakdown {
  font-size: 12px;
  color: #999;
}
</style>
