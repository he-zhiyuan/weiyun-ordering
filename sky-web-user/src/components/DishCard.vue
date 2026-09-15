<template>
  <div class="dish-card">
    <img class="thumb" :src="item.image" />
    <div class="info">
      <div class="name">{{ item.name }}</div>
      <div class="desc">{{ item.description }}</div>
      <div v-if="type === 'setmeal'" class="setmeal-link" @click="showDetail = true">
        查看套餐内容 &gt;
      </div>
      <div class="bottom">
        <span class="price">¥{{ item.price }}</span>
        <div class="stepper">
          <el-button
            v-if="qty > 0"
            circle
            size="small"
            :icon="Minus"
            @click="handleSub"
          />
          <span v-if="qty > 0" class="qty">{{ qty }}</span>
          <el-button circle size="small" type="primary" :icon="Plus" @click="handleAdd" />
        </div>
      </div>
    </div>

    <FlavorPicker v-if="type === 'dish'" v-model="pickerVisible" :dish="item" />

    <el-dialog v-if="type === 'setmeal'" v-model="showDetail" title="套餐详情" width="420px">
      <div v-for="d in setmealDishes" :key="d.name" class="setmeal-dish-row">
        <img :src="d.image" />
        <div class="setmeal-dish-info">
          <div>{{ d.name }} x{{ d.copies }}</div>
          <div class="setmeal-dish-desc">{{ d.description }}</div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import { Plus, Minus } from '@element-plus/icons-vue'
import { addToCart, subCart } from '../api/cart'
import { getSetmealDishes } from '../api/setmeal'
import { useCartStore } from '../store/cart'
import FlavorPicker from './FlavorPicker.vue'

const props = defineProps({
  item: { type: Object, required: true },
  type: { type: String, default: 'dish' }, // 'dish' | 'setmeal'
})

const cartStore = useCartStore()
const pickerVisible = ref(false)
const showDetail = ref(false)
const setmealDishes = ref([])

const cartLines = computed(() =>
  cartStore.list.filter((line) =>
    props.type === 'dish' ? line.dishId === props.item.id : line.setmealId === props.item.id,
  ),
)
const qty = computed(() => cartLines.value.reduce((sum, l) => sum + l.number, 0))

watch(showDetail, async (val) => {
  if (val && setmealDishes.value.length === 0) {
    const res = await getSetmealDishes(props.item.id)
    setmealDishes.value = res.data || []
  }
})

async function handleAdd() {
  if (props.type === 'dish' && props.item.flavors && props.item.flavors.length > 0) {
    pickerVisible.value = true
    return
  }
  const payload =
    props.type === 'dish' ? { dishId: props.item.id } : { setmealId: props.item.id }
  await addToCart(payload)
  await cartStore.refresh()
}

async function handleSub() {
  if (cartLines.value.length === 0) return
  const line = cartLines.value[cartLines.value.length - 1]
  await subCart({
    dishId: line.dishId,
    setmealId: line.setmealId,
    dishFlavor: line.dishFlavor,
  })
  await cartStore.refresh()
}
</script>

<style scoped>
.dish-card {
  display: flex;
  gap: 12px;
  padding: 16px;
  background: #fff;
  border-radius: 8px;
}
.thumb {
  width: 96px;
  height: 96px;
  border-radius: 8px;
  object-fit: cover;
  flex-shrink: 0;
  background: #f0f0f0;
}
.info {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.name {
  font-size: 15px;
  font-weight: 600;
  color: #333;
}
.desc {
  font-size: 12px;
  color: #999;
  margin-top: 4px;
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}
.setmeal-link {
  font-size: 12px;
  color: #ff9800;
  cursor: pointer;
  margin-top: 4px;
}
.bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
}
.price {
  color: #ff6600;
  font-size: 16px;
  font-weight: 600;
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
.setmeal-dish-row {
  display: flex;
  gap: 12px;
  margin-bottom: 12px;
}
.setmeal-dish-row img {
  width: 56px;
  height: 56px;
  border-radius: 6px;
  object-fit: cover;
}
.setmeal-dish-desc {
  font-size: 12px;
  color: #999;
}
</style>
