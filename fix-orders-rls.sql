-- تعليمات إصلاح سياسات RLS لطلبات المستخدمين
-- تنفيذ هذا الملف في SQL Editor في Supabase

-- 1. إعادة ضبط سياسات RLS لجدول orders
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- 2. إعادة ضبط سياسات RLS لجدول order_items
DROP POLICY IF EXISTS "Users can view their order items" ON order_items;
DROP POLICY IF EXISTS "Users can insert order items" ON order_items;
DROP POLICY IF EXISTS "Users can update their order items" ON order_items;
DROP POLICY IF EXISTS "Users can delete their order items" ON order_items;

-- 3. التأكد من تفعيل RLS على الجداول
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- 4. إنشاء سياسات جديدة لجدول orders

-- سياسة للقراءة: المستخدم يمكنه قراءة طلباته فقط
CREATE POLICY "Users can view their own orders"
ON orders FOR SELECT
USING (auth.uid() = user_id);

-- سياسة للإضافة: المستخدم يمكنه إضافة طلبات باسمه فقط
CREATE POLICY "Users can insert their own orders"
ON orders FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- سياسة للتعديل: المستخدم يمكنه تعديل طلباته فقط
CREATE POLICY "Users can update their own orders"
ON orders FOR UPDATE
USING (auth.uid() = user_id);

-- سياسة للحذف: المستخدم يمكنه حذف طلباته فقط
CREATE POLICY "Users can delete their own orders"
ON orders FOR DELETE
USING (auth.uid() = user_id);

-- 5. إنشاء سياسات لجدول order_items

-- سياسة قراءة عناصر الطلبات: المستخدم يمكنه قراءة عناصر طلباته فقط
CREATE POLICY "Users can view their order items"
ON order_items FOR SELECT
USING (
  order_id IN (
    SELECT id FROM orders WHERE user_id = auth.uid()
  )
);

-- سياسة إضافة عناصر طلبات: المستخدم يمكنه إضافة عناصر لطلباته فقط
CREATE POLICY "Users can insert order items"
ON order_items FOR INSERT
WITH CHECK (
  order_id IN (
    SELECT id FROM orders WHERE user_id = auth.uid()
  )
);

-- سياسة تعديل عناصر الطلبات: المستخدم يمكنه تعديل عناصر طلباته فقط
CREATE POLICY "Users can update order items"
ON order_items FOR UPDATE
USING (
  order_id IN (
    SELECT id FROM orders WHERE user_id = auth.uid()
  )
);

-- سياسة حذف عناصر الطلبات: المستخدم يمكنه حذف عناصر طلباته فقط
CREATE POLICY "Users can delete order items"
ON order_items FOR DELETE
USING (
  order_id IN (
    SELECT id FROM orders WHERE user_id = auth.uid()
  )
);

-- 6. التأكد من وجود حقل user_id في جدول orders إذا لم يكن موجودًا
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT FROM information_schema.columns 
    WHERE table_name = 'orders' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE orders ADD COLUMN user_id UUID NOT NULL REFERENCES auth.users(id);
  END IF;
END $$; 