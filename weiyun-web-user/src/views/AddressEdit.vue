<template>
  <div class="edit-page">
    <header class="page-header">
      <el-button link @click="router.back()">&lt; 返回</el-button>
      <span class="title">{{ isEdit ? '编辑地址' : '新增地址' }}</span>
    </header>

    <div class="content">
      <el-form :model="form" :rules="rules" ref="formRef" label-width="90px">
        <el-form-item label="收货人" prop="consignee">
          <el-input v-model="form.consignee" placeholder="请输入收货人姓名" maxlength="12" />
        </el-form-item>
        <el-form-item label="性别">
          <el-radio-group v-model="form.sex">
            <el-radio value="1">先生</el-radio>
            <el-radio value="0">女士</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="手机号" prop="phone">
          <el-input v-model="form.phone" placeholder="请输入手机号" maxlength="11" />
        </el-form-item>
        <el-form-item label="所在地区" prop="region">
          <el-cascader
            v-model="region"
            :options="regionData"
            placeholder="请选择省/市/区"
            style="width: 100%"
          />
        </el-form-item>
        <el-form-item label="详细地址" prop="detail">
          <el-input v-model="form.detail" placeholder="街道、楼牌号等" maxlength="100" />
        </el-form-item>
        <el-form-item label="地址标签">
          <el-input v-model="form.label" placeholder="如：家、公司（可选）" maxlength="10" />
        </el-form-item>
        <el-form-item label="设为默认">
          <el-switch v-model="isDefault" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="saving" @click="handleSave">保存</el-button>
        </el-form-item>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { regionData, codeToText } from 'element-china-area-data'
import {
  getAddressById,
  getAddressList,
  addAddress,
  updateAddress,
  setDefaultAddress,
} from '../api/address'

const route = useRoute()
const router = useRouter()

const isEdit = computed(() => !!route.query.id)
const formRef = ref(null)
const saving = ref(false)
const region = ref([])
const isDefault = ref(false)

const form = reactive({
  id: null,
  consignee: '',
  sex: '1',
  phone: '',
  detail: '',
  label: '',
})

const phoneReg = /^(13[0-9]|14[01456879]|15[0-35-9]|16[2567]|17[0-8]|18[0-9]|19[0-35-9])\d{8}$/
const nameReg = new RegExp('^[\\u0391-\\uFFE5A-Za-z0-9]{2,12}$')

const rules = {
  consignee: [
    { required: true, message: '请输入收货人姓名', trigger: 'blur' },
    { pattern: nameReg, message: '姓名格式不正确', trigger: 'blur' },
  ],
  phone: [
    { required: true, message: '请输入手机号', trigger: 'blur' },
    { pattern: phoneReg, message: '手机号格式不正确', trigger: 'blur' },
  ],
  detail: [{ required: true, message: '请输入详细地址', trigger: 'blur' }],
}

async function loadAddress() {
  if (!isEdit.value) return
  const res = await getAddressById(route.query.id)
  const addr = res.data
  form.id = addr.id
  form.consignee = addr.consignee
  form.sex = addr.sex
  form.phone = addr.phone
  form.detail = addr.detail
  form.label = addr.label
  isDefault.value = addr.isDefault === 1
  region.value = [addr.provinceCode, addr.cityCode, addr.districtCode].filter(Boolean)
}

async function handleSave() {
  const valid = await formRef.value.validate().catch(() => false)
  if (!valid) return
  if (region.value.length < 3) {
    ElMessage.warning('请选择完整的省/市/区')
    return
  }
  const [provinceCode, cityCode, districtCode] = region.value
  const payload = {
    id: form.id,
    consignee: form.consignee,
    sex: form.sex,
    phone: form.phone,
    provinceCode,
    provinceName: codeToText[provinceCode],
    cityCode,
    cityName: codeToText[cityCode],
    districtCode,
    districtName: codeToText[districtCode],
    detail: form.detail,
    label: form.label,
  }
  saving.value = true
  try {
    let savedId = form.id
    if (isEdit.value) {
      await updateAddress(payload)
    } else {
      await addAddress(payload)
      // 新增接口不返回自增id，且 insert() 强制 isDefault=0，
      // 需要重新查询列表取最大id定位刚插入的记录
      const listRes = await getAddressList()
      const created = (listRes.data || []).reduce(
        (max, a) => (a.id > (max?.id || 0) ? a : max),
        null,
      )
      savedId = created?.id
    }
    // 后端 save()/update() 不保证默认地址互斥，必须显式调用 /default 接口
    if (isDefault.value && savedId) {
      await setDefaultAddress({ id: savedId })
    }
    ElMessage.success('保存成功')
    router.back()
  } finally {
    saving.value = false
  }
}

onMounted(() => {
  loadAddress()
})
</script>

<style scoped>
.edit-page {
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
  max-width: 560px;
  margin: 24px auto;
  background: #fff;
  border-radius: 8px;
  padding: 32px;
}
</style>
