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
