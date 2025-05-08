// برنامج إصلاح سياسات RLS للمستخدمين لحل مشكلات تسجيل الدخول وإنشاء الحسابات
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

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
 * قراءة ملف SQL وتفسيره إلى مجموعة من الأوامر
 */
function parseSqlFile(filePath) {
  try {
    const sqlContent = fs.readFileSync(filePath, 'utf8');
    // تقسيم الملف إلى أوامر منفصلة (نحذف التعليقات أولاً)
    const sqlCommands = sqlContent
      .replace(/--.*$/gm, '') // إزالة التعليقات
      .split(';')
      .map(cmd => cmd.trim())
      .filter(cmd => cmd !== ''); // إزالة الأسطر الفارغة
    
    return sqlCommands;
  } catch (error) {
    logWithTimestamp(`خطأ في قراءة ملف SQL: ${error.message}`);
    return [];
  }
}

/**
 * البحث عن ملف SQL
 */
function findSqlFile(fileName) {
  // البحث في المجلد الحالي
  if (fs.existsSync(fileName)) {
    return fileName;
  }
  
  // البحث في مجلد HeaWaBas
  const heawabasPath = path.join(process.cwd(), 'HeaWaBas', fileName);
  if (fs.existsSync(heawabasPath)) {
    return heawabasPath;
  }
  
  // البحث في المجلد الأصلي إذا كنا في مجلد HeaWaBas
  const parentPath = path.join(process.cwd(), '..', fileName);
  if (fs.existsSync(parentPath)) {
    return parentPath;
  }
  
  return null;
}

/**
 * تنفيذ أمر SQL على Supabase
 */
async function executeSqlCommand(command) {
  try {
    const { error } = await supabase.rpc('exec_sql', { sql_query: command });
    if (error) {
      return { success: false, error: error.message };
    }
    return { success: true };
  } catch (error) {
    return { success: false, error: error.message };
  }
}

/**
 * إصلاح سياسات RLS للمستخدمين
 */
async function fixAuthRLS() {
  logWithTimestamp('=== بدء إصلاح سياسات RLS للمستخدمين ===');
  
  // البحث عن ملف SQL
  const sqlFilePath = findSqlFile('fix-users-rls.sql');
  if (!sqlFilePath) {
    logWithTimestamp('!!! لم يتم العثور على ملف fix-users-rls.sql !!!');
    return { success: false, message: 'لم يتم العثور على ملف SQL اللازم للإصلاح' };
  }
  
  logWithTimestamp(`وجدت ملف SQL في: ${sqlFilePath}`);
  
  // قراءة وتفسير ملف SQL
  const sqlCommands = parseSqlFile(sqlFilePath);
  if (sqlCommands.length === 0) {
    logWithTimestamp('!!! لم يتم العثور على أوامر SQL في الملف !!!');
    return { success: false, message: 'ملف SQL فارغ أو غير صالح' };
  }
  
  logWithTimestamp(`تم استخراج ${sqlCommands.length} أمر SQL من الملف`);
  
  // تسجيل الدخول أولاً للحصول على صلاحيات (إذا لزم الأمر)
  try {
    logWithTimestamp('محاولة تسجيل الدخول...');
    
    // يمكنك تعديل بيانات تسجيل الدخول حسب الحاجة
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: 'admin@example.com',
      password: 'password123'
    });
    
    if (authError) {
      logWithTimestamp(`تحذير: لم يتم تسجيل الدخول (${authError.message})`);
      logWithTimestamp('متابعة التنفيذ بدون تسجيل دخول...');
    } else {
      logWithTimestamp('تم تسجيل الدخول بنجاح');
    }
  } catch (error) {
    logWithTimestamp(`تحذير: فشل تسجيل الدخول (${error.message})`);
    logWithTimestamp('متابعة التنفيذ بدون تسجيل دخول...');
  }
  
  // تنفيذ الأوامر واحدًا تلو الآخر
  let successCount = 0;
  let failCount = 0;
  
  for (let i = 0; i < sqlCommands.length; i++) {
    const command = sqlCommands[i];
    if (command.length < 10) continue; // تخطي الأوامر القصيرة جدًا
    
    logWithTimestamp(`تنفيذ الأمر ${i+1}/${sqlCommands.length}...`);
    // جعل الأمر مختصر للعرض
    const shortCommand = command.length > 50 ? `${command.substring(0, 50)}...` : command;
    logWithTimestamp(`SQL: ${shortCommand}`);
    
    const result = await executeSqlCommand(command);
    if (result.success) {
      successCount++;
      logWithTimestamp('✓ تم تنفيذ الأمر بنجاح');
    } else {
      failCount++;
      logWithTimestamp(`✗ فشل تنفيذ الأمر: ${result.error}`);
    }
  }
  
  // ملخص النتائج
  logWithTimestamp('=== تم إكمال عملية إصلاح سياسات RLS ===');
  logWithTimestamp(`إجمالي الأوامر: ${sqlCommands.length}`);
  logWithTimestamp(`نجح: ${successCount}`);
  logWithTimestamp(`فشل: ${failCount}`);
  
  if (failCount > 0) {
    logWithTimestamp('!!! هناك بعض الأوامر التي فشلت، راجع السجل لمزيد من التفاصيل !!!');
    return {
      success: successCount > 0,
      message: `تم تنفيذ ${successCount} أمر بنجاح، وفشل ${failCount} أمر.`,
      partialSuccess: true
    };
  }
  
  logWithTimestamp('✓ تم إصلاح سياسات RLS للمستخدمين بنجاح');
  
  return {
    success: true,
    message: 'تم إصلاح سياسات RLS للمستخدمين بنجاح'
  };
}

// تنفيذ الإصلاح
fixAuthRLS().then(result => {
  console.log('\nنتيجة عملية الإصلاح:');
  console.log(JSON.stringify(result, null, 2));
  
  if (!result.success && !result.partialSuccess) {
    console.log('\nللإصلاح اليدوي:');
    console.log('1. قم بالوصول إلى لوحة تحكم Supabase');
    console.log('2. انتقل إلى قسم SQL');
    console.log('3. انسخ محتوى ملف fix-users-rls.sql وقم بتنفيذه');
    
    process.exit(1);
  }
}); 