@echo off
echo ===== تطبيق إصلاح مشكلة "Database error granting user" =====
echo.

echo يرجى متابعة الخطوات التالية لإصلاح مشكلة المصادقة:
echo.

:SHOW_OPTIONS
echo 1. عرض ملف الإصلاح SQL
echo 2. اختبار عملية المصادقة بعد تطبيق الإصلاح
echo 3. إنهاء
echo.

set /p CHOICE=اختر رقم العملية (1، 2 أو 3): 

if "%CHOICE%" == "1" (
    echo.
    echo ===== ملف الإصلاح SQL =====
    echo.
    echo محتوى ملف الإصلاح SQL:
    echo.
    type auth-fix-applied.sql
    echo.
    echo ---------------------------------------------
    echo لتطبيق الإصلاح، يرجى اتباع الخطوات التالية:
    echo 1. قم بتسجيل الدخول إلى لوحة تحكم Supabase
    echo 2. انتقل إلى SQL Editor
    echo 3. انسخ محتوى الملف المعروض أعلاه وألصقه في المحرر
    echo 4. اضغط على زر "Run" لتنفيذ الأوامر
    echo 5. بعد الانتهاء، يمكنك العودة هنا واختيار الخيار 2 لاختبار الإصلاح
    echo ---------------------------------------------
    echo.
    goto CONTINUE
)

if "%CHOICE%" == "2" (
    echo.
    echo ===== اختبار المصادقة =====
    echo.
    echo سيتم اختبار عملية المصادقة للتأكد من حل المشكلة...
    echo.
    
    if exist node_modules (
        echo تشغيل اختبار المصادقة...
        node test-auth-fixed.js
    ) else (
        echo يبدو أنك تحتاج إلى تثبيت الوحدات المطلوبة أولاً.
        echo.
        echo هل ترغب في تثبيت وحدة @supabase/supabase-js الآن؟
        set /p INSTALL=اكتب "نعم" للتثبيت: 
        
        if /i "%INSTALL%" == "نعم" (
            echo تثبيت الوحدات المطلوبة...
            npm install @supabase/supabase-js
            
            echo.
            echo تشغيل اختبار المصادقة...
            node test-auth-fixed.js
        ) else (
            echo تم إلغاء التثبيت.
            echo لتشغيل الاختبار يدوياً في وقت لاحق، قم بتنفيذ:
            echo npm install @supabase/supabase-js
            echo node test-auth-fixed.js
        )
    )
    
    goto CONTINUE
)

if "%CHOICE%" == "3" (
    echo.
    echo شكراً لاستخدام أداة إصلاح المصادقة!
    exit /b 0
) else (
    echo.
    echo خيار غير صالح! يرجى إدخال 1، 2 أو 3.
    echo.
    goto SHOW_OPTIONS
)

:CONTINUE
echo.
echo هل ترغب في العودة إلى القائمة الرئيسية؟
set /p BACK=اكتب "نعم" للعودة أو أي شيء آخر للخروج: 

if /i "%BACK%" == "نعم" (
    echo.
    goto SHOW_OPTIONS
) else (
    echo.
    echo شكراً لاستخدام أداة إصلاح المصادقة!
) 