-- ============================================================
-- FREELANCEMARKET — Tablas para Collab y AI Match
-- Ejecuta en SQL Editor de Supabase
-- ============================================================

-- TABLA: collab_projects
CREATE TABLE IF NOT EXISTS public.collab_projects (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  owner_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title            TEXT NOT NULL,
  description      TEXT,
  category         TEXT,
  budget           NUMERIC(10,2) DEFAULT 0,
  deadline         DATE,
  required_skills  TEXT[],
  notes            TEXT,
  status           TEXT DEFAULT 'open' CHECK (status IN ('open','progress','completed','cancelled')),
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

-- TABLA: collab_roles (plazas dentro de cada proyecto)
CREATE TABLE IF NOT EXISTS public.collab_roles (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id  UUID NOT NULL REFERENCES public.collab_projects(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  budget      NUMERIC(10,2) DEFAULT 0,
  filled      BOOLEAN DEFAULT false,
  user_id     UUID REFERENCES public.profiles(id),
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- TABLA: collab_applications (solicitudes de unirse)
CREATE TABLE IF NOT EXISTS public.collab_applications (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  project_id  UUID NOT NULL REFERENCES public.collab_projects(id) ON DELETE CASCADE,
  role_id     UUID REFERENCES public.collab_roles(id),
  applicant_id UUID NOT NULL REFERENCES public.profiles(id),
  message     TEXT,
  status      TEXT DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected')),
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE public.collab_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collab_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collab_applications ENABLE ROW LEVEL SECURITY;

-- collab_projects policies
CREATE POLICY "Anyone can view open collab projects" ON public.collab_projects
  FOR SELECT USING (status = 'open' OR auth.uid() = owner_id OR public.is_admin_or_owner());

CREATE POLICY "Authenticated users can create collab projects" ON public.collab_projects
  FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can update their projects" ON public.collab_projects
  FOR UPDATE USING (auth.uid() = owner_id OR public.is_admin_or_owner());

-- collab_roles policies
CREATE POLICY "Anyone can view collab roles" ON public.collab_roles
  FOR SELECT USING (true);

CREATE POLICY "Project owners can manage roles" ON public.collab_roles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.collab_projects WHERE id = project_id AND owner_id = auth.uid())
    OR public.is_admin_or_owner()
  );

-- collab_applications policies
CREATE POLICY "Users can view own applications" ON public.collab_applications
  FOR SELECT USING (auth.uid() = applicant_id OR EXISTS (
    SELECT 1 FROM public.collab_projects WHERE id = project_id AND owner_id = auth.uid()
  ));

CREATE POLICY "Users can create applications" ON public.collab_applications
  FOR INSERT WITH CHECK (auth.uid() = applicant_id);

CREATE POLICY "Project owners can update application status" ON public.collab_applications
  FOR UPDATE USING (EXISTS (
    SELECT 1 FROM public.collab_projects WHERE id = project_id AND owner_id = auth.uid()
  ));
