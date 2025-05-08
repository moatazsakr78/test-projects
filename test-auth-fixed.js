// اختبار المصادقة بعد تطبيق الإصلاحات
// استخدم هذا السكريبت للتحقق من أن الإصلاحات عملت بنجاح

const { createClient } = require('@supabase/supabase-js');

// إعدادات Supabase من ملفات التطبيق
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
 * اختبار إنشاء مستخدم جديد
 */
async function testSignUp() {
  try {
    // إنشاء بيانات اختبار فريدة
    const timestamp = new Date().getTime();
    const testEmail = `test${timestamp}@example.com`;
    const testPassword = 'Password123!';
    const testUsername = `user${timestamp}`;

    logWithTimestamp('=== اختبار إنشاء حساب جديد ===');
    logWithTimestamp(`استخدام البريد الإلكتروني: ${testEmail}`);

    const { data, error } = await supabase.auth.signUp({
      email: testEmail,
      password: testPassword,
      options: {
        data: {
          username: testUsername
        }
      }
    });

    if (error) {
      logWithTimestamp(`❌ فشل إنشاء الحساب: ${error.message}`);
      console.log('تفاصيل الخطأ:', error);
      return false;
    }

    logWithTimestamp(`✅ تم إنشاء الحساب بنجاح! معرف المستخدم: ${data.user.id}`);
    return true;
  } catch (error) {
    logWithTimestamp(`❌ خطأ غير متوقع: ${error.message}`);
    console.error('تفاصيل الخطأ:', error);
    return false;
  } finally {
    // تسجيل الخروج
    await supabase.auth.signOut();
  }
}

/**
 * اختبار تسجيل الدخول بمستخدم موجود
 */
async function testSignIn() {
  try {
    // يمكنك تعديل هذه البيانات إلى حساب موجود في النظام
    const email = 'test@example.com';
    const password = 'Password123!';

    logWithTimestamp('=== اختبار تسجيل الدخول ===');
    logWithTimestamp(`استخدام البريد الإلكتروني: ${email}`);

    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password
    });

    if (error) {
      logWithTimestamp(`❌ فشل تسجيل الدخول: ${error.message}`);
      console.log('تفاصيل الخطأ:', error);
      return false;
    }

    logWithTimestamp(`✅ تم تسجيل الدخول بنجاح! معرف الجلسة: ${data.session.id}`);
    return true;
  } catch (error) {
    logWithTimestamp(`❌ خطأ غير متوقع: ${error.message}`);
    console.error('تفاصيل الخطأ:', error);
    return false;
  } finally {
    // تسجيل الخروج
    await supabase.auth.signOut();
  }
}

/**
 * تشغيل الاختبارات
 */
async function runTests() {
  logWithTimestamp('▶️ بدء اختبارات المصادقة بعد تطبيق الإصلاحات');
  
  const signUpResult = await testSignUp();
  const signInResult = await testSignIn();
  
  if (signUpResult && signInResult) {
    logWithTimestamp('✅✅ تم اجتياز جميع الاختبارات بنجاح! الإصلاحات تعمل بشكل جيد.');
  } else {
    logWithTimestamp('❌❌ فشلت بعض الاختبارات. يرجى مراجعة السجل أعلاه والتأكد من تطبيق جميع الإصلاحات.');
  }
}

// تشغيل الاختبارات تلقائيًا
runTests(); 