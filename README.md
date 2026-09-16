# 味云点餐 WeiYun Ordering

一个全栈外卖点餐系统：Spring Boot 后端 + 双 Web 前端（商家管理后台 / 用户点餐网页），支持完整的下单履约流程、JWT 双端鉴权、WebSocket 实时来单提醒，并配套了一套基于 GitHub Actions 的生产级自动化部署链路。

## 在线演示

- 用户端：http://106.53.185.34/
- 商家管理端：http://106.53.185.34:8081/

> 当前通过服务器 IP 直接访问（域名备案中），演示环境为个人云服务器，性能有限，仅供功能预览。

## 项目背景

本项目在经典 Java 教学项目「苍穹外卖」的核心业务代码基础上，独立完成了以下产品化 / 工程化扩展：

- **新增一套 Web 端用户点餐前端**（原项目仅有微信小程序端），让用户无需小程序即可在浏览器直接点餐
- **项目整体重命名重构**：跨 Java 包名、Maven artifactId、前端项目名的系统性重构（`sky-*` → `weiyun-*`，`com.sky` → `com.weiyun`）
- **从零搭建生产级 CI/CD**：GitHub Actions 触发 → SSH 部署 → 前后端构建 → systemd/nginx 上线，并在真实上线过程中排查修复了多轮生产环境问题
- 品牌视觉重塑（更名"味云点餐"、统一蓝色主题）

## 技术栈

**后端**

| 分类 | 技术选型 |
|---|---|
| 语言 / 框架 | Java 17、Spring Boot 2.7.3 |
| 持久层 | MyBatis + XML Mapper、PageHelper（分页）、Druid（连接池） |
| 数据库 / 缓存 | MySQL、Redis |
| 鉴权 | JWT（管理端 / 用户端双密钥、双 Token） |
| 实时通信 | WebSocket（原生 `javax.websocket`），管理端来单 / 催单实时提醒 |
| 第三方服务 | 阿里云 OSS（图片存储）、微信支付 SDK（当前为可切换的模拟支付模式） |
| 其他 | Knife4j（接口文档）、AspectJ（公共字段自动填充）、Apache POI（报表导出） |

**前端（两套独立项目）**

| 项目 | 定位 | 技术选型 |
|---|---|---|
| `weiyun-web-admin` | 商家管理后台 | Vue 2.6 + TypeScript + Element UI + Vuex + ECharts |
| `weiyun-web-user` | 用户点餐网页 | Vue 3.5 `<script setup>` + Vite + Element Plus + Pinia（持久化） |

**部署 / CI**

GitHub Actions + SSH 远程部署 + systemd + Nginx，详见 [`DEPLOYMENT.md`](./DEPLOYMENT.md)。

## 系统架构

```
weiyun-common   通用工具类 / 常量 / JWT工具 / OSS与微信支付配置
     ↓
weiyun-pojo     Entity / DTO / VO
     ↓
weiyun-server   Spring Boot 主服务（:8080）
     ├─ /admin/**   管理端接口
     ├─ /user/**    用户端接口
     ├─ /notify/**  微信支付回调
     └─ /ws/**      WebSocket 实时通知

weiyun-web-admin  商家管理后台（Nginx 静态托管）
weiyun-web-user   用户点餐网页（Nginx 静态托管）
```

部署链路（详见 DEPLOYMENT.md）：

```
git push main → GitHub Actions（SSH触发）→ 服务器端受限脚本
  → git pull（只读 deploy key）→ mvn package → systemctl restart weiyun-server
  → 双前端 npm build → rsync 到 /var/www → nginx reload
```

CI 触发密钥通过 `authorized_keys` 的 `command=` + `no-pty` + `no-port-forwarding` 强制绑定到单一部署脚本，即使泄露也无法获得交互式 shell；拉代码使用另一把独立只读 deploy key，实现权限隔离。

## 功能模块

**管理端**
- 员工管理（增删改查、启禁用、密码加密）
- 分类 / 菜品 / 套餐管理（含口味、批量操作、启售停售）
- 订单全流程管理（搜索、接单、拒单、派送、完成、取消）
- 数据统计（营业额 / 用户 / 订单趋势、销量 Top10、Excel 导出、工作台）
- 来单 / 催单实时提醒（WebSocket）
- 营业状态设置（Redis 存储）

**用户端**
- 小程序登录 + Web 端简化登录（手机号登录/自动注册，仅用于演示）
- 菜品 / 套餐浏览（Spring Cache 缓存加速）
- 购物车、地址簿管理
- 下单、支付（真实微信支付 / 模拟支付可配置切换）、催单、再来一单
- 历史订单查询、店铺营业状态与客服电话查询

## 数据库设计

核心表：`user`、`employee`、`category`、`dish`、`dish_flavor`、`setmeal`、`setmeal_dish`、`address_book`、`shopping_cart`、`orders`、`order_detail`。

体现的是经典餐饮点餐领域模型：分类 → 菜品/套餐（含口味、套餐-菜品多对多）、用户 → 地址簿/购物车 → 订单/订单明细，管理端员工账号与 C 端用户账号体系独立。建表脚本见 [`weiyun-server/src/main/resources/sky.sql`](./weiyun-server/src/main/resources/sky.sql)。

## 本地运行

```bash
# 后端（需本地 MySQL / Redis，配置见 weiyun-server/src/main/resources/application-dev.yml）
mvn -pl weiyun-server -am spring-boot:run

# 管理端前端
cd weiyun-web-admin && npm install --legacy-peer-deps && npm run serve

# 用户端前端
cd weiyun-web-user && npm install --legacy-peer-deps && npm run dev
```

默认端口：后端 `8080`，管理端 `8888`，用户端 `5173`。

## 已知局限 / 后续改进方向

- Web 端登录是演示级简化方案（仅手机号，无密码/验证码），非生产级鉴权设计
- 支付默认走模拟支付分支，未接入真实微信商户资质
- 缺少 Controller / Service 层的单元测试与集成测试覆盖
- CI 目前只做部署触发，尚未加入自动化测试 / lint 质量门禁

## 相关文档

- [`DEPLOYMENT.md`](./DEPLOYMENT.md) — 部署架构与真实生产问题排查记录
- [`PAYMENT_SIMULATION.md`](./PAYMENT_SIMULATION.md) — 模拟支付方案说明
- [`AGENTS.md`](./AGENTS.md) — 项目关键业务约束速览
