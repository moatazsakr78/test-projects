-- إصلاح مشكلة "Database error granting user" في Supabase
-- استخدم هذا الملف إذا كنت تواجه مشكلة في تسجيل الدخول أو إنشاء حسابات جديدة

-- 1. التأكد من صحة الوصول إلى مخطط auth
GRANT USAGE ON SCHEMA auth TO postgres;
GRANT USAGE ON SCHEMA auth TO anon;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO service_role;

-- 2. منح صلاحيات الوصول إلى جدول auth.users
-- الصلاحيات الأساسية للمستخدم المجهول (مهم جدًا للتسجيل)
GRANT SELECT ON TABLE auth.users TO anon;
GRANT SELECT ON TABLE auth.users TO authenticated;

-- إعطاء service_role وصول كامل
GRANT ALL PRIVILEGES ON TABLE auth.users TO service_role;

-- 3. منح صلاحيات للجداول الأخرى في auth schema
GRANT SELECT ON ALL TABLES IN SCHEMA auth TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA auth TO authenticated;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO service_role;

-- 4. منح صلاحيات للتسلسلات والدوال
GRANT USAGE ON ALL SEQUENCES IN SCHEMA auth TO anon;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA auth TO authenticated;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO service_role;

GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO anon;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO authenticated;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA auth TO service_role;

-- 5. إصلاح مشكلة RLS
-- تعطيل RLS على auth.users
ALTER TABLE IF EXISTS auth.users DISABLE ROW LEVEL SECURITY;

-- 6. التأكد من وجود نسخة من auth.users في جدول public.users
-- تحقق من وجود جدول users
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    RAISE NOTICE 'جدول users موجود، نتأكد من وجود الصلاحيات المناسبة';
    
    -- التأكد من تعطيل RLS على public.users
    ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
    
    -- منح صلاحيات على public.users
    GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO anon;
    GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO authenticated;
    GRANT ALL PRIVILEGES ON TABLE public.users TO service_role;
  ELSE
    RAISE NOTICE 'جدول users غير موجود في schema public';
  END IF;
END $$;

-- 7. التأكد من صحة الوصول إلى جداول auth الأخرى المهمة
GRANT SELECT ON TABLE auth.refresh_tokens TO anon, authenticated;
GRANT SELECT ON TABLE auth.instances TO anon, authenticated;
GRANT SELECT ON TABLE auth.schema_migrations TO anon, authenticated;

-- 8. إعادة تعيين مالك مخطط auth
ALTER SCHEMA auth OWNER TO postgres;

-- 9. التأكد من صحة وظائف auth
GRANT EXECUTE ON FUNCTION auth.uid() TO anon;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;
GRANT EXECUTE ON FUNCTION auth.role() TO anon;
GRANT EXECUTE ON FUNCTION auth.role() TO authenticated;
GRANT EXECUTE ON FUNCTION auth.email() TO anon;
GRANT EXECUTE ON FUNCTION auth.email() TO authenticated;

-- ملاحظة: إذا استمرت المشكلة بعد تنفيذ هذا الملف، فقد تحتاج إلى إعادة تشغيل خدمة Supabase Auth
-- أو التحقق من إعدادات JWT في قاعدة البيانات 