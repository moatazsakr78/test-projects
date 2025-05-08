-- إصلاح مشكلة "infinite recursion" في سياسات جدول users
-- استخدم هذا الملف إذا كنت تواجه رسالة خطأ "infinite recursion detected in policy for relation users"

-- 1. حذف السياسات الحالية لجدول المستخدمين التي قد تسبب المشكلة
DROP POLICY IF EXISTS "Users can view own data" ON "users";
DROP POLICY IF EXISTS "Users can update own data" ON "users";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "users";
DROP POLICY IF EXISTS "Allow users to view their own user data" ON "users";
DROP POLICY IF EXISTS "Allow users to update their own data" ON "users";
DROP POLICY IF EXISTS "Allow users to view their own profile" ON "users";
DROP POLICY IF EXISTS "Allow users to update their own profile" ON "users";
DROP POLICY IF EXISTS "Allow all users to view all user data" ON "users";

-- 2. تعطيل سياسات RLS مؤقتًا لجدول المستخدمين (لإصلاح المشكلة أولاً)
ALTER TABLE "users" DISABLE ROW LEVEL SECURITY;

-- 3. إعادة تفعيل RLS مع سياسات بسيطة غير متداخلة
-- تم إزالة التعليق لتطبيق هذه السياسات

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

-- 4. إذا كنت تستخدم جدول profiles منفصل، فقم بإصلاح سياساته أيضًا
DROP POLICY IF EXISTS "Allow users to view own profile" ON "profiles";
DROP POLICY IF EXISTS "Allow users to update own profile" ON "profiles";

-- أزل التعليق عن هذا الجزء إذا كان لديك جدول profiles
/*
ALTER TABLE "profiles" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow users to view own profile"
ON "profiles" FOR SELECT
USING (
  user_id = auth.uid()
);

CREATE POLICY "Allow users to update own profile"
ON "profiles" FOR UPDATE
USING (
  user_id = auth.uid()
);
*/

-- ملاحظة هامة: إذا استمرت المشكلة، جرب تشغيل ملف simple-disable-rls.sql
-- الذي يقوم بتعطيل RLS بشكل كامل كحل مؤقت 