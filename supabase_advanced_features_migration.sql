-- =====================================================
-- Hatırlatıcı Uygulaması - İleri Seviye Özellikler Migration
-- Versiyon: 2.0.0
-- =====================================================

-- 1. Reminders tablosuna yeni alanlar ekle
ALTER TABLE reminders 
ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS attachments TEXT[],
ADD COLUMN IF NOT EXISTS shared_with TEXT,
ADD COLUMN IF NOT EXISTS is_shared BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES profiles(id);

-- 2. Reminder Shares tablosu oluştur
CREATE TABLE IF NOT EXISTS reminder_shares (
  id SERIAL PRIMARY KEY,
  reminder_id INTEGER NOT NULL REFERENCES reminders(id) ON DELETE CASCADE,
  shared_with_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  shared_by_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  can_edit BOOLEAN DEFAULT true,
  accepted BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Index'ler oluştur
CREATE INDEX IF NOT EXISTS idx_reminders_favorite ON reminders(is_favorite);
CREATE INDEX IF NOT EXISTS idx_reminders_shared ON reminders(is_shared);
CREATE INDEX IF NOT EXISTS idx_reminders_created_by ON reminders(created_by);
CREATE INDEX IF NOT EXISTS idx_reminder_shares_reminder ON reminder_shares(reminder_id);
CREATE INDEX IF NOT EXISTS idx_reminder_shares_shared_with ON reminder_shares(shared_with_user_id);
CREATE INDEX IF NOT EXISTS idx_reminder_shares_shared_by ON reminder_shares(shared_by_user_id);

-- 4. Row Level Security (RLS) Politikaları

-- Reminder Shares için RLS aktif et
ALTER TABLE reminder_shares ENABLE ROW LEVEL SECURITY;

-- Kullanıcı kendi paylaştığı hatırlatıcıları görebilir
CREATE POLICY "Users can view their shared reminders" ON reminder_shares
  FOR SELECT
  USING (
    auth.uid() = shared_by_user_id 
    OR auth.uid() = shared_with_user_id
  );

-- Kullanıcı hatırlatıcı paylaşabilir
CREATE POLICY "Users can share reminders" ON reminder_shares
  FOR INSERT
  WITH CHECK (auth.uid() = shared_by_user_id);

-- Kullanıcı kendi paylaşımlarını güncelleyebilir
CREATE POLICY "Users can update their shares" ON reminder_shares
  FOR UPDATE
  USING (auth.uid() = shared_by_user_id);

-- Kullanıcı kendi paylaşımlarını silebilir
CREATE POLICY "Users can delete their shares" ON reminder_shares
  FOR DELETE
  USING (
    auth.uid() = shared_by_user_id 
    OR auth.uid() = shared_with_user_id
  );

-- Paylaşılan hatırlatıcıları görebilme politikası güncelle
DROP POLICY IF EXISTS "Users can view their own reminders" ON reminders;
CREATE POLICY "Users can view their own and shared reminders" ON reminders
  FOR SELECT
  USING (
    auth.uid() = user_id 
    OR auth.uid() IN (
      SELECT shared_with_user_id 
      FROM reminder_shares 
      WHERE reminder_shares.reminder_id = reminders.id
    )
  );

-- 5. Trigger'lar oluştur

-- Updated_at otomatik güncelleme trigger'ı
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_reminder_shares_updated_at
  BEFORE UPDATE ON reminder_shares
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 6. Fonksiyonlar oluştur

-- Hatırlatıcı paylaşma fonksiyonu
CREATE OR REPLACE FUNCTION share_reminder(
  p_reminder_id INTEGER,
  p_user_emails TEXT[],
  p_can_edit BOOLEAN DEFAULT true
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_shared_count INTEGER := 0;
  v_result JSON;
BEGIN
  -- Her email için paylaşım oluştur
  FOREACH v_user_id IN ARRAY (
    SELECT ARRAY_AGG(id) 
    FROM profiles 
    WHERE email = ANY(p_user_emails)
  )
  LOOP
    INSERT INTO reminder_shares (
      reminder_id,
      shared_with_user_id,
      shared_by_user_id,
      can_edit
    ) VALUES (
      p_reminder_id,
      v_user_id,
      auth.uid(),
      p_can_edit
    )
    ON CONFLICT DO NOTHING;
    
    v_shared_count := v_shared_count + 1;
  END LOOP;

  -- Hatırlatıcıyı paylaşımlı olarak işaretle
  UPDATE reminders 
  SET is_shared = true 
  WHERE id = p_reminder_id;

  v_result := json_build_object(
    'success', true,
    'shared_count', v_shared_count
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Paylaşımı kaldırma fonksiyonu
CREATE OR REPLACE FUNCTION unshare_reminder(
  p_reminder_id INTEGER,
  p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_remaining_shares INTEGER;
  v_result JSON;
BEGIN
  -- Paylaşımı sil
  DELETE FROM reminder_shares
  WHERE reminder_id = p_reminder_id
    AND shared_with_user_id = p_user_id
    AND shared_by_user_id = auth.uid();

  -- Kalan paylaşım sayısını kontrol et
  SELECT COUNT(*) INTO v_remaining_shares
  FROM reminder_shares
  WHERE reminder_id = p_reminder_id;

  -- Eğer paylaşım kalmadıysa, hatırlatıcıyı paylaşımsız yap
  IF v_remaining_shares = 0 THEN
    UPDATE reminders 
    SET is_shared = false 
    WHERE id = p_reminder_id;
  END IF;

  v_result := json_build_object(
    'success', true,
    'remaining_shares', v_remaining_shares
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Kullanıcının favori hatırlatıcılarını getir
CREATE OR REPLACE FUNCTION get_favorite_reminders()
RETURNS SETOF reminders AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM reminders
  WHERE user_id = auth.uid()
    AND is_favorite = true
    AND is_deleted = false
  ORDER BY date_time ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Paylaşılan hatırlatıcıları getir
CREATE OR REPLACE FUNCTION get_shared_reminders()
RETURNS SETOF reminders AS $$
BEGIN
  RETURN QUERY
  SELECT r.* FROM reminders r
  INNER JOIN reminder_shares rs ON r.id = rs.reminder_id
  WHERE rs.shared_with_user_id = auth.uid()
    AND r.is_deleted = false
  ORDER BY r.date_time ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Hatırlatıcı istatistikleri
CREATE OR REPLACE FUNCTION get_reminder_statistics()
RETURNS JSON AS $$
DECLARE
  v_total INTEGER;
  v_completed INTEGER;
  v_active INTEGER;
  v_favorite INTEGER;
  v_shared INTEGER;
  v_recurring INTEGER;
  v_result JSON;
BEGIN
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE is_completed = true),
    COUNT(*) FILTER (WHERE is_completed = false),
    COUNT(*) FILTER (WHERE is_favorite = true),
    COUNT(*) FILTER (WHERE is_shared = true),
    COUNT(*) FILTER (WHERE is_recurring = true)
  INTO v_total, v_completed, v_active, v_favorite, v_shared, v_recurring
  FROM reminders
  WHERE user_id = auth.uid()
    AND is_deleted = false;

  v_result := json_build_object(
    'total', v_total,
    'completed', v_completed,
    'active', v_active,
    'favorite', v_favorite,
    'shared', v_shared,
    'recurring', v_recurring
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. View'lar oluştur

-- Paylaşım detayları view'ı
CREATE OR REPLACE VIEW reminder_share_details AS
SELECT 
  rs.id,
  rs.reminder_id,
  r.title AS reminder_title,
  r.description AS reminder_description,
  rs.shared_with_user_id,
  p1.email AS shared_with_email,
  p1.full_name AS shared_with_name,
  rs.shared_by_user_id,
  p2.email AS shared_by_email,
  p2.full_name AS shared_by_name,
  rs.can_edit,
  rs.accepted,
  rs.created_at
FROM reminder_shares rs
INNER JOIN reminders r ON rs.reminder_id = r.id
INNER JOIN profiles p1 ON rs.shared_with_user_id = p1.id
INNER JOIN profiles p2 ON rs.shared_by_user_id = p2.id;

-- 8. Örnek veriler (opsiyonel - test için)
-- INSERT INTO reminders (user_id, title, description, date_time, is_favorite, created_by)
-- VALUES (auth.uid(), 'Test Hatırlatıcı', 'Bu bir test hatırlatıcısıdır', NOW() + INTERVAL '1 day', true, auth.uid());

-- 9. Yetkilendirme
-- View'a erişim izni ver
GRANT SELECT ON reminder_share_details TO authenticated;

-- Fonksiyonlara erişim izni ver
GRANT EXECUTE ON FUNCTION share_reminder TO authenticated;
GRANT EXECUTE ON FUNCTION unshare_reminder TO authenticated;
GRANT EXECUTE ON FUNCTION get_favorite_reminders TO authenticated;
GRANT EXECUTE ON FUNCTION get_shared_reminders TO authenticated;
GRANT EXECUTE ON FUNCTION get_reminder_statistics TO authenticated;

-- =====================================================
-- Migration tamamlandı!
-- =====================================================

-- Kontrol sorguları:
-- SELECT * FROM reminder_shares;
-- SELECT * FROM reminder_share_details;
-- SELECT get_reminder_statistics();
-- SELECT * FROM get_favorite_reminders();
-- SELECT * FROM get_shared_reminders();

