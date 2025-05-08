@echo off
echo ===== إصلاح مشكلة "Database error granting user" =====
echo.

echo هذا الملف سيساعدك على إصلاح مشكلة
echo "Database error granting user"
echo التي تظهر عند محاولة تسجيل الدخول أو إنشاء حساب جديد
echo.

echo 1. هل ترغب في تشخيص المشكلة أولاً؟ (موصى به)
echo 2. تطبيق الإصلاح مباشرة
echo 3. عرض إرشادات التصحيح اليدوي
echo.

set /p CHOICE=اختر رقم العملية (1، 2 أو 3): 

if "%CHOICE%" == "1" (
    echo.
    echo ===== تشخيص المشكلة =====
    echo سيتم محاولة إنشاء حساب اختباري للكشف عن المشكلة...
    
    if exist "test-auth.js" (
        echo تشغيل سكريبت تشخيص المشكلة...
        node test-auth.js
    ) else (
        echo لم يتم العثور على ملف test-auth.js
        echo العودة إلى القائمة الرئيسية...
        goto MAIN_MENU
    )
) else if "%CHOICE%" == "2" (
    echo.
    echo ===== تطبيق الإصلاح =====
    
    if exist "fix-auth-permissions.sql" (
        echo تم العثور على ملف الإصلاح SQL.
        echo.
        
        echo محتوى ملف الإصلاح:
        type fix-auth-permissions.sql
        echo.
        
        echo لتطبيق هذا الإصلاح:
        echo 1. قم بتسجيل الدخول إلى لوحة تحكم Supabase
        echo 2. انتقل إلى SQL Editor
        echo 3. انسخ محتوى الملف وألصقه في المحرر
        echo 4. اضغط على زر "Run" لتنفيذ الإصلاح
        echo.
        
        if exist "test-auth.js" (
            echo هل ترغب في محاولة تشخيص المشكلة بعد تطبيق الإصلاح؟
            set /p TEST=اكتب "نعم" للتشخيص: 
            
            if /i "%TEST%" == "نعم" (
                echo.
                echo تشغيل سكريبت تشخيص المشكلة...
                node test-auth.js
            )
        )
    ) else (
        echo لم يتم العثور على ملف fix-auth-permissions.sql
        echo لا يمكن تطبيق الإصلاح تلقائيًا.
    )
) else if "%CHOICE%" == "3" (
    echo.
    echo ===== إرشادات التصحيح اليدوي =====
    echo.
    echo لحل مشكلة "Database error granting user"، يجب اتباع الخطوات التالية:
    echo.
    echo 1. قم بتسجيل الدخول إلى لوحة تحكم Supabase
    echo 2. انتقل إلى SQL Editor
    echo 3. قم بتنفيذ الأوامر التالية:
    echo.
    echo ----------------------
    echo GRANT USAGE ON SCHEMA auth TO anon;
    echo GRANT SELECT ON TABLE auth.users TO anon;
    echo GRANT USAGE ON SCHEMA auth TO authenticated;
    echo GRANT SELECT ON TABLE auth.users TO authenticated;
    echo ALTER TABLE IF EXISTS auth.users DISABLE ROW LEVEL SECURITY;
    echo ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
    echo ----------------------
    echo.
    echo 4. بعد تنفيذ هذه الأوامر، قم بمحاولة تسجيل الدخول أو إنشاء حساب جديد مرة أخرى.
    echo.
) else (
    echo اختيار غير صالح!
)

:MAIN_MENU
echo.
echo هل ترغب في المحاولة مرة أخرى؟
set /p RETRY=اكتب "نعم" للمحاولة مرة أخرى: 

if /i "%RETRY%" == "نعم" (
    cls
    goto :EOF
    call fix-auth-error.bat
) else (
    echo شكراً لاستخدام سكريبت الإصلاح!
)

pause 