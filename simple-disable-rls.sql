-- حل سريع لمشكلة infinite recursion في سياسات RLS
-- قم بتشغيل هذا الملف مباشرة في محرر SQL في Supabase Dashboard

-- 1. تعطيل سياسات RLS لجدول المستخدمين
-- هذا الجزء سيحل مشكلة "infinite recursion detected in policy for relation users"
DROP POLICY IF EXISTS "Users can view own data" ON "users";
DROP POLICY IF EXISTS "Users can update own data" ON "users";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "users";
DROP POLICY IF EXISTS "Allow users to view their own user data" ON "users";
DROP POLICY IF EXISTS "Allow users to update their own data" ON "users";
DROP POLICY IF EXISTS "Allow users to view their own profile" ON "users";
DROP POLICY IF EXISTS "Allow users to update their own profile" ON "users";
DROP POLICY IF EXISTS "Allow all users to view all user data" ON "users";

-- تعطيل RLS على جدول المستخدمين
ALTER TABLE "users" DISABLE ROW LEVEL SECURITY;

-- 2. تعطيل RLS على جدول الطلبات وعناصر الطلبات (اختياري)
-- يمكنك تفعيل هذا الجزء إذا استمرت المشكلة

DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert order items" ON order_items;
DROP POLICY IF EXISTS "Users can update their order items" ON order_items;
DROP POLICY IF EXISTS "Users can delete their order items" ON order_items;

ALTER TABLE order_items DISABLE ROW LEVEL SECURITY;

-- ملاحظة: هذا حل مؤقت وغير آمن. بعد إصلاح المشكلة،
-- يجب إعادة تفعيل سياسات RLS مع سياسات صحيحة. 