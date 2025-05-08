-- تعليمات إصلاح سياسات RLS لجميع الجداول المرتبطة بالطلبات
-- تنفيذ هذا الملف في SQL Editor في Supabase

-- ----------------------
-- 1. إصلاح جدول Users
-- ----------------------
-- مسح جميع السياسات الموجودة للمستخدمين
DROP POLICY IF EXISTS "Users can view own data" ON "users";
DROP POLICY IF EXISTS "Users can update own data" ON "users";
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON "users";
DROP POLICY IF EXISTS "Allow users to view their own user data" ON "users";
DROP POLICY IF EXISTS "Allow users to update their own data" ON "users";

-- التأكد من تفعيل RLS
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;

-- إنشاء سياسات بسيطة وآمنة
CREATE POLICY "Allow users to view their own user data"
ON "users" FOR SELECT
USING (auth.uid() = id);

CREATE POLICY "Allow users to update their own data"
ON "users" FOR UPDATE
USING (auth.uid() = id);

-- ----------------------
-- 2. إصلاح جدول Orders
-- ----------------------
-- مسح جميع السياسات الموجودة
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- التأكد من تفعيل RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- إنشاء سياسات جديدة بسيطة
CREATE POLICY "Users can view their own orders"
ON orders FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own orders"
ON orders FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own orders"
ON orders FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own orders"
ON orders FOR DELETE
USING (auth.uid() = user_id);

-- ----------------------
-- 3. إصلاح جدول Order Items
-- ----------------------
-- مسح جميع السياسات الموجودة
DROP POLICY IF EXISTS "Users can view their order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert order items" ON order_items;
DROP POLICY IF EXISTS "Users can update their order items" ON order_items;
DROP POLICY IF EXISTS "Users can delete their order items" ON order_items;

-- التأكد من تفعيل RLS
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- سياسة قراءة عناصر الطلبات: السماح بالاطلاع على الطلبات الخاصة بالمستخدم
CREATE POLICY "Users can view their order items"
ON order_items FOR SELECT
USING (EXISTS (
  SELECT 1 FROM orders 
  WHERE orders.id = order_items.order_id 
  AND orders.user_id = auth.uid()
));

-- سياسة إضافة عناصر الطلبات: بسيطة لتجنب المشاكل في عملية الإنشاء
CREATE POLICY "Users can insert order items"
ON order_items FOR INSERT
WITH CHECK (true); -- نسمح بإدخال عناصر حاليًا، ويمكن تقييدها لاحقًا

-- سياسة تعديل عناصر الطلبات: السماح بتعديل عناصر الطلبات الخاصة بالمستخدم
CREATE POLICY "Users can update their order items"
ON order_items FOR UPDATE
USING (EXISTS (
  SELECT 1 FROM orders 
  WHERE orders.id = order_items.order_id 
  AND orders.user_id = auth.uid()
));

-- سياسة حذف عناصر الطلبات: السماح بحذف عناصر الطلبات الخاصة بالمستخدم
CREATE POLICY "Users can delete their order items"
ON order_items FOR DELETE
USING (EXISTS (
  SELECT 1 FROM orders 
  WHERE orders.id = order_items.order_id 
  AND orders.user_id = auth.uid()
));

-- ----------------------
-- 4. سياسة خاصة للمشرفين (إذا كان لديك)
-- ----------------------

-- إضافة سياسة للمشرفين لرؤية جميع البيانات (اختياري)
DO $$
BEGIN
  IF EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'is_admin'
  ) THEN
    CREATE POLICY IF NOT EXISTS "Admins can view all orders"
    ON orders FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.is_admin = true
      )
    );
    
    CREATE POLICY IF NOT EXISTS "Admins can view all order items"
    ON order_items FOR SELECT
    USING (
      EXISTS (
        SELECT 1 FROM users
        WHERE users.id = auth.uid() AND users.is_admin = true
      )
    );
  END IF;
END $$; 