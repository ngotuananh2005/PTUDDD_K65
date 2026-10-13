-- ==============================================================================
-- SUPABASE DATABASE SCHEMA CHO ỨNG DỤNG CASHEW STUDYDOCS (v2 - Firebase Auth)
-- LƯU Ý: App dùng Firebase Auth, không phải Supabase Auth.
-- Vì vậy:
--   - profiles.id = Firebase UID (TEXT, không phải UUID)
--   - documents.owner_id = Firebase UID (TEXT)
--   - documents.id = TEXT (có thể là UUID hoặc ID tự sinh từ app)
-- ==============================================================================

-- BẬT EXTENSION cần thiết
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;

-- ==============================================================================
-- 1. BẢNG NGƯỜI DÙNG / PROFILES
-- id = Firebase UID (TEXT, ví dụ: "hH3Wo80Ne5d0cZb6gNPAJhpyx292")
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id TEXT PRIMARY KEY,            -- Firebase UID (không phải UUID Supabase)
    email TEXT NOT NULL UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 2. BẢNG TÀI LIỆU HỌC TẬP (DOCUMENTS)
-- id = TEXT (có thể là UUID hoặc ID tự sinh từ app như "doc_abc123")
-- owner_id = Firebase UID (TEXT)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    owner_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    document_type TEXT NOT NULL DEFAULT 'other',
    status TEXT NOT NULL DEFAULT 'pending',
    priority TEXT NOT NULL DEFAULT 'medium',
    file_url TEXT DEFAULT '',               -- URL từ Firebase Storage
    storage_path TEXT DEFAULT '',           -- Đường dẫn: documents/{userId}/{docId}/{fileName}
    file_name TEXT DEFAULT '',
    file_size BIGINT DEFAULT 0,
    page_count INTEGER DEFAULT 0,
    estimated_minutes INTEGER DEFAULT 30,
    is_pinned BOOLEAN DEFAULT false,
    tags TEXT[] DEFAULT '{}',
    due_date TIMESTAMPTZ,
    completed_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 3. BẢNG QUYỀN CHIA SẺ TÀI LIỆU (DOCUMENT_PERMISSIONS)
-- grantee_id = Firebase UID (TEXT, tham chiếu profiles.id)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.document_permissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id TEXT NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    grantee_id TEXT NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    permission_level TEXT NOT NULL CHECK (permission_level IN ('viewer', 'editor')),
    created_at TIMESTAMPTZ DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE (document_id, grantee_id)
);

ALTER TABLE public.document_permissions ENABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- CHÍNH SÁCH BẢO MẬT ROW LEVEL SECURITY (RLS)
-- LƯU Ý: App dùng Firebase Auth nên auth.uid() = NULL với anon key.
-- Bảo mật tầng ứng dụng: chỉ upsert với Firebase UID chính xác.
-- ==============================================================================

-- A. CHÍNH SÁCH CHO BẢNG PROFILES
-- Cho phép anon đọc profile để tìm email khi chia sẻ tài liệu
CREATE POLICY "profiles_select_all"
ON public.profiles FOR SELECT
TO anon, authenticated
USING (true);

-- Cho phép anon INSERT/UPDATE profile (Firebase Auth bridge - app kiểm soát UID)
CREATE POLICY "profiles_insert_all"
ON public.profiles FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "profiles_update_all"
ON public.profiles FOR UPDATE
TO anon, authenticated
USING (true);

-- B. CHÍNH SÁCH CHO BẢNG DOCUMENTS
-- SELECT: Chủ sở hữu HOẶC người được cấp quyền
CREATE POLICY "documents_select"
ON public.documents FOR SELECT
TO anon, authenticated
USING (true);   -- App lọc theo owner_id ở tầng query

-- INSERT: Cho phép tạo tài liệu mới (app truyền owner_id = Firebase UID)
CREATE POLICY "documents_insert"
ON public.documents FOR INSERT
TO anon, authenticated
WITH CHECK (true);

-- UPDATE: Cho phép sửa (app kiểm tra owner_id trước khi gọi)
CREATE POLICY "documents_update"
ON public.documents FOR UPDATE
TO anon, authenticated
USING (true);

-- DELETE: Cho phép xóa (app kiểm tra owner_id trước khi gọi)
CREATE POLICY "documents_delete"
ON public.documents FOR DELETE
TO anon, authenticated
USING (true);

-- C. CHÍNH SÁCH CHO BẢNG DOCUMENT_PERMISSIONS
CREATE POLICY "permissions_select"
ON public.document_permissions FOR SELECT
TO anon, authenticated
USING (true);

CREATE POLICY "permissions_insert"
ON public.document_permissions FOR INSERT
TO anon, authenticated
WITH CHECK (true);

CREATE POLICY "permissions_update"
ON public.document_permissions FOR UPDATE
TO anon, authenticated
USING (true);

CREATE POLICY "permissions_delete"
ON public.document_permissions FOR DELETE
TO anon, authenticated
USING (true);

-- ==============================================================================
-- INDEX TỐI ƯU HÓA TRUY VẤN
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_documents_owner ON public.documents(owner_id);
CREATE INDEX IF NOT EXISTS idx_documents_course ON public.documents(course_id);
CREATE INDEX IF NOT EXISTS idx_documents_title_trgm ON public.documents USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_documents_desc_trgm ON public.documents USING gin (description gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_permissions_doc ON public.document_permissions(document_id);
CREATE INDEX IF NOT EXISTS idx_permissions_grantee ON public.document_permissions(grantee_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ==============================================================================
-- TRIGGER tự động cập nhật updated_at
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER on_documents_updated
BEFORE UPDATE ON public.documents
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE TRIGGER on_profiles_updated
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
