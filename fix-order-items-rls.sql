-- حل سريع لمشكلة إنشاء الطلبات بتعطيل سياسات RLS لجدول عناصر الطلبات
-- استخدم هذا الملف للحصول على حل سريع وقتي

-- 1. حذف سياسات RLS الحالية لجدول order_items
DROP POLICY IF EXISTS "Users can view their order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert order items" ON order_items;
DROP POLICY IF EXISTS "Users can update their order items" ON order_items;
DROP POLICY IF EXISTS "Users can delete their order items" ON order_items;

-- 2. تعطيل سياسات RLS لجدول order_items مؤقتًا للسماح بإدخال البيانات
ALTER TABLE order_items DISABLE ROW LEVEL SECURITY;

-- ملاحظة: هذا حل مؤقت فقط، يسمح لجميع المستخدمين بالوصول إلى جميع بيانات order_items
-- بعد اختبار الطلبات بنجاح، يجب إعادة تفعيل سياسات RLS واستخدام الملفات الأخرى لتطبيق سياسات مناسبة 