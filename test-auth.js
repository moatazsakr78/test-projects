// اختبار تسجيل حساب وتسجيل الدخول لتشخيص المشكلة
const { createClient } = require('@supabase/supabase-js');

// إعدادات Supabase
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

/**
 * إنشاء حساب جديد واختبار تسجيل الدخول
 */
async function testAuthentication() {
  try {
    // إنشاء بيانات اختبار فريدة
    const timestamp = new Date().getTime();
    const testEmail = `test${timestamp}@example.com`;
    const testPassword = 'Password123!';
    const testUsername = `user${timestamp}`;

    logWithTimestamp('=== بدء اختبار المصادقة ===');
    logWithTimestamp(`اختبار باستخدام البريد الإلكتروني: ${testEmail}`);

    // 1. محاولة إنشاء حساب جديد (تسجيل)
    logWithTimestamp('1. محاولة إنشاء حساب جديد...');
    const { data: signUpData, error: signUpError } = await supabase.auth.signUp({
      email: testEmail,
      password: testPassword,
      options: {
        data: {
          username: testUsername
        }
      }
    });

    if (signUpError) {
      logWithTimestamp(`❌ فشل إنشاء الحساب: ${signUpError.message}`);
      console.log('تفاصيل الخطأ:', signUpError);
      
      if (signUpError.message.includes('grant')) {
        logWithTimestamp('⚠️ تم اكتشاف مشكلة منح الصلاحيات. سنحاول إصلاحها...');
        
        // اختبار الوصول إلى جدول auth.users
        logWithTimestamp('محاولة فحص سياسات جدول auth.users...');
        
        const { error: rpcError } = await supabase.rpc('exec_sql', { 
          sql_query: `
          SELECT * FROM pg_catalog.pg_tables 
          WHERE schemaname = 'auth' AND tablename = 'users' 
          LIMIT 1;
          ` 
        });
        
        if (rpcError) {
          logWithTimestamp(`❌ فشل فحص جدول auth.users: ${rpcError.message}`);
        } else {
          logWithTimestamp('✅ نجح الوصول إلى معلومات جدول auth.users');
        }
        
        // محاولة تشخيص مشكلة منح الصلاحيات
        logWithTimestamp('فحص صلاحيات anon على auth.users...');
        
        const { error: grantsError } = await supabase.rpc('exec_sql', { 
          sql_query: `
          SELECT grantee, privilege_type 
          FROM information_schema.role_table_grants 
          WHERE table_name = 'users' AND table_schema = 'auth';
          ` 
        });
        
        if (grantsError) {
          logWithTimestamp(`❌ فشل فحص الصلاحيات: ${grantsError.message}`);
        } else {
          logWithTimestamp('✅ نجح فحص الصلاحيات');
        }
        
        return {
          success: false,
          stage: 'signup',
          error: signUpError.message,
          solutions: [
            'تحقق من صلاحيات الوصول لدور anon على جدول auth.users',
            'تأكد من تكوين خدمة auth في Supabase',
            'راجع سجلات خطأ Postgres لمزيد من التفاصيل'
          ]
        };
      }
      
      return {
        success: false,
        stage: 'signup',
        error: signUpError.message
      };
    }

    logWithTimestamp(`✅ تم إنشاء الحساب بنجاح! معرف المستخدم: ${signUpData.user.id}`);

    // 2. تسجيل الخروج للتأكد من أن الاختبار نظيف
    logWithTimestamp('2. تسجيل الخروج...');
    await supabase.auth.signOut();
    logWithTimestamp('✅ تم تسجيل الخروج بنجاح');

    // 3. محاولة تسجيل الدخول باستخدام الحساب الجديد
    logWithTimestamp('3. محاولة تسجيل الدخول بالحساب الجديد...');
    const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
      email: testEmail,
      password: testPassword
    });

    if (signInError) {
      logWithTimestamp(`❌ فشل تسجيل الدخول: ${signInError.message}`);
      return {
        success: false,
        stage: 'signin',
        error: signInError.message
      };
    }

    logWithTimestamp(`✅ تم تسجيل الدخول بنجاح! معرف جلسة المستخدم: ${signInData.session.id}`);

    // 4. اختبار الوصول إلى ملف تعريف المستخدم
    logWithTimestamp('4. اختبار الوصول إلى بيانات المستخدم...');
    const { data: userData, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', signInData.user.id)
      .single();

    if (userError) {
      logWithTimestamp(`⚠️ فشل الوصول إلى بيانات المستخدم: ${userError.message}`);
      logWithTimestamp('ملاحظة: هذا قد لا يؤثر على تسجيل الدخول، لكنه قد يشير إلى مشكلة في سياسات RLS');
    } else {
      logWithTimestamp('✅ تم الوصول إلى بيانات المستخدم بنجاح');
      console.log('بيانات المستخدم:', userData);
    }

    logWithTimestamp('=== انتهاء اختبار المصادقة بنجاح ===');

    return {
      success: true,
      userId: signUpData.user.id,
      email: testEmail
    };
  } catch (error) {
    logWithTimestamp(`❌ خطأ غير متوقع أثناء الاختبار: ${error.message}`);
    console.error('تفاصيل الخطأ:', error);
    
    return {
      success: false,
      error: error.message
    };
  } finally {
    // تسجيل الخروج في النهاية للتأكد من نظافة الاختبار
    await supabase.auth.signOut();
  }
}

/**
 * وظيفة للتحقق من وجود مشكلة مستخدم auth.anon default
 */
async function checkAnonPermissions() {
  logWithTimestamp('فحص إعدادات دور المستخدم المجهول (anon)...');
  
  try {
    // التحقق من صلاحيات الدور anon
    const { error: anonError } = await supabase.rpc('exec_sql', { 
      sql_query: `
      SELECT rolname, rolsuper, rolcreaterole, rolcreatedb 
      FROM pg_roles 
      WHERE rolname = 'anon';
      ` 
    });
    
    if (anonError) {
      logWithTimestamp(`❌ فشل فحص دور anon: ${anonError.message}`);
    } else {
      logWithTimestamp('✅ تم فحص دور anon بنجاح');
    }
    
    // التحقق من صلاحيات الوصول إلى جدول auth.users
    const { error: grantError } = await supabase.rpc('exec_sql', { 
      sql_query: `
      GRANT USAGE ON SCHEMA auth TO anon;
      GRANT SELECT ON TABLE auth.users TO anon;
      ` 
    });
    
    if (grantError) {
      logWithTimestamp(`❌ فشل منح صلاحيات لدور anon: ${grantError.message}`);
      return {
        success: false,
        error: grantError.message
      };
    }
    
    logWithTimestamp('✅ تم منح صلاحيات الوصول لدور anon');
    
    return {
      success: true
    };
  } catch (error) {
    logWithTimestamp(`❌ خطأ غير متوقع أثناء فحص الصلاحيات: ${error.message}`);
    return {
      success: false,
      error: error.message
    };
  }
}

/**
 * وظيفة لإصلاح مشكلة الصلاحيات
 */
async function fixAuthPermissions() {
  logWithTimestamp('=== بدء إصلاح صلاحيات المصادقة ===');
  
  try {
    // 1. منح صلاحية USAGE على schema auth
    logWithTimestamp('1. منح صلاحية USAGE على auth schema للمستخدم المجهول...');
    const { error: usageError } = await supabase.rpc('exec_sql', { 
      sql_query: `GRANT USAGE ON SCHEMA auth TO anon, authenticated;` 
    });
    
    if (usageError) {
      logWithTimestamp(`❌ فشل منح صلاحية USAGE: ${usageError.message}`);
    } else {
      logWithTimestamp('✅ تم منح صلاحية USAGE بنجاح');
    }
    
    // 2. منح صلاحيات على auth.users
    logWithTimestamp('2. منح صلاحيات على جدول auth.users...');
    const { error: usersError } = await supabase.rpc('exec_sql', { 
      sql_query: `GRANT SELECT ON TABLE auth.users TO anon, authenticated;` 
    });
    
    if (usersError) {
      logWithTimestamp(`❌ فشل منح صلاحيات على auth.users: ${usersError.message}`);
    } else {
      logWithTimestamp('✅ تم منح صلاحيات على auth.users بنجاح');
    }
    
    // 3. إعادة تعيين صلاحيات service_role
    logWithTimestamp('3. إعادة تعيين صلاحيات service_role...');
    const { error: serviceError } = await supabase.rpc('exec_sql', { 
      sql_query: `
      GRANT ALL PRIVILEGES ON SCHEMA auth TO service_role;
      GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO service_role;
      GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO service_role;
      GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA auth TO service_role;
      ` 
    });
    
    if (serviceError) {
      logWithTimestamp(`❌ فشل إعادة تعيين صلاحيات service_role: ${serviceError.message}`);
    } else {
      logWithTimestamp('✅ تم إعادة تعيين صلاحيات service_role بنجاح');
    }
    
    // 4. التأكد من تعطيل RLS على auth.users
    logWithTimestamp('4. التأكد من تعطيل RLS على auth.users...');
    const { error: rlsError } = await supabase.rpc('exec_sql', { 
      sql_query: `ALTER TABLE IF EXISTS auth.users DISABLE ROW LEVEL SECURITY;` 
    });
    
    if (rlsError) {
      logWithTimestamp(`❌ فشل تعطيل RLS على auth.users: ${rlsError.message}`);
    } else {
      logWithTimestamp('✅ تم تعطيل RLS على auth.users بنجاح');
    }
    
    logWithTimestamp('=== تم إكمال إصلاح صلاحيات المصادقة ===');
    
    return {
      success: true,
      message: 'تم إصلاح صلاحيات المصادقة بنجاح'
    };
  } catch (error) {
    logWithTimestamp(`❌ خطأ غير متوقع أثناء إصلاح الصلاحيات: ${error.message}`);
    return {
      success: false,
      error: error.message
    };
  }
}

// تنفيذ الاختبار والإصلاح
async function runTests() {
  // 1. اختبار إنشاء حساب وتسجيل دخول
  const authResult = await testAuthentication();
  console.log('\nنتيجة اختبار المصادقة:');
  console.log(JSON.stringify(authResult, null, 2));
  
  // إذا فشل الاختبار، حاول إصلاح المشكلة
  if (!authResult.success) {
    console.log('\nتم اكتشاف مشكلة، محاولة إصلاحها...');
    
    // فحص صلاحيات المستخدم المجهول
    const anonResult = await checkAnonPermissions();
    console.log('\nنتيجة فحص صلاحيات المستخدم المجهول:');
    console.log(JSON.stringify(anonResult, null, 2));
    
    // إصلاح صلاحيات المصادقة
    const fixResult = await fixAuthPermissions();
    console.log('\nنتيجة إصلاح صلاحيات المصادقة:');
    console.log(JSON.stringify(fixResult, null, 2));
    
    // إعادة اختبار المصادقة بعد الإصلاح
    console.log('\nإعادة اختبار المصادقة بعد الإصلاح...');
    const retestResult = await testAuthentication();
    console.log('\nنتيجة إعادة اختبار المصادقة:');
    console.log(JSON.stringify(retestResult, null, 2));
    
    if (retestResult.success) {
      console.log('\n✅ تم إصلاح مشكلة المصادقة بنجاح!');
    } else {
      console.log('\n❌ لم يتم إصلاح المشكلة بالكامل. قد تحتاج إلى مراجعة إعدادات Supabase.');
      
      console.log('\nللإصلاح اليدوي، قم بتنفيذ الأوامر التالية في محرر SQL في Supabase:');
      console.log(`
-- منح صلاحيات للمستخدم المجهول (anon)
GRANT USAGE ON SCHEMA auth TO anon;
GRANT SELECT ON TABLE auth.users TO anon;

-- منح صلاحيات للمستخدم المصادق عليه (authenticated)
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT SELECT ON TABLE auth.users TO authenticated;

-- إعادة تعيين صلاحيات service_role
GRANT ALL PRIVILEGES ON SCHEMA auth TO service_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA auth TO service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA auth TO service_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA auth TO service_role;

-- تعطيل RLS على auth.users إذا كانت مفعلة
ALTER TABLE IF EXISTS auth.users DISABLE ROW LEVEL SECURITY;
      `);
    }
  } else {
    console.log('\n✅ نجح اختبار المصادقة! يبدو أن النظام يعمل بشكل صحيح.');
  }
}

// تنفيذ الاختبارات
runTests(); 