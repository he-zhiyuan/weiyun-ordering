<template>
  <div class="login-page">
    <div class="login-card">
      <h1 class="brand">味云点餐</h1>
      <p class="subtitle">Web 端点餐（演示登录，仅需手机号）</p>
      <el-form :model="form" :rules="rules" ref="formRef" @submit.prevent>
        <el-form-item prop="phone">
          <el-input v-model="form.phone" placeholder="请输入手机号" maxlength="11" size="large" />
        </el-form-item>
        <el-form-item prop="name">
          <el-input v-model="form.name" placeholder="请输入昵称（可选）" maxlength="12" size="large" />
        </el-form-item>
        <el-form-item>
          <el-button
            type="primary"
            size="large"
            style="width: 100%"
            :loading="loading"
            @click="handleLogin"
          >
            登录
          </el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { webLogin } from '../api/user'
import { useUserStore } from '../store/user'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const formRef = ref(null)
const loading = ref(false)
const form = reactive({
  phone: '',
  name: '',
})

const phoneReg = /^(13[0-9]|14[01456879]|15[0-35-9]|16[2567]|17[0-8]|18[0-9]|19[0-35-9])\d{8}$/

const rules = {
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { pattern: phoneReg, message: '手机号格式不正确', trigger: 'blur' },
  ],
}

async function handleLogin() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  loading.value = true
  try {
    const res = await webLogin({ phone: form.phone, name: form.name })
    userStore.setUser({
      token: res.data.token,
      id: res.data.id,
      phone: form.phone,
      name: form.name,
    })
    ElMessage.success('登录成功')
    router.replace(route.query.redirect || '/')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, var(--brand-primary), var(--brand-primary-light));
}

.login-card {
  width: 380px;
  padding: 40px 32px;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.15);
  text-align: center;
}

.brand {
  margin: 0 0 8px;
  font-size: 28px;
  color: var(--brand-primary);
}

.subtitle {
  margin: 0 0 24px;
  color: #999;
  font-size: 13px;
}
</style>
