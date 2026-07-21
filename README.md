# 🏔️ 我的旅行足迹 — 中国旅游地图

在线中国地图，标记你去过的城市，展示旅游照片。

## 功能

- 🇨🇳 交互式中国地图（ECharts），点击城市查看照片
- 📷 照片气泡轮播，支持多张照片翻看
- 🔑 密码管理：登录后可添加/删除城市和照片
- ☁️ 数据存 Supabase 云端，多设备同步
- 📱 响应式，手机和桌面都可使用

## 快速部署

### 1. 注册 Supabase

前往 [supabase.com](https://supabase.com) 注册免费账号，创建项目。

等待数据库启动（约 1 分钟）。

### 2. 初始化数据库

在 Supabase Dashboard → SQL Editor 中，粘贴并执行 `supabase-setup.sql` 的全部内容。

### 3. 创建 Storage Bucket

1. Supabase Dashboard → Storage → New Bucket
2. Bucket name: `travel-photos`
3. 勾选 **Public bucket**
4. 创建后，进入 Policies 标签页，添加以下策略：
   - **SELECT 策略**: 允许所有人 (`true`)
   - **INSERT 策略**: 允许所有人 (`true`)
   - **DELETE 策略**: 允许所有人 (`true`)

### 4. 配置应用

打开 `travel-map.html`，修改顶部配置：

```javascript
const SUPABASE_URL = 'https://xxxxx.supabase.co';  // Supabase Project URL
const SUPABASE_ANON_KEY = 'your-anon-key';           // Supabase anon/public key
const ADMIN_PASSWORD_HASH = 'your-sha256-hash';       // 管理密码的 SHA-256 hash
```

获取 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY`：
- Supabase Dashboard → Settings → API
- 复制 `Project URL` 和 `anon public` key

生成密码 hash（在终端执行）：
```bash
echo -n "你的密码" | sha256sum
# 或
echo -n "你的密码" | openssl dgst -sha256
```

### 5. 部署到 GitHub Pages

1. 创建 GitHub 仓库，推送代码
2. Settings → Pages → Source: `Deploy from a branch` → 选择 `main` 分支
3. 保存，稍等片刻即可通过 `https://<username>.github.io/<repo>/` 访问

### 6. 开始使用

1. 打开你的页面
2. 点击「管理」→ 输入密码 → 进入管理模式
3. 点击「添加城市」→ 选择城市 → 上传照片
4. 添加完成后，在地图上点击城市标记即可查看照片

## 技术栈

- ECharts 5 + 中国地图 GeoJSON
- Supabase (PostgreSQL + Storage)
- 原生 HTML/CSS/JS，无框架依赖
- GitHub Pages 静态托管
