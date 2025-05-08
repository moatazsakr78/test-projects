@echo off
echo ===== تطبيق إصلاحات سياسات RLS للتسجيل وتسجيل الدخول =====
echo.

echo 1. محاولة تطبيق إصلاح سياسات RLS للمستخدمين...

if exist "fix-users-rls.sql" (
    echo وجدت ملف fix-users-rls.sql
    set SQL_FILE=fix-users-rls.sql
) else (
    echo لم أجد ملف fix-users-rls.sql في المجلد الحالي
    echo محاولة البحث عنه في المجلدات الأخرى...
    
    if exist "HeaWaBas\fix-users-rls.sql" (
        echo وجدت الملف في مجلد HeaWaBas
        set SQL_FILE=HeaWaBas\fix-users-rls.sql
    ) else (
        echo لم أستطع العثور على ملف إصلاح سياسات RLS
        echo يرجى التأكد من وجود ملف fix-users-rls.sql
        pause
        exit /b 1
    )
)

echo سيتم تنفيذ ملف SQL التالي: %SQL_FILE%
echo.
echo هذا الملف سيقوم بـ:
echo 1. حذف سياسات RLS القديمة على جدول المستخدمين
echo 2. تعطيل RLS مؤقتًا
echo 3. إعادة تفعيل RLS مع سياسات صحيحة تسمح بالتسجيل وتسجيل الدخول
echo.

echo يمكنك تنفيذ محتوى الملف بإحدى الطرق التالية:
echo - نسخ محتوى الملف وتنفيذه في محرر SQL في لوحة تحكم Supabase
echo - استخدام أداة تنفيذ SQL مثل psql لتنفيذه مباشرة
echo.

echo --- محتوى ملف الإصلاح ---
type "%SQL_FILE%"
echo ----------------------------
echo.

set /p CONFIRM=هل تريد المتابعة وتطبيق الإصلاح؟ (y/n): 

if /i "%CONFIRM%" NEQ "y" (
    echo تم إلغاء العملية.
    pause
    exit /b 0
)

echo.
echo لتطبيق الإصلاح، قم بالتالي:
echo 1. افتح لوحة تحكم Supabase
echo 2. انتقل إلى قسم SQL Editor
echo 3. انسخ محتوى ملف fix-users-rls.sql وألصقه في المحرر
echo 4. اضغط على Run لتنفيذ الأوامر
echo.
echo إذا كنت بحاجة إلى المزيد من المساعدة، راجع README-RLS-FIX.md

pause 