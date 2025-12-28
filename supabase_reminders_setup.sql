-- Reminders tablosu oluştur (Türkçe karakter desteği ile)
CREATE TABLE IF NOT EXISTS reminders (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT COLLATE "tr_TR" NOT NULL,
  description TEXT COLLATE "tr_TR" NOT NULL DEFAULT '',
  date_time TIMESTAMPTZ NOT NULL,
  is_recurring BOOLEAN NOT NULL DEFAULT false,
  category TEXT COLLATE "tr_TR" NOT NULL DEFAULT 'Genel',
  is_completed BOOLEAN NOT NULL DEFAULT false,
  is_all_day BOOLEAN NOT NULL DEFAULT false,
  recurrence_type TEXT NOT NULL DEFAULT 'none',
  weekly_days TEXT DEFAULT NULL,
  monthly_day INTEGER DEFAULT NULL,
  notification_before_minutes INTEGER NOT NULL DEFAULT 0,
  priority TEXT NOT NULL DEFAULT 'normal',
  color_tag INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index'ler oluştur (performans için)
CREATE INDEX IF NOT EXISTS reminders_user_id_idx ON reminders(user_id);
CREATE INDEX IF NOT EXISTS reminders_date_time_idx ON reminders(date_time);
CREATE INDEX IF NOT EXISTS reminders_category_idx ON reminders(category);
CREATE INDEX IF NOT EXISTS reminders_is_completed_idx ON reminders(is_completed);

-- Updated_at trigger'ı
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_reminders_updated_at BEFORE UPDATE ON reminders
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) politikaları
ALTER TABLE reminders ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi hatırlatıcılarını görebilir
CREATE POLICY "Users can view their own reminders"
ON reminders FOR SELECT
USING (auth.uid() = user_id);

-- Kullanıcılar sadece kendi hatırlatıcılarını ekleyebilir
CREATE POLICY "Users can insert their own reminders"
ON reminders FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Kullanıcılar sadece kendi hatırlatıcılarını güncelleyebilir
CREATE POLICY "Users can update their own reminders"
ON reminders FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Kullanıcılar sadece kendi hatırlatıcılarını silebilir
CREATE POLICY "Users can delete their own reminders"
ON reminders FOR DELETE
USING (auth.uid() = user_id);

