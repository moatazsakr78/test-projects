-- إصلاح مشكلة "Database error granting user" في Supabase
-- هذا ملف يجمع كل الإصلاحات اللازمة من ملفات متعددة

-- 1. إصلاح صلاحيات المستخدم المجهول (anon)
GRANT USAGE ON SCHEMA auth TO anon;
GRANT SELECT ON TABLE auth.users TO anon;

-- 2. إصلاح صلاحيات المستخدم المصادق عليه
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON TABLE auth.users TO authenticated;

-- 3. إصلاح صلاحيات دور الخدمة
GRANT USAGE ON SCHEMA auth TO service_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO service_role;

-- 4. تعطيل RLS على جداول المستخدمين
ALTER TABLE IF EXISTS auth.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;

-- 5. حذف السياسات القديمة التي قد تسبب تداخل أو تكرار لانهائي
DROP POLICY IF EXISTS "Users can view own data" ON "users";
DROP POLICY IF EXISTS "Users can update own data" ON "users";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "users";
DROP POLICY IF EXISTS "Allow users to view their own user data" ON "users";
DROP POLICY IF EXISTS "Allow users to update their own data" ON "users";
DROP POLICY IF EXISTS "Allow users to view their own profile" ON "users";
DROP POLICY IF EXISTS "Allow users to update their own profile" ON "users";
DROP POLICY IF EXISTS "Allow all users to view all user data" ON "users";

-- 6. منح صلاحيات على جدول المستخدمين العام (إذا كان موجودًا)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    EXECUTE 'GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO anon, authenticated;';
  END IF;
END $$;

-- 7. إعادة إنشاء سياسات بسيطة وواضحة بدون تداخل
-- فقط إذا كان تفعيل RLS ضروري (نترك هذا كتعليق الآن)
/*
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;

-- السماح للمستخدمين المجهولين بالتسجيل
CREATE POLICY "Allow anonymous users to register"
ON "users" FOR INSERT
TO anon
WITH CHECK (true);

-- السماح للمستخدمين المسجلين بتسجيل الدخول
CREATE POLICY "Allow all authenticated users to sign in" 
ON "users" FOR SELECT 
TO authenticated 
USING (true);

-- سياسة بسيطة للقراءة
CREATE POLICY "Allow users to view their own profile"
ON "users" FOR SELECT
USING (
  id = auth.uid()
);

-- سياسة بسيطة للتحديث
CREATE POLICY "Allow users to update their own profile"
ON "users" FOR UPDATE
USING (
  id = auth.uid()
);
*/

-- 8. التأكد من صحة وظائف auth
GRANT EXECUTE ON FUNCTION auth.uid() TO anon;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;
GRANT EXECUTE ON FUNCTION auth.role() TO anon;
GRANT EXECUTE ON FUNCTION auth.role() TO authenticated;
GRANT EXECUTE ON FUNCTION auth.email() TO anon;
GRANT EXECUTE ON FUNCTION auth.email() TO authenticated; 