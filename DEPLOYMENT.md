# 部署指南

本文档面向"把本项目部署到一台新服务器"的场景，把之前几轮排查中踩过的坑一次性讲清楚，目的是让部署一次成功，不用再逐个报错去猜配置。

## 一、架构总览

```
开发者 git push main
        │
        ▼
GitHub Actions (.github/workflows/deploy.yml)
        │  用 secrets.DEPLOY_HOST / DEPLOY_USER / DEPLOY_SSH_KEY 建立 SSH 连接
        ▼
服务器 ~/.ssh/authorized_keys 里这把公钥被 command="/opt/deploy/deploy.sh" 强制绑定
        │  —— 不管 workflow 发送什么命令，SSH 连接一建立就只会执行这一个脚本
        ▼
/opt/deploy/deploy.sh
        │  git pull（用另一把只读 deploy key）→ mvn package → systemctl restart weiyun-server
        │                                     → npm build（两个前端）→ rsync 到 /var/www/
        ▼
        systemctl reload nginx
```

几个关键设计，理解了就不会误改：

- **`deploy.sh` 必须放在仓库目录之外**（如 `/opt/deploy/deploy.sh`），不能放进 `/opt/weiyun-ordering` 仓库里，否则 `git pull`/`git clean` 可能把它清理掉，导致自动部署链路自毁。
- **`authorized_keys` 用 `command=` 限制触发密钥的权限**：即使这把 GitHub Actions 使用的私钥泄露，攻击者也只能触发一次部署脚本，拿不到交互式 shell（`no-pty`）、拿不到端口转发。GitHub Actions workflow 本身发送什么命令内容不重要（当前是占位符 `echo triggering deploy`），SSH 一连上就会被 `command=` 强制替换执行。
- **`deploy.sh` 拉代码用的是另一把只读 deploy key**（`~/.ssh/github_deploy_ro`），只能 `git clone`/`pull` 这一个仓库，和上面触发部署的密钥是两把完全不同、用途不同的密钥，互不影响。
- **`/etc/sky-take-out/server.env` 通过 systemd 的 `EnvironmentFile=` 机制注入真实密钥**，这个路径不在 git 管理范围内，任何自动化都不应该把它移动、改名或打印其内容。

## 二、从零部署到一台新服务器（Checklist）

**前置要求：**
- 一台全新 Ubuntu 20.04/22.04 服务器，有 sudo 权限
- 已单独安装好 MySQL 和 Redis，并已手动建好数据库（本项目的部署脚本不负责数据库/Redis 本身的安装和建库，只负责应用层）
- 已在服务器安全组/防火墙开放 80、8081、22 端口

**步骤：**

1. 把 `deploy/setup-server.sh` 连同整个 `deploy/` 目录传到服务器（或者先 `git clone` 仓库到任意临时目录，再从里面跑这个脚本），执行：
   ```bash
   sudo bash deploy/setup-server.sh
   ```
   这一步会自动安装 Java 17/Maven/Node 20/nginx/rsync、创建 2GB swap、clone 仓库到 `/opt/weiyun-ordering`、安装 systemd 单元和 nginx 站点配置并 enable。**不会自动启动服务**（此时 `server.env` 还是空占位符）。

2. 编辑 `/etc/sky-take-out/server.env`，参照 `deploy/server.env.example` 填入真实的 MySQL/Redis 连接信息（阿里云 OSS、微信支付两组是可选的，留空不影响启动和点餐主流程）。

3. 按脚本结尾打印的提示生成两把密钥：
   - 一把只读 deploy key 给 `deploy.sh` 拉代码用（GitHub 仓库 Settings → Deploy keys，不勾选 Write access）
   - 一把触发部署用的密钥，公钥加 `command="/opt/deploy/deploy.sh",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty` 前缀写入服务器 `authorized_keys`，私钥连同服务器地址和登录用户名写入 GitHub 仓库 Secrets：`DEPLOY_SSH_KEY`、`DEPLOY_HOST`、`DEPLOY_USER`。

4. 手动跑一次验证全链路：
   ```bash
   bash /opt/deploy/deploy.sh
   ```
   跑完检查 `systemctl status weiyun-server` 是 `active (running)`，`curl -I http://127.0.0.1/` 和 `curl -I http://127.0.0.1:8081/` 均应返回 200。

5. 之后每次 `git push` 到 `main` 分支，GitHub Actions 会自动触发部署，不需要再手动操作。

## 三、环境变量参考

完整清单和每项说明见 [`deploy/server.env.example`](deploy/server.env.example)。核心原则：**环境变量的优先级天然高于 `application.yml` 里的字面值**，这是 Spring Boot 内置的 `PropertySource` 机制，不需要任何额外配置或占位符技巧——`application.yml` 里凡是写成 `${sky.xxx.yyy}` 这种占位符的字段，本质就是在等一个同名（大写+下划线）的环境变量来覆盖它。

## 四、常见故障排查

### 1. 后端启动失败 / 一直 502

先看日志定位到底是哪一步失败：
```bash
sudo systemctl status weiyun-server
sudo journalctl -u weiyun-server -n 100 --no-pager
```

`application.yml` 里凡是 `key: ${sky.x.y}` 这种"字段名和占位符路径长得一样"的自引用写法，如果对应的环境变量没配置，会报三种完全不同、都不太好一眼看出"其实是同一类问题"的错误，取决于这个字段是被哪种机制消费的：

| 消费方式 | 报错表现 | 例子 |
|---|---|---|
| Druid 自己的 `@ConfigurationProperties` 宽松绑定 | 不报启动错误，把字面量占位符字符串原样传入运行时，等到真正使用时才报一个看起来毫不相关的错误 | `driver-class-name` 缺失 → 启动"成功"，但请求打到数据库时报 `ClassNotFoundException: ${sky.datasource.driver-class-name}` |
| 自定义 `@ConfigurationProperties` POJO（如微信支付配置类） | 启动期直接崩，报"循环占位符"，即使给了 `:` 默认值语法也无法避免 | `Circular placeholder reference 'sky.wechat.apiV3Key:' in property definitions` |
| 普通 `@Value("${sky.x.y}")` 字段注入 | 启动期直接崩，报"找不到占位符"，是三种里最好诊断的一种 | `Could not resolve placeholder 'sky.shop.phone'` |

`driver-class-name` 已经在 `application.yml` 里硬编码为 `com.mysql.cj.jdbc.Driver`（这个值对本项目永远不变，不需要做成环境变量），alioss/wechat/shop.phone 相关字段也都已经改成安全的字面量空字符串默认值，不会再触发以上任何一种崩溃。**如果以后又在 `application.yml` 里新增了 `${sky.x.y}` 这种自引用占位符字段，务必同时在 `deploy/server.env.example` 里补上对应的环境变量**，否则又会复现上面某一种报错。

### 2. 接口返回 500，日志里有 `ClassNotFoundException: com.sky.xxx`（或任何旧包名/旧类名）

这是**改过 Java 包名或类名之后**才会出现的问题，全新服务器从空 Redis 起步不会遇到，专门写在这里是为了以后再有类似重构时能一眼认出来：

`RedisConfiguration.java` 里 `RedisTemplate` 的 value 序列化器用的是默认的 `JdkSerializationRedisSerializer`（只手动设置了 key 序列化器），这种序列化方式会把 Java 的**完整类名**编码进 Redis 里的字节流。一旦代码里把某个类的包名或类名改了，Redis 里改名之前缓存下来的旧对象就再也反序列化不出来，任何读到这个缓存 key 的请求都会直接抛异常变成 500。

处理方法：
```bash
redis-cli -h <host> -p <port> -a <password> --no-auth-warning flushdb
```
清空缓存不影响 MySQL 里的业务数据，清完之后缓存会在下次请求时重新生成。**这是一次性的、和"改名"这个动作绑定的代价，不是需要修的 bug**——所以本项目没有改动序列化方式或引入 TTL，只是把这个坑记录在这里。

### 3. `/user/category/list`、`/user/dish/list` 等接口不带 token 访问返回 401

这是设计如此，不是 bug。`WebMvcConfiguration.java` 里的拦截器只放行了登录接口、`/user/shop/status`、`/user/shop/phone`，其余 `/user/**` 接口都要求登录态——这是"先登录再点餐"的正常业务逻辑，不需要"修复"。

### 4. 换到另一台服务器，路径不是 `/opt/weiyun-ordering`

`deploy/weiyun-server.service` 里的 `WorkingDirectory`/`ExecStart`，以及 `deploy/deploy.sh` 里的 `REPO_DIR`，都硬编码了 `/opt/weiyun-ordering` 这个路径。如果实际安装路径不同，这几处需要同步手动改掉再安装/使用。
