-- إصلاح مباشر لمشكلة "Database error granting user" في Supabase
-- هذا ملف مبسط يحتوي على الأوامر الأساسية فقط لإصلاح المشكلة

-- منح الصلاحيات الأساسية التي تحتاجها عملية تسجيل المستخدمين
GRANT USAGE ON SCHEMA auth TO anon;
GRANT SELECT ON TABLE auth.users TO anon;

GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON TABLE auth.users TO authenticated;

GRANT USAGE ON SCHEMA auth TO service_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO service_role;

-- تعطيل RLS على جداول المستخدمين
ALTER TABLE IF EXISTS auth.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;

-- منح صلاحيات على جدول المستخدمين العام (إذا كان موجودًا)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    EXECUTE 'GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO anon, authenticated;';
  END IF;
END $$; 