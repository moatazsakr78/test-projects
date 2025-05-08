@echo off
echo ===== تنفيذ إصلاح سياسات RLS للمستخدمين =====
echo.

if exist "fix-auth-rls.js" (
    echo وجدت ملف fix-auth-rls.js
    echo تنفيذ إصلاح RLS باستخدام Node.js...
    
    node fix-auth-rls.js
) else (
    echo لم أجد ملف fix-auth-rls.js في المجلد الحالي
    echo محاولة البحث عنه في المجلدات الأخرى...
    
    if exist "HeaWaBas\fix-auth-rls.js" (
        echo وجدت الملف في مجلد HeaWaBas
        cd HeaWaBas
        node fix-auth-rls.js
    ) else (
        echo لم أستطع العثور على ملف إصلاح سياسات RLS
        echo يرجى التأكد من وجود ملف fix-auth-rls.js
        
        echo.
        echo هل تريد تنفيذ ملف fix-users-rls.sql يدويًا بدلًا من ذلك؟
        set /p CONFIRM=اكتب "نعم" للمتابعة: 
        
        if /i "%CONFIRM%" == "نعم" (
            if exist "fix-users-rls.sql" (
                echo.
                echo محتوى ملف fix-users-rls.sql:
                type fix-users-rls.sql
                echo.
                echo انسخ هذا المحتوى وألصقه في محرر SQL في لوحة تحكم Supabase.
            ) else if exist "HeaWaBas\fix-users-rls.sql" (
                echo.
                echo محتوى ملف fix-users-rls.sql:
                type HeaWaBas\fix-users-rls.sql
                echo.
                echo انسخ هذا المحتوى وألصقه في محرر SQL في لوحة تحكم Supabase.
            ) else (
                echo لم أتمكن من العثور على أي ملفات إصلاح.
            )
        )
    )
)

echo.
echo انتهت عملية الإصلاح. تحقق من النتائج أعلاه.
pause 