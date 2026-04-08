-- ============================================================
-- FREELANCEMARKET — Supabase SQL Schema
-- Ejecuta este SQL en el SQL Editor de tu proyecto Supabase
-- Dashboard: https://supabase.com/dashboard → SQL Editor
-- ============================================================

-- EXTENSIONES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- TABLA: profiles (extiende auth.users)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username      TEXT UNIQUE,
  full_name     TEXT,
  avatar_url    TEXT,
  bio           TEXT,
  location      TEXT,
  website       TEXT,
  skills        TEXT[],
  languages     TEXT[],
  is_seller     BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

-- Auto-crear perfil al registrarse
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, full_name, avatar_url)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- TABLA: services
-- ============================================================
CREATE TABLE IF NOT EXISTS public.services (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id        UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title          TEXT NOT NULL,
  description    TEXT,
  requirements   TEXT,
  category       TEXT,
  subcategory    TEXT,
  cover_emoji    TEXT DEFAULT '🎨',
  cover_url      TEXT,
  tags           TEXT[],
  packages       JSONB,          -- [{name, description, price, delivery_days, revisions}]
  price_from     NUMERIC(10,2) DEFAULT 0,
  status         TEXT DEFAULT 'draft' CHECK (status IN ('draft','active','paused')),
  rating         NUMERIC(3,2) DEFAULT 5.0,
  reviews_count  INTEGER DEFAULT 0,
  orders_count   INTEGER DEFAULT 0,
  views          INTEGER DEFAULT 0,
  created_at     TIMESTAMPTZ DEFAULT now(),
  updated_at     TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- TABLA: orders
-- ============================================================
CREATE TABLE IF NOT EXISTS public.orders (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_id     UUID REFERENCES public.services(id) ON DELETE SET NULL,
  buyer_id       UUID NOT NULL REFERENCES public.profiles(id),
  seller_id      UUID NOT NULL REFERENCES public.profiles(id),
  package_name   TEXT,
  amount         NUMERIC(10,2) NOT NULL,
  delivery_days  INTEGER,
  requirements   TEXT,
  status         TEXT DEFAULT 'pending' CHECK (status IN ('pending','in_progress','delivered','revision','completed','cancelled')),
  delivered_at   TIMESTAMPTZ,
  completed_at   TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT now(),
  updated_at     TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- TABLA: reviews
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id    UUID UNIQUE REFERENCES public.orders(id) ON DELETE CASCADE,
  service_id  UUID REFERENCES public.services(id) ON DELETE CASCADE,
  reviewer_id UUID REFERENCES public.profiles(id),
  rating      INTEGER CHECK (rating BETWEEN 1 AND 5),
  comment     TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Update service rating after review
CREATE OR REPLACE FUNCTION update_service_rating()
RETURNS trigger AS $$
BEGIN
  UPDATE public.services
  SET 
    rating = (SELECT AVG(rating) FROM public.reviews WHERE service_id = NEW.service_id),
    reviews_count = (SELECT COUNT(*) FROM public.reviews WHERE service_id = NEW.service_id)
  WHERE id = NEW.service_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_review_created ON public.reviews;
CREATE TRIGGER on_review_created
  AFTER INSERT ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION update_service_rating();

-- ============================================================
-- TABLA: conversations
-- ============================================================
CREATE TABLE IF NOT EXISTS public.conversations (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user1_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user2_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user1_id, user2_id)
);

-- ============================================================
-- TABLA: messages
-- ============================================================
CREATE TABLE IF NOT EXISTS public.messages (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id  UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id        UUID NOT NULL REFERENCES public.profiles(id),
  receiver_id      UUID,
  content          TEXT NOT NULL,
  read             BOOLEAN DEFAULT false,
  created_at       TIMESTAMPTZ DEFAULT now()
);

-- Update conversation timestamp on new message
CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS trigger AS $$
BEGIN
  UPDATE public.conversations SET updated_at = now() WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_message_created ON public.messages;
CREATE TRIGGER on_message_created
  AFTER INSERT ON public.messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_timestamp();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Services
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Active services are viewable by everyone" ON public.services FOR SELECT USING (status = 'active' OR auth.uid() = user_id);
CREATE POLICY "Users can insert own services" ON public.services FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own services" ON public.services FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own services" ON public.services FOR DELETE USING (auth.uid() = user_id);

-- Orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their orders" ON public.orders FOR SELECT USING (auth.uid() = buyer_id OR auth.uid() = seller_id);
CREATE POLICY "Buyers can create orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = buyer_id);
CREATE POLICY "Order parties can update" ON public.orders FOR UPDATE USING (auth.uid() = buyer_id OR auth.uid() = seller_id);

-- Reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reviews are public" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Buyers can create reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);

-- Conversations
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own conversations" ON public.conversations FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Authenticated users can create conversations" ON public.conversations FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);
CREATE POLICY "Conversation parties can update" ON public.conversations FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- Messages
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view messages in their conversations" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.conversations WHERE id = conversation_id AND (user1_id = auth.uid() OR user2_id = auth.uid()))
);
CREATE POLICY "Users can send messages" ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can update read status" ON public.messages FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.conversations WHERE id = conversation_id AND (user1_id = auth.uid() OR user2_id = auth.uid()))
);

-- ============================================================
-- REALTIME
-- Habilita realtime para mensajes en el Dashboard:
-- Database → Replication → Habilita "messages" table
-- ============================================================

-- ============================================================
-- DATOS DE EJEMPLO (opcional)
-- ============================================================
-- Descomenta para insertar datos de prueba después de crear usuarios
/*
INSERT INTO public.services (user_id, title, description, category, cover_emoji, price_from, status, tags) VALUES
  ('TU-USER-UUID', 'Diseñaré tu logo profesional en 24h', 'Soy diseñador gráfico con 5 años de experiencia...', 'design', '🎨', 29.99, 'active', ARRAY['logo', 'diseño', 'branding']),
  ('TU-USER-UUID', 'Desarrollaré tu landing page en React', 'Frontend developer especializado en React y Next.js...', 'dev', '💻', 149.00, 'active', ARRAY['react', 'web', 'frontend']);
*/
