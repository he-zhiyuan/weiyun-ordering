<template>
  <el-dialog v-model="visible" title="选择口味" width="420px" @closed="onClosed">
    <div v-if="dish" class="flavor-body">
      <div class="dish-brief">
        <img :src="dish.image" />
        <div>
          <div class="name">{{ dish.name }}</div>
          <div class="price">¥{{ dish.price }}</div>
        </div>
      </div>
      <div v-for="flavor in flavorOptions" :key="flavor.name" class="flavor-group">
        <div class="flavor-name">{{ flavor.name }}</div>
        <el-radio-group v-model="selections[flavor.name]">
          <el-radio-button v-for="opt in flavor.options" :key="opt" :label="opt" :value="opt">
            {{ opt }}
          </el-radio-button>
        </el-radio-group>
      </div>
    </div>
    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" :loading="loading" @click="handleConfirm">加入购物车</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed, reactive, ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { addToCart } from '../api/cart'
import { useCartStore } from '../store/cart'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  dish: { type: Object, default: null },
})
const emit = defineEmits(['update:modelValue', 'success'])

const cartStore = useCartStore()
const loading = ref(false)
const selections = reactive({})

const visible = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const flavorOptions = computed(() => {
  if (!props.dish || !props.dish.flavors) return []
  return props.dish.flavors.map((f) => {
    let options = []
    try {
      options = JSON.parse(f.value)
    } catch (e) {
      options = []
    }
    return { name: f.name, options }
  })
})

watch(
  () => props.dish,
  (dish) => {
    Object.keys(selections).forEach((key) => delete selections[key])
    if (!dish || !dish.flavors) return
    dish.flavors.forEach((f) => {
      let options = []
      try {
        options = JSON.parse(f.value)
      } catch (e) {
        options = []
      }
      if (options.length) selections[f.name] = options[0]
    })
  },
  { immediate: true },
)

function onClosed() {
  loading.value = false
}

async function handleConfirm() {
  if (!props.dish) return
  const dishFlavor = Object.entries(selections)
    .map(([name, value]) => `${name}:${value}`)
    .join(';')
  loading.value = true
  try {
    await addToCart({ dishId: props.dish.id, dishFlavor })
    await cartStore.refresh()
    ElMessage.success('已加入购物车')
    visible.value = false
    emit('success')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.dish-brief {
  display: flex;
  gap: 12px;
  margin-bottom: 16px;
  align-items: center;
}
.dish-brief img {
  width: 64px;
  height: 64px;
  border-radius: 8px;
  object-fit: cover;
}
.dish-brief .name {
  font-size: 16px;
  font-weight: 600;
}
.dish-brief .price {
  color: #ff6600;
  margin-top: 4px;
}
.flavor-group {
  margin-bottom: 16px;
}
.flavor-name {
  font-size: 13px;
  color: #666;
  margin-bottom: 8px;
}
</style>
