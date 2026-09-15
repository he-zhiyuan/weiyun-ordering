<template>
  <el-dialog v-model="visible" title="订单备注" width="420px">
    <div class="quick-tags">
      <el-tag
        v-for="tag in presets"
        :key="tag"
        class="tag-item"
        :effect="draft.includes(tag) ? 'dark' : 'plain'"
        @click="toggleTag(tag)"
      >
        {{ tag }}
      </el-tag>
    </div>
    <el-input
      v-model="draft"
      type="textarea"
      :rows="3"
      maxlength="50"
      show-word-limit
      placeholder="请输入备注信息"
    />
    <template #footer>
      <el-button @click="visible = false">取消</el-button>
      <el-button type="primary" @click="handleConfirm">确定</el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed, ref, watch } from 'vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  remark: { type: String, default: '' },
})
const emit = defineEmits(['update:modelValue', 'confirm'])

const presets = ['不要辣', '少放盐', '不要香菜', '多加米饭', '尽快送达']
const draft = ref(props.remark)

const visible = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

watch(
  () => props.modelValue,
  (val) => {
    if (val) draft.value = props.remark
  },
)

function toggleTag(tag) {
  if (draft.value.includes(tag)) {
    draft.value = draft.value.replace(tag, '').trim()
  } else {
    draft.value = draft.value ? `${draft.value},${tag}` : tag
  }
}

function handleConfirm() {
  emit('confirm', draft.value)
  visible.value = false
}
</script>

<style scoped>
.quick-tags {
  margin-bottom: 12px;
}
.tag-item {
  margin: 0 8px 8px 0;
  cursor: pointer;
}
</style>
