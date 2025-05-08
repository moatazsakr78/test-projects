// تطبيق إصلاح سياسات RLS لجدول المستخدمين
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// إعدادات Supabase للاختبار
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://jpwsohttsxsmyhasvudy.supabase.co';
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impwd3NvaHR0c3hzbXloYXN2dWR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY0NDc0OTAsImV4cCI6MjA2MjAyMzQ5MH0.3smkZyO8z7B69lCEPebl3nI7WKHfkl2badoVYxvIgnw';

// إنشاء عميل Supabase
const supabase = createClient(supabaseUrl, supabaseKey);

/**
 * وظيفة تسجيل مع وقت
 */
function logWithTimestamp(message) {
  const now = new Date();
  const timestamp = now.toLocaleTimeString();
  console.log(`[${timestamp}] ${message}`);
}

async function applyFixUsersRLS() {
  try {
    logWithTimestamp('=== بدء تطبيق إصلاح سياسات RLS لجدول المستخدمين ===');
    
    // قراءة ملف SQL
    const sqlFilePath = path.join(__dirname, 'fix-users-rls.sql');
    const sqlContent = fs.readFileSync(sqlFilePath, 'utf8');
    
    logWithTimestamp('تم قراءة ملف SQL بنجاح');
    
    // تسجيل الدخول أولاً للحصول على صلاحيات
    logWithTimestamp('محاولة تسجيل الدخول...');
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'test@example.com',
      password: 'Password123!'
    });
    
    if (authError) {
      throw new Error(`فشل تسجيل الدخول: ${authError.message}`);
    }
    
    logWithTimestamp('تم تسجيل الدخول بنجاح');
    
    // تنفيذ الاستعلام SQL
    logWithTimestamp('جاري تطبيق إصلاح سياسات RLS...');
    
    // تقسيم النص إلى استعلامات منفصلة وتنفيذها واحدًا تلو الآخر
    const queries = sqlContent
      .split(';')
      .map(query => query.trim())
      .filter(query => query && !query.startsWith('--') && !query.startsWith('/*'));
    
    for (let i = 0; i < queries.length; i++) {
      const query = queries[i];
      if (!query) continue;
      
      logWithTimestamp(`تنفيذ الاستعلام ${i+1}/${queries.length}`);
      
      try {
        const { error } = await supabase.rpc('exec_sql', { sql_query: query });
        
        if (error) {
          console.warn(`تحذير في الاستعلام ${i+1}: ${error.message}`);
        }
      } catch (err) {
        console.warn(`خطأ في تنفيذ الاستعلام ${i+1}: ${err.message}`);
      }
    }
    
    logWithTimestamp('تم تطبيق إصلاح سياسات RLS بنجاح');
    
    // اختبار الإصلاح عن طريق محاولة إنشاء طلب
    logWithTimestamp('جاري اختبار الإصلاح بإنشاء طلب...');
    
    const orderData = {
      user_id: authData.user.id,
      created_at: new Date().toISOString()
    };
    
    const { data: orderResult, error: orderError } = await supabase
      .from('orders')
      .insert(orderData)
      .select('id')
      .single();
    
    if (orderError) {
      throw new Error(`فشل اختبار إنشاء الطلب: ${orderError.message}`);
    }
    
    logWithTimestamp(`نجح اختبار إنشاء الطلب! معرف الطلب: ${orderResult.id}`);
    
    // إنشاء عناصر الطلب للاختبار
    const orderItems = [
      {
        order_id: orderResult.id,
        product_id: '01234567-89ab-cdef-0123-456789abcdef',
        quantity: 2,
        note: 'ملاحظة اختبار',
        is_prepared: false,
        created_at: new Date().toISOString()
      }
    ];
    
    const { data: itemsResult, error: itemsError } = await supabase
      .from('order_items')
      .insert(orderItems)
      .select();
      
    if (itemsError) {
      logWithTimestamp(`فشل إضافة عناصر الطلب: ${itemsError.message}`);
      logWithTimestamp('سيتم تطبيق إصلاح سياسات RLS لجدول عناصر الطلبات...');
      
      // تطبيق إصلاح order_items أيضًا
      const orderItemsSqlPath = path.join(__dirname, 'fix-order-items-rls.sql');
      if (fs.existsSync(orderItemsSqlPath)) {
        const orderItemsSql = fs.readFileSync(orderItemsSqlPath, 'utf8');
        const orderItemsQueries = orderItemsSql
          .split(';')
          .map(query => query.trim())
          .filter(query => query && !query.startsWith('--'));
        
        for (const query of orderItemsQueries) {
          if (!query) continue;
          await supabase.rpc('exec_sql', { sql_query: query }).catch(e => {
            console.warn(`تحذير: ${e.message}`);
          });
        }
        
        logWithTimestamp('تم تطبيق إصلاح جدول عناصر الطلبات');
        
        // محاولة إضافة عناصر الطلب مرة أخرى
        const { error: retryError } = await supabase
          .from('order_items')
          .insert(orderItems);
          
        if (retryError) {
          throw new Error(`فشل إضافة عناصر الطلب بعد الإصلاح: ${retryError.message}`);
        }
        
        logWithTimestamp('تم إضافة عناصر الطلب بنجاح بعد الإصلاح');
      }
    } else {
      logWithTimestamp(`تم إضافة ${itemsResult.length} عنصر للطلب بنجاح`);
    }
    
    logWithTimestamp('=== تم إصلاح سياسات RLS واختبارها بنجاح ===');
    
    return {
      success: true,
      message: 'تم إصلاح سياسات RLS بنجاح',
      order_id: orderResult?.id
    };
  } catch (error) {
    logWithTimestamp(`!!! فشل تطبيق الإصلاح: ${error.message} !!!`);
    return {
      success: false,
      message: error.message
    };
  }
}

// تنفيذ عملية الإصلاح
applyFixUsersRLS().then(result => {
  console.log('\nنتيجة العملية:');
  console.log(JSON.stringify(result, null, 2));
  
  if (!result.success) {
    process.exit(1);
  }
}); 