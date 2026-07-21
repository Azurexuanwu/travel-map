# 中国旅游足迹地图 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个基于 ECharts 中国地图的旅游足迹纪念页面，支持在线访问和管理

**Architecture:** 单文件 HTML 应用（CDN 加载 ECharts 5 + Supabase JS SDK），地图为全屏主体，点击城市弹出气泡轮播照片。管理面板为侧边抽屉，需密码登录后出现。数据存 Supabase（PostgreSQL + Storage）。

**Tech Stack:** ECharts 5 (CDN), Supabase JS SDK v2 (CDN), vanilla HTML/CSS/JS

## Global Constraints

- 照片单张 ≤ 2MB（前端校验），每个城市最多 20 张
- 密码用 SHA-256 hash 比对，Supabase 中存 hash 值
- RLS 策略：读公开，写需 service_role（通过前端密码门控）
- 响应式：桌面和移动端均可用
- 部署在 GitHub Pages，数据在 Supabase 免费层

---

### Task 1: 项目骨架与 HTML 结构

**Files:**
- Create: `travel-map/travel-map.html`

**Interfaces:**
- Produces: 完整的 HTML 结构（顶部栏、地图容器、气泡浮层、管理抽屉、密码弹窗），所有 CSS 变量和基础样式

- [ ] **Step 1: 创建 HTML 文件，写入完整骨架和 CSS**

```bash
mkdir -p /home/zhongxu/travel-map
```

创建 `travel-map/travel-map.html`，内容如下：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>我的旅行足迹</title>
<script src="https://cdn.jsdelivr.net/npm/echarts@5.5.0/dist/echarts.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/echarts@5.5.0/map/js/china.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2"></script>
<style>
:root {
  --primary: #1a73e8;
  --danger: #d93025;
  --bg: #f8f9fa;
  --surface: #ffffff;
  --text: #202124;
  --text-secondary: #5f6368;
  --shadow: 0 2px 12px rgba(0,0,0,0.12);
  --radius: 12px;
  --bubble-width: 340px;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Noto Sans SC", sans-serif;
  background: var(--bg);
  height: 100vh; width: 100vw;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* 顶部栏 */
.header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 20px;
  background: var(--surface);
  box-shadow: 0 1px 4px rgba(0,0,0,0.08);
  z-index: 10;
  flex-shrink: 0;
}
.header .logo { font-size: 18px; font-weight: 700; color: var(--text); }
.header .logo .icon { margin-right: 6px; }
.header .actions { display: flex; gap: 8px; }
.btn {
  padding: 7px 16px; border: none; border-radius: 6px;
  font-size: 14px; cursor: pointer; font-weight: 500;
  transition: background 0.2s, opacity 0.2s;
}
.btn-primary { background: var(--primary); color: #fff; }
.btn-primary:hover { opacity: 0.9; }
.btn-outline { background: transparent; border: 1px solid #dadce0; color: var(--text); }
.btn-outline:hover { background: #f1f3f4; }
.btn-danger { background: var(--danger); color: #fff; }
.btn-danger:hover { opacity: 0.9; }

/* 地图容器 */
.map-container { flex: 1; position: relative; overflow: hidden; }
#map { width: 100%; height: 100%; }

/* 气泡浮层 */
.bubble {
  position: absolute;
  width: var(--bubble-width);
  max-width: 90vw;
  background: var(--surface);
  border-radius: var(--radius);
  box-shadow: var(--shadow);
  z-index: 20;
  display: none;
  overflow: hidden;
}
.bubble.visible { display: block; }
.bubble .bubble-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 14px;
  border-bottom: 1px solid #e8eaed;
  font-weight: 600; font-size: 15px;
}
.bubble .bubble-close {
  background: none; border: none; font-size: 20px; cursor: pointer;
  color: var(--text-secondary); line-height: 1; padding: 0 2px;
}
.bubble .bubble-body { padding: 12px 14px; }
.bubble .photo-frame {
  width: 100%; height: 220px;
  border-radius: 8px; overflow: hidden;
  background: #e8eaed;
  display: flex; align-items: center; justify-content: center;
}
.bubble .photo-frame img {
  width: 100%; height: 100%; object-fit: cover;
}
.bubble .photo-frame .no-photo {
  font-size: 48px; color: #bdc1c6;
}
.bubble .photo-desc { margin-top: 8px; font-size: 13px; color: var(--text-secondary); text-align: center; }
.bubble .photo-nav {
  display: flex; align-items: center; justify-content: center;
  gap: 12px; margin-top: 10px;
}
.bubble .photo-nav .nav-btn {
  width: 32px; height: 32px; border-radius: 50%;
  border: 1px solid #dadce0; background: #fff;
  cursor: pointer; font-size: 16px; display: flex;
  align-items: center; justify-content: center;
  transition: background 0.2s;
}
.bubble .photo-nav .nav-btn:hover { background: #f1f3f4; }
.bubble .photo-nav .nav-btn:disabled { opacity: 0.3; cursor: default; }
.bubble .photo-nav .counter { font-size: 13px; color: var(--text-secondary); min-width: 40px; text-align: center; }
.bubble .bubble-footer {
  padding: 8px 14px; border-top: 1px solid #e8eaed;
  display: none; /* edit mode only */
}
.bubble .bubble-footer.visible { display: flex; justify-content: flex-end; }

/* 管理抽屉 */
.drawer-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.3);
  z-index: 30; display: none;
}
.drawer-overlay.visible { display: block; }
.drawer {
  position: fixed; top: 0; right: 0; bottom: 0;
  width: 380px; max-width: 90vw;
  background: var(--surface); z-index: 31;
  box-shadow: -2px 0 12px rgba(0,0,0,0.12);
  display: flex; flex-direction: column;
  transform: translateX(100%);
  transition: transform 0.3s ease;
}
.drawer.visible { transform: translateX(0); }
.drawer-header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 16px 20px; border-bottom: 1px solid #e8eaed;
  font-size: 17px; font-weight: 600;
}
.drawer-body { flex: 1; overflow-y: auto; padding: 16px 20px; }
.drawer-body .city-item {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 0; border-bottom: 1px solid #f1f3f4;
}
.drawer-body .city-item .city-name { font-size: 15px; font-weight: 500; }
.drawer-body .city-item .city-meta { font-size: 12px; color: var(--text-secondary); }
.drawer-body .empty-state {
  text-align: center; padding: 40px 0; color: var(--text-secondary);
  font-size: 14px;
}
.drawer-footer {
  padding: 12px 20px; border-top: 1px solid #e8eaed;
}

/* 添加城市表单 */
.form-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.4);
  z-index: 40; display: none;
  align-items: center; justify-content: center;
}
.form-overlay.visible { display: flex; }
.form-panel {
  background: var(--surface); border-radius: var(--radius);
  width: 440px; max-width: 92vw; max-height: 85vh;
  overflow-y: auto; padding: 24px;
  box-shadow: 0 4px 24px rgba(0,0,0,0.16);
}
.form-panel h3 { margin-bottom: 16px; font-size: 18px; }
.form-group { margin-bottom: 14px; }
.form-group label { display: block; font-size: 13px; font-weight: 500; color: var(--text-secondary); margin-bottom: 4px; }
.form-group select, .form-group input[type="text"], .form-group input[type="number"] {
  width: 100%; padding: 8px 10px; border: 1px solid #dadce0; border-radius: 6px;
  font-size: 14px; outline: none;
}
.form-group select:focus, .form-group input:focus { border-color: var(--primary); }
.form-actions { display: flex; gap: 8px; justify-content: flex-end; margin-top: 18px; }

/* 照片上传区 */
.photo-upload-list { margin-top: 8px; }
.photo-upload-item {
  display: flex; align-items: center; gap: 10px;
  padding: 8px 0; border-bottom: 1px solid #f1f3f4;
}
.photo-upload-item img {
  width: 60px; height: 60px; object-fit: cover;
  border-radius: 6px; background: #e8eaed;
}
.photo-upload-item .photo-info { flex: 1; }
.photo-upload-item .photo-info input {
  width: 100%; padding: 4px 8px; border: 1px solid #dadce0;
  border-radius: 4px; font-size: 13px;
}
.photo-upload-item .remove-btn {
  background: none; border: none; color: var(--danger);
  cursor: pointer; font-size: 18px; padding: 2px 6px;
}
.file-input-wrapper {
  display: flex; align-items: center; gap: 8px; margin-top: 8px;
}
.file-input-wrapper .file-label {
  padding: 6px 14px; border: 1px dashed #dadce0; border-radius: 6px;
  cursor: pointer; font-size: 13px; color: var(--primary);
  transition: background 0.2s;
}
.file-input-wrapper .file-label:hover { background: #e8f0fe; }
.file-input-wrapper input[type="file"] { display: none; }

/* 密码弹窗 */
.password-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.4);
  z-index: 50; display: none;
  align-items: center; justify-content: center;
}
.password-overlay.visible { display: flex; }
.password-panel {
  background: var(--surface); border-radius: var(--radius);
  padding: 28px; width: 340px; max-width: 90vw;
  box-shadow: 0 4px 24px rgba(0,0,0,0.16);
  text-align: center;
}
.password-panel h3 { margin-bottom: 6px; font-size: 17px; }
.password-panel p { font-size: 13px; color: var(--text-secondary); margin-bottom: 16px; }
.password-panel input {
  width: 100%; padding: 10px 12px; border: 1px solid #dadce0;
  border-radius: 6px; font-size: 15px; outline: none; margin-bottom: 14px;
}
.password-panel input:focus { border-color: var(--primary); }
.password-panel .error { color: var(--danger); font-size: 13px; margin-bottom: 8px; display: none; }

/* 响应式 */
@media (max-width: 600px) {
  .header { padding: 8px 12px; }
  .header .logo { font-size: 16px; }
  .btn { padding: 6px 12px; font-size: 13px; }
  .drawer { width: 100vw; }
  :root { --bubble-width: 280px; }
  .bubble .photo-frame { height: 180px; }
}

/* Toast */
.toast {
  position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%);
  background: #323232; color: #fff; padding: 10px 22px;
  border-radius: 8px; font-size: 14px; z-index: 60;
  opacity: 0; transition: opacity 0.3s; pointer-events: none;
}
.toast.visible { opacity: 1; }
</style>
</head>
<body>
  <!-- 顶部栏 -->
  <header class="header">
    <div class="logo"><span class="icon">🏔️</span>我的旅行足迹</div>
    <div class="actions" id="headerActions">
      <button class="btn btn-outline" id="btnManage" onclick="openManagement()">⚙️ 管理</button>
    </div>
  </header>

  <!-- 地图 -->
  <div class="map-container">
    <div id="map"></div>
    <!-- 气泡 -->
    <div class="bubble" id="bubble">
      <div class="bubble-header">
        <span id="bubbleCityName"></span>
        <button class="bubble-close" onclick="closeBubble()">×</button>
      </div>
      <div class="bubble-body">
        <div class="photo-frame" id="bubblePhotoFrame">
          <span class="no-photo">🖼️</span>
        </div>
        <div class="photo-desc" id="bubblePhotoDesc"></div>
        <div class="photo-nav" id="bubbleNav">
          <button class="nav-btn" id="bubblePrev" onclick="prevPhoto()">◀</button>
          <span class="counter" id="bubbleCounter">0/0</span>
          <button class="nav-btn" id="bubbleNext" onclick="nextPhoto()">▶</button>
        </div>
      </div>
      <div class="bubble-footer" id="bubbleFooter">
        <button class="btn btn-danger btn-sm" onclick="deleteCurrentPhoto()">🗑 删除照片</button>
      </div>
    </div>
  </div>

  <!-- 管理抽屉 -->
  <div class="drawer-overlay" id="drawerOverlay" onclick="closeDrawer()"></div>
  <div class="drawer" id="drawer">
    <div class="drawer-header">
      <span>⚙️ 管理城市</span>
      <button class="bubble-close" onclick="closeDrawer()">×</button>
    </div>
    <div class="drawer-body" id="drawerBody"></div>
    <div class="drawer-footer">
      <button class="btn btn-primary" style="width:100%" onclick="openAddCityForm()">+ 添加城市</button>
    </div>
  </div>

  <!-- 添加城市表单 -->
  <div class="form-overlay" id="formOverlay">
    <div class="form-panel">
      <h3 id="formTitle">添加城市</h3>
      <div class="form-group">
        <label>选择城市</label>
        <select id="citySelect" onchange="onCitySelect()">
          <option value="">-- 请选择 --</option>
        </select>
      </div>
      <div class="form-group">
        <label>城市名称</label>
        <input type="text" id="cityNameInput" placeholder="如：丽江">
      </div>
      <div style="display:flex; gap:10px;">
        <div class="form-group" style="flex:1">
          <label>纬度</label>
          <input type="number" id="cityLatInput" placeholder="如：26.86" step="any">
        </div>
        <div class="form-group" style="flex:1">
          <label>经度</label>
          <input type="number" id="cityLngInput" placeholder="如：100.23" step="any">
        </div>
      </div>
      <div class="form-group">
        <label>照片（每张不超过 2MB，最多 20 张）</label>
        <div class="photo-upload-list" id="photoUploadList"></div>
        <div class="file-input-wrapper">
          <label class="file-label" for="fileInput">📷 选择照片</label>
          <input type="file" id="fileInput" accept="image/*" multiple onchange="onFilesSelected()">
          <span style="font-size:12px;color:var(--text-secondary)" id="fileCount">未选择文件</span>
        </div>
      </div>
      <div class="form-actions">
        <button class="btn btn-outline" onclick="closeAddCityForm()">取消</button>
        <button class="btn btn-primary" id="btnSaveCity" onclick="saveCity()">保存</button>
      </div>
    </div>
  </div>

  <!-- 密码弹窗 -->
  <div class="password-overlay" id="passwordOverlay">
    <div class="password-panel">
      <h3>🔑 输入管理密码</h3>
      <p>请输入密码以进入管理模式</p>
      <input type="password" id="passwordInput" placeholder="管理密码" onkeydown="if(event.key==='Enter')verifyPassword()">
      <div class="error" id="passwordError">密码错误，请重试</div>
      <button class="btn btn-primary" style="width:100%" onclick="verifyPassword()">确认</button>
    </div>
  </div>

  <!-- Toast -->
  <div class="toast" id="toast"></div>
</body>
</html>
```

- [ ] **Step 2: 在浏览器中打开文件确认骨架显示正常**

```bash
# 用默认浏览器打开查看
xdg-open /home/zhongxu/travel-map/travel-map.html 2>/dev/null || echo "请在浏览器中手动打开文件"
```

预期：看到顶部栏（「我的旅行足迹」+「管理」按钮），空白的地图区域，无 JS 错误。

- [ ] **Step 3: 提交**

```bash
cd /home/zhongxu/travel-map
git add travel-map.html
git commit -m "feat: add HTML skeleton with CSS for travel map"
```

---

### Task 2: 预设城市数据与工具函数

**Files:**
- Modify: `travel-map/travel-map.html` — 在 `</body>` 前插入 `<script>` 标签

**Interfaces:**
- Produces: `PRESET_CITIES` 数组（含 name、lat、lng），`sha256()` 异步函数，`showToast()` 函数，`isEditMode()` 函数，`closeBubble()` 函数

- [ ] **Step 1: 添加 JavaScript 数据层和工具函数**

在 `travel-map.html` 的 `</body>` 前插入以下 `<script>` 块：

```html
<script>
// ====== 配置（部署时替换为你的 Supabase 信息） ======
const SUPABASE_URL = 'YOUR_SUPABASE_URL';       // 如 https://xxxxx.supabase.co
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';       // Supabase 项目的 anon/public key
const ADMIN_PASSWORD_HASH = 'YOUR_SHA256_HASH';  // echo -n "yourpassword" | sha256sum

// ====== 预设城市列表 ======
const PRESET_CITIES = [
  { name: '北京', lat: 39.92, lng: 116.46 },
  { name: '上海', lat: 31.23, lng: 121.47 },
  { name: '广州', lat: 23.13, lng: 113.26 },
  { name: '深圳', lat: 22.54, lng: 114.06 },
  { name: '成都', lat: 30.57, lng: 104.07 },
  { name: '重庆', lat: 29.56, lng: 106.55 },
  { name: '杭州', lat: 30.29, lng: 120.15 },
  { name: '南京', lat: 32.06, lng: 118.80 },
  { name: '西安', lat: 34.34, lng: 108.94 },
  { name: '武汉', lat: 30.59, lng: 114.31 },
  { name: '长沙', lat: 28.23, lng: 112.94 },
  { name: '厦门', lat: 24.48, lng: 118.09 },
  { name: '青岛', lat: 36.07, lng: 120.38 },
  { name: '大连', lat: 38.91, lng: 121.61 },
  { name: '哈尔滨', lat: 45.80, lng: 126.53 },
  { name: '昆明', lat: 25.04, lng: 102.71 },
  { name: '丽江', lat: 26.86, lng: 100.23 },
  { name: '大理', lat: 25.61, lng: 100.27 },
  { name: '桂林', lat: 25.27, lng: 110.29 },
  { name: '三亚', lat: 18.25, lng: 109.51 },
  { name: '拉萨', lat: 29.65, lng: 91.14 },
  { name: '乌鲁木齐', lat: 43.83, lng: 87.62 },
  { name: '呼和浩特', lat: 40.84, lng: 111.75 },
  { name: '西宁', lat: 36.62, lng: 101.78 },
  { name: '兰州', lat: 36.06, lng: 103.83 },
  { name: '银川', lat: 38.49, lng: 106.23 },
  { name: '海口', lat: 20.02, lng: 110.35 },
  { name: '贵阳', lat: 26.65, lng: 106.63 },
  { name: '南昌', lat: 28.68, lng: 115.86 },
  { name: '合肥', lat: 31.82, lng: 117.23 },
  { name: '郑州', lat: 34.75, lng: 113.63 },
  { name: '济南', lat: 36.67, lng: 116.98 },
  { name: '太原', lat: 37.87, lng: 112.55 },
  { name: '石家庄', lat: 38.04, lng: 114.51 },
  { name: '天津', lat: 39.13, lng: 117.19 },
  { name: '苏州', lat: 31.30, lng: 120.62 },
  { name: '无锡', lat: 31.49, lng: 120.31 },
  { name: '宁波', lat: 29.87, lng: 121.54 },
  { name: '福州', lat: 26.07, lng: 119.30 },
  { name: '珠海', lat: 22.27, lng: 113.58 },
];

// ====== Supabase 客户端 ======
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ====== 应用状态 ======
let cities = [];             // [{ id, name, lat, lng, photos: [{id, storage_path, description, sort_order}] }]
let currentBubbleCity = null;
let currentPhotoIndex = 0;
let editMode = false;
let pendingPhotos = [];      // 添加城市表单中的待上传照片 [{ file, previewUrl, description }]

// ====== 工具函数 ======
async function sha256(message) {
  const msgBuffer = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}

function showToast(msg) {
  const el = document.getElementById('toast');
  el.textContent = msg;
  el.classList.add('visible');
  clearTimeout(el._timeout);
  el._timeout = setTimeout(() => el.classList.remove('visible'), 2500);
}

function isEditMode() { return editMode; }

function closeBubble() {
  document.getElementById('bubble').classList.remove('visible');
  currentBubbleCity = null;
  currentPhotoIndex = 0;
}
</script>
```

- [ ] **Step 2: 确认无 JS 语法错误**

在浏览器控制台检查无报错。

- [ ] **Step 3: 提交**

```bash
cd /home/zhongxu/travel-map
git add travel-map.html
git commit -m "feat: add preset cities, Supabase client, and utility functions"
```

---

### Task 3: ECharts 地图初始化和城市标记渲染

**Files:**
- Modify: `travel-map/travel-map.html` — 在现有 `<script>` 块内追加代码

**Interfaces:**
- Consumes: `cities` 数组（来自 Task 2 数据加载）
- Produces: `initMap()` 函数 → 渲染中国地图 + 散点标记，`renderCityMarkers()` 函数 → 更新标记数据，`loadCities()` 函数 → 从 Supabase 加载城市

- [ ] **Step 1: 追加地图初始化代码**

在 `travel-map.html` 的 `<script>` 块末尾（`closeBubble()` 函数后面）追加：

```javascript
// ====== ECharts 地图 ======
let mapChart = null;

function initMap() {
  const dom = document.getElementById('map');
  mapChart = echarts.init(dom);

  const option = {
    tooltip: {
      trigger: 'item',
      formatter: function(params) {
        if (params.seriesType === 'scatter' || params.seriesType === 'effectScatter') {
          return params.name;
        }
        return '';
      }
    },
    geo: {
      map: 'china',
      roam: true,
      zoom: 1.2,
      center: [104.5, 36],
      label: { show: false },
      itemStyle: {
        areaColor: '#f3f4f5',
        borderColor: '#d0d5dd'
      },
      emphasis: {
        label: { show: false },
        itemStyle: { areaColor: '#e8eaed' }
      }
    },
    series: []
  };

  mapChart.setOption(option);

  // 点击地图空白处关闭气泡
  mapChart.on('click', function(params) {
    if (params.componentType === 'geo') {
      closeBubble();
    }
  });

  // 窗口大小变化时重绘
  window.addEventListener('resize', function() {
    mapChart.resize();
    closeBubble();
  });
}

function renderCityMarkers() {
  if (!mapChart) return;

  // 为每个城市创建散点数据
  const scatterData = cities.map(city => ({
    name: city.name,
    value: [city.lng, city.lat, city.id]
  }));

  mapChart.setOption({
    series: [{
      type: 'scatter',
      coordinateSystem: 'geo',
      data: scatterData,
      symbolSize: function(val) {
        return 14;
      },
      symbol: 'pin',
      itemStyle: {
        color: '#e53e3e'
      },
      label: {
        show: true,
        formatter: function(p) { return p.name; },
        position: 'right',
        distance: 6,
        fontSize: 13,
        color: '#202124',
        fontWeight: 500
      },
      emphasis: {
        scale: 1.4,
        itemStyle: { color: '#c53030' }
      }
    }]
  });

  // 点击城市标记 → 显示气泡
  mapChart.off('click');
  mapChart.on('click', function(params) {
    if (params.componentType === 'geo') {
      closeBubble();
    } else if (params.seriesType === 'scatter') {
      const cityId = params.value[2];
      const city = cities.find(c => c.id === cityId);
      if (city) {
        showBubble(city, params.event.event);
      }
    }
  });
}

// ====== 数据加载 ======
async function loadCities() {
  const { data, error } = await supabase
    .from('cities')
    .select('id, name, lat, lng, photos(id, storage_path, description, sort_order)')
    .order('created_at', { ascending: true });

  if (error) {
    console.error('加载城市失败:', error);
    return;
  }

  cities = (data || []).map(city => ({
    ...city,
    photos: (city.photos || []).sort((a, b) => a.sort_order - b.sort_order)
  }));

  renderCityMarkers();
}
</script>
```

- [ ] **Step 2: 在页面底部添加初始化调用**

在 `</script>` 前追加 DOMContentLoaded 初始化：

```javascript
// ====== 初始化 ======
document.addEventListener('DOMContentLoaded', async function() {
  initMap();
  await loadCities();
});
```

- [ ] **Step 3: 浏览器打开确认地图渲染**

打开页面，应看到中国地图（灰色省份边界），若 Supabase 未配置则无城市标记（这是预期的）。

- [ ] **Step 4: 提交**

```bash
cd /home/zhongxu/travel-map
git add travel-map.html
git commit -m "feat: add ECharts China map with city scatter markers"
```

---

### Task 4: 气泡弹窗与照片轮播

**Files:**
- Modify: `travel-map/travel-map.html` — 在 `<script>` 块内追加气泡逻辑

**Interfaces:**
- Consumes: `currentBubbleCity`, `currentPhotoIndex`（来自 Task 2），`cities` 数组
- Produces: `showBubble(city, event)`, `prevPhoto()`, `nextPhoto()`, `renderBubbleContent()`

- [ ] **Step 1: 追加气泡显示和轮播代码**

在 `loadCities()` 函数后面追加：

```javascript
// ====== 气泡弹窗 ======
function showBubble(city, clickEvent) {
  currentBubbleCity = city;
  currentPhotoIndex = 0;

  const bubble = document.getElementById('bubble');
  const mapContainer = document.querySelector('.map-container');
  const rect = mapContainer.getBoundingClientRect();

  // 将地图点击位置转换为容器内坐标
  let left = clickEvent.clientX - rect.left;
  let top = clickEvent.clientY - rect.top;

  // 气泡宽度约 340px，确保不超出屏幕
  const bubbleWidth = Math.min(340, rect.width * 0.9);
  bubble.style.setProperty('--bubble-width', bubbleWidth + 'px');

  if (left + bubbleWidth / 2 > rect.width) {
    left = rect.width - bubbleWidth - 10;
  } else {
    left = left - bubbleWidth / 2;
  }
  if (left < 10) left = 10;

  // 气泡显示在点击位置上方
  top = top - 280; // 气泡高度约 280px
  if (top < 10) top = 10;

  bubble.style.left = left + 'px';
  bubble.style.top = top + 'px';

  renderBubbleContent();

  // 编辑模式下显示删除按钮
  const footer = document.getElementById('bubbleFooter');
  if (editMode) {
    footer.classList.add('visible');
  } else {
    footer.classList.remove('visible');
  }

  bubble.classList.add('visible');
}

function renderBubbleContent() {
  const city = currentBubbleCity;
  if (!city) return;

  document.getElementById('bubbleCityName').textContent = city.name;

  const photoFrame = document.getElementById('bubblePhotoFrame');
  const photoDesc = document.getElementById('bubblePhotoDesc');
  const counter = document.getElementById('bubbleCounter');
  const prevBtn = document.getElementById('bubblePrev');
  const nextBtn = document.getElementById('bubbleNext');

  const photos = city.photos || [];

  if (photos.length === 0) {
    photoFrame.innerHTML = '<span class="no-photo">🖼️</span>';
    photoDesc.textContent = '暂无照片';
    counter.textContent = '0/0';
    prevBtn.disabled = true;
    nextBtn.disabled = true;
    return;
  }

  const photo = photos[currentPhotoIndex];
  const photoUrl = SUPABASE_URL + '/storage/v1/object/public/travel-photos/' + photo.storage_path;

  photoFrame.innerHTML = `<img src="${photoUrl}" alt="${photo.description || ''}" loading="lazy">`;
  photoDesc.textContent = photo.description || '';
  counter.textContent = `${currentPhotoIndex + 1}/${photos.length}`;
  prevBtn.disabled = currentPhotoIndex === 0;
  nextBtn.disabled = currentPhotoIndex >= photos.length - 1;
}

function prevPhoto() {
  if (!currentBubbleCity) return;
  const total = (currentBubbleCity.photos || []).length;
  if (total === 0) return;
  currentPhotoIndex = Math.max(0, currentPhotoIndex - 1);
  renderBubbleContent();
}

function nextPhoto() {
  if (!currentBubbleCity) return;
  const total = (currentBubbleCity.photos || []).length;
  if (total === 0) return;
  currentPhotoIndex = Math.min(total - 1, currentPhotoIndex + 1);
  renderBubbleContent();
}

function deleteCurrentPhoto() {
  if (!currentBubbleCity || !editMode) return;
  const photos = currentBubbleCity.photos || [];
  if (photos.length === 0) return;
  const photo = photos[currentPhotoIndex];
  if (!confirm(`确定删除照片「${photo.description || '未命名'}」吗？`)) return;

  deletePhotoFromSupabase(currentBubbleCity.id, photo).then(() => {
    showToast('照片已删除');
  });
}
```

- [ ] **Step 2: 浏览器打开测试气泡交互**

在控制台手动创建一个测试城市数据来验证气泡功能（因为 Supabase 还未配置）：
```javascript
// 控制台临时测试
currentBubbleCity = { name: '测试', photos: [] };
showBubble({ name: '测试', photos: [] }, { clientX: 500, clientY: 300 });
```
预期：气泡弹出，显示「暂无照片」，可关闭。

- [ ] **Step 3: 提交**

```bash
cd /home/zhongxu/travel-map
git add travel-map.html
git commit -m "feat: add photo bubble popup with carousel navigation"
```

---

### Task 5: 密码验证与管理模式

**Files:**
- Modify: `travel-map/travel-map.html` — 在 `<script>` 块内追加认证逻辑

**Interfaces:**
- Consumes: `ADMIN_PASSWORD_HASH`, `sha256()`
- Produces: `openManagement()`, `verifyPassword()`, `editMode` 状态切换

- [ ] **Step 1: 追加密码验证和管理模式切换代码**

在 `deleteCurrentPhoto()` 函数后面追加：

```javascript
// ====== 认证 ======
function openManagement() {
  if (editMode) {
    // 已登录，直接打开管理抽屉
    openDrawer();
    return;
  }
  // 未登录，弹出密码框
  document.getElementById('passwordOverlay').classList.add('visible');
  document.getElementById('passwordInput').value = '';
  document.getElementById('passwordError').style.display = 'none';
  setTimeout(() => document.getElementById('passwordInput').focus(), 100);
}

async function verifyPassword() {
  const input = document.getElementById('passwordInput').value;
  if (!input) return;

  const hash = await sha256(input);

  if (hash === ADMIN_PASSWORD_HASH) {
    editMode = true;
    document.getElementById('passwordOverlay').classList.remove('visible');
    document.getElementById('btnManage').textContent = '⚙️ 管理（已登录）';
    document.getElementById('btnManage').classList.add('btn-primary');
    document.getElementById('btnManage').classList.remove('btn-outline');
    showToast('已进入管理模式');
    openDrawer();
  } else {
    document.getElementById('passwordError').style.display = 'block';
    document.getElementById('passwordInput').value = '';
    document.getElementById('passwordInput').focus();
  }
}

function logoutEditMode() {
  editMode = false;
  document.getElementById('btnManage').textContent = '⚙️ 管理';
  document.getElementById('btnManage').classList.remove('btn-primary');
  document.getElementById('btnManage').classList.add('btn-outline');
  document.getElementById('bubbleFooter').classList.remove('visible');
  closeDrawer();
  closeAddCityForm();
  closeBubble();
  showToast('已退出管理模式');
}
```

- [ ] **Step 2: 提交**

```bash
cd /home/zhongxu/travel-map
git add travel-map.html
git commit -m "feat: add password authentication and edit mode toggle"
```

---

### Task 6: 管理抽屉（城市列表）

**Files:**
- Modify: `travel-map/travel-map.html` — 在 `<script>` 块内追加抽屉逻辑

**Interfaces:**
- Consumes: `cities` 数组, `editMode`
- Produces: `openDrawer()`, `closeDrawer()`, `renderDrawerList()`, `deleteCity()`

- [ ] **Step 1: 追加管理抽屉代码**

在 `logoutEditMode()` 函数后面追加：

```javascript
// ====== 管理抽屉 ======
function openDrawer() {
  renderDrawerList();
  document.getElementById('drawer').classList.add('visible');
  document.getElementById('drawerOverlay').classList.add('visible');
}

function closeDrawer() {
  document.getElementById('drawer').classList.remove('visible');
  document.getElementById('drawerOverlay').classList.remove('visible');
}

function renderDrawerList() {
  const body = document.getElementById('drawerBody');
  if (cities.length === 0) {
    body.innerHTML = '<div class="empty-state">🏙️<br>还没有添加城市<br>点击下方按钮开始</div>';
    return;
  }

  body.innerHTML = cities.map(city => `
    <div class="city-item">
      <div>
        <div class="city-name">📍 ${escapeHtml(city.name)}</div>
        <div class="city-meta">${(city.photos || []).length} 张照片</div>
      </div>
      <button class="btn btn-danger btn-sm" onclick="deleteCity('${city.id}')">删除</button>
    </div>
  `).join('');
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}

async function deleteCity(cityId) {
  const city = cities.find(c => c.id === cityId);
  if (!city) return;
  if (!confirm(`确定删除「${city.name}」及其所有照片吗？此操作不可恢复。`)) return;

  // 删除所有照片文件
  for (const photo of (city.photos || [])) {
    await supabase.storage.from('travel-photos').remove([photo.storage_path]);
  }
  // 删除照片记录
  await supabase.from('photos').delete().eq('city_id', cityId);
  // 删除城市记录
  const { error } = await supabase.from('cities').delete().eq('id', cityId);

  if (error) {
    showToast('删除失败: ' + error.message);
    return;
  }

  // 从本地状态移除
  cities = cities.filter(c => c.id !== cityId);
  renderCityMarkers();
  renderDrawerList();
  closeBubble();
  showToast(`已删除「${city.name}」`);
}
```

- [ ] **Step 2: 提交**

```bash
cd /home/zhongxu/travel-map
git add travel-map.html
git commit -m "feat: add management drawer with city list and delete"
```

---

### Task 7: 添加城市表单 + 照片上传

**Files:**
- Modify: `travel-map/travel-map.html` — 在 `<script>` 块内追加表单和上传逻辑

**Interfaces:**
- Consumes: `PRESET_CITIES`, `cities`, Supabase storage
- Produces: `openAddCityForm()`, `closeAddCityForm()`, `onCitySelect()`, `onFilesSelected()`, `saveCity()`, `deletePhotoFromSupabase()`

- [ ] **Step 1: 追加添加城市表单代码**

在 `deleteCity()` 函数后面追加：

```javascript
// ====== 添加城市表单 ======
function openAddCityForm() {
  // 填充预设城市下拉
  const select = document.getElementById('citySelect');
  const existingNames = cities.map(c => c.name);
  const available = PRESET_CITIES.filter(c => !existingNames.includes(c.name));
  select.innerHTML = '<option value="">-- 请选择 --</option>' +
    available.map(c => `<option value="${c.name}" data-lat="${c.lat}" data-lng="${c.lng}">${c.name}</option>`).join('');

  document.getElementById('cityNameInput').value = '';
  document.getElementById('cityLatInput').value = '';
  document.getElementById('cityLngInput').value = '';
  document.getElementById('fileInput').value = '';
  document.getElementById('fileCount').textContent = '未选择文件';
  pendingPhotos = [];
  renderPhotoUploadList();

  document.getElementById('formOverlay').classList.add('visible');
  document.getElementById('btnSaveCity').disabled = false;
}

function closeAddCityForm() {
  document.getElementById('formOverlay').classList.remove('visible');
  // 释放预览 URL
  pendingPhotos.forEach(p => URL.revokeObjectURL(p.previewUrl));
  pendingPhotos = [];
}

function onCitySelect() {
  const select = document.getElementById('citySelect');
  const option = select.selectedOptions[0];
  if (option && option.dataset.lat) {
    document.getElementById('cityNameInput').value = option.value;
    document.getElementById('cityLatInput').value = option.dataset.lat;
    document.getElementById('cityLngInput').value = option.dataset.lng;
  }
}

function onFilesSelected() {
  const files = Array.from(document.getElementById('fileInput').files);
  const currentCount = pendingPhotos.length;

  if (currentCount + files.length > 20) {
    showToast('每个城市最多 20 张照片');
    document.getElementById('fileInput').value = '';
    return;
  }

  for (const file of files) {
    if (file.size > 2 * 1024 * 1024) {
      showToast(`「${file.name}」超过 2MB，已跳过`);
      continue;
    }
    pendingPhotos.push({
      file: file,
      previewUrl: URL.createObjectURL(file),
      description: ''
    });
  }

  document.getElementById('fileInput').value = '';
  document.getElementById('fileCount').textContent = `已选 ${pendingPhotos.length} 张`;
  renderPhotoUploadList();
}

function renderPhotoUploadList() {
  const container = document.getElementById('photoUploadList');
  if (pendingPhotos.length === 0) {
    container.innerHTML = '';
    return;
  }
  container.innerHTML = pendingPhotos.map((p, i) => `
    <div class="photo-upload-item">
      <img src="${p.previewUrl}" alt="预览">
      <div class="photo-info">
        <input type="text" placeholder="照片描述（可选）" value="${escapeHtml(p.description)}"
               onchange="pendingPhotos[${i}].description = this.value">
      </div>
      <button class="remove-btn" onclick="removePendingPhoto(${i})" title="移除">×</button>
    </div>
  `).join('');
}

function removePendingPhoto(index) {
  URL.revokeObjectURL(pendingPhotos[index].previewUrl);
  pendingPhotos.splice(index, 1);
  document.getElementById('fileCount').textContent = `已选 ${pendingPhotos.length} 张`;
  renderPhotoUploadList();
}

async function saveCity() {
  const name = document.getElementById('cityNameInput').value.trim();
  const lat = parseFloat(document.getElementById('cityLatInput').value);
  const lng = parseFloat(document.getElementById('cityLngInput').value);

  if (!name) { showToast('请输入城市名称'); return; }
  if (isNaN(lat) || isNaN(lng)) { showToast('请输入有效的经纬度'); return; }
  if (lat < 18 || lat > 54 || lng < 73 || lng > 135) {
    if (!confirm('经纬度似乎不在中国范围内，确定继续吗？')) return;
  }

  const btn = document.getElementById('btnSaveCity');
  btn.disabled = true;
  btn.textContent = '保存中...';

  try {
    // 1. 插入城市记录
    const { data: cityData, error: cityError } = await supabase
      .from('cities')
      .insert({ name, lat, lng })
      .select('id')
      .single();

    if (cityError) throw new Error('创建城市失败: ' + cityError.message);

    const cityId = cityData.id;

    // 2. 上传照片
    const uploadedPhotos = [];
    for (let i = 0; i < pendingPhotos.length; i++) {
      const p = pendingPhotos[i];
      const ext = p.file.name.split('.').pop() || 'jpg';
      const storagePath = `${cityId}/${Date.now()}_${i}.${ext}`;

      const { error: uploadError } = await supabase.storage
        .from('travel-photos')
        .upload(storagePath, p.file, {
          cacheControl: '31536000',
          upsert: false
        });

      if (uploadError) {
        console.error('上传失败:', uploadError);
        continue;
      }

      uploadedPhotos.push({
        city_id: cityId,
        storage_path: storagePath,
        description: p.description || '',
        sort_order: i
      });
    }

    // 3. 批量插入照片记录
    if (uploadedPhotos.length > 0) {
      await supabase.from('photos').insert(uploadedPhotos);
    }

    // 4. 更新本地状态
    const newCity = {
      id: cityId,
      name,
      lat,
      lng,
      photos: uploadedPhotos.map(p => ({
        id: '', // 不需要精确 id，用于展示
        storage_path: p.storage_path,
        description: p.description,
        sort_order: p.sort_order
      }))
    };
    cities.push(newCity);
    renderCityMarkers();
    renderDrawerList();
    closeAddCityForm();
    showToast(`已添加「${name}」，共 ${uploadedPhotos.length} 张照片`);
  } catch (err) {
    showToast(err.message);
  } finally {
    btn.disabled = false;
    btn.textContent = '保存';
  }
}

async function deletePhotoFromSupabase(cityId, photo) {
  try {
    // 从 Storage 删除
    await supabase.storage.from('travel-photos').remove([photo.storage_path]);
    // 从 photos 表删除
    await supabase.from('photos').delete().eq('id', photo.id);

    // 更新本地状态
    const city = cities.find(c => c.id === cityId);
    if (city) {
      city.photos = city.photos.filter(p => p.id !== photo.id);
      if (currentPhotoIndex >= city.photos.length) {
        currentPhotoIndex = Math.max(0, city.photos.length - 1);
      }
      if (city.photos.length === 0) {
        closeBubble();
      } else {
        renderBubbleContent();
      }
      renderDrawerList();
      renderCityMarkers();
    }
  } catch (err) {
    showToast('删除失败: ' + err.message);
  }
}
```

- [ ] **Step 2: 提交**

```bash
cd /home/zhongxu/travel-map
git add travel-map.html
git commit -m "feat: add city form with photo upload to Supabase storage"
```

---

### Task 8: Supabase 建表 SQL 与 RLS 策略

**Files:**
- Create: `travel-map/supabase-setup.sql`

**Interfaces:**
- Produces: 完整的数据库 schema（cities 表、photos 表、storage bucket 配置）

- [ ] **Step 1: 创建 SQL 文件**

创建 `travel-map/supabase-setup.sql`：

```sql
-- ============================================
-- 中国旅游足迹地图 — Supabase 数据库初始化
-- 在 Supabase SQL Editor 中执行本文件
-- ============================================

-- 1. 创建城市表
CREATE TABLE IF NOT EXISTS cities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  lat FLOAT8 NOT NULL,
  lng FLOAT8 NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. 创建照片表
CREATE TABLE IF NOT EXISTS photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  city_id UUID NOT NULL REFERENCES cities(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  description TEXT DEFAULT '',
  sort_order INT2 NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. 索引
CREATE INDEX IF NOT EXISTS idx_photos_city_id ON photos(city_id);

-- 4. RLS 策略：公开可读，写操作由前端密码门控（使用 anon key）
ALTER TABLE cities ENABLE ROW LEVEL SECURITY;
ALTER TABLE photos ENABLE ROW LEVEL SECURITY;

-- 允许所有人读取
CREATE POLICY cities_read_policy ON cities
  FOR SELECT USING (true);

CREATE POLICY photos_read_policy ON photos
  FOR SELECT USING (true);

-- 允许所有人写入（前端密码验证做门控）
-- 注意：这意味着知道 Supabase URL 和 anon key 的人可以写入
-- 如果你需要更严格的安全，可以改用 service_role key
CREATE POLICY cities_write_policy ON cities
  FOR INSERT WITH CHECK (true);

CREATE POLICY cities_update_policy ON cities
  FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY cities_delete_policy ON cities
  FOR DELETE USING (true);

CREATE POLICY photos_write_policy ON photos
  FOR INSERT WITH CHECK (true);

CREATE POLICY photos_update_policy ON photos
  FOR UPDATE USING (true) WITH CHECK (true);

CREATE POLICY photos_delete_policy ON photos
  FOR DELETE USING (true);

-- 5. Storage bucket 配置（需要在 Supabase Dashboard → Storage 手动创建）
-- Bucket 名称: travel-photos
-- 勾选 "Public bucket"（允许公开访问图片 URL）
-- 在 Storage → Policies 中为 travel-photos 添加策略:
--   - SELECT (读取): 允许所有人 (bucket_id = 'travel-photos')
--   - INSERT (上传): 允许所有人 (bucket_id = 'travel-photos')
--   - DELETE (删除): 允许所有人 (bucket_id = 'travel-photos')
```

- [ ] **Step 2: 提交**

```bash
cd /home/zhongxu/travel-map
git add supabase-setup.sql
git commit -m "feat: add Supabase database setup SQL with RLS policies"
```

---

### Task 9: README 部署说明

**Files:**
- Create: `travel-map/README.md`

- [ ] **Step 1: 创建 README.md**

创建 `travel-map/README.md`：

```markdown
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
```

- [ ] **Step 2: 提交**

```bash
cd /home/zhongxu/travel-map
git add README.md
git commit -m "docs: add README with deployment instructions"
```

---

### Task 10: 整体验证与修复

**Files:**
- Modify: `travel-map/travel-map.html` — 检查并修复遗漏

**说明:** 逐项验证所有功能，修复发现的问题。

- [ ] **Step 1: 功能检查清单**

在浏览器打开页面，检查以下各项：

1. 地图正常渲染（中国地图、省份边界）
2. 点击「管理」弹出密码框
3. 输入密码后进入管理模式
4. 管理抽屉列出已有城市
5. 添加城市表单：下拉选择自动填充经纬度
6. 上传照片、添加描述
7. 保存后地图上出现新标记
8. 点击标记弹出气泡，照片正常显示
9. 气泡内左右翻页
10. 删除照片
11. 删除城市
12. 响应式：缩小浏览器窗口，布局正常

- [ ] **Step 2: 修复发现的问题**

根据检查结果逐一修复。

- [ ] **Step 3: 最终提交**

```bash
cd /home/zhongxu/travel-map
git add travel-map.html
git commit -m "fix: final verification fixes"
```

---
