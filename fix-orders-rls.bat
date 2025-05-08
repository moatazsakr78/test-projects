@echo off
echo "جارٍ إصلاح سياسات RLS لجداول الطلبات..."

REM تحقق من وجود مفاتيح API كمتغيرات بيئية أو اطلبها من المستخدم
if "%SUPABASE_URL%"=="" (
  echo "يرجى إدخال عنوان URL الخاص بـ Supabase:"
  set /p SUPABASE_URL=
)

if "%SUPABASE_KEY%"=="" (
  echo "يرجى إدخال مفتاح API الخاص بـ Supabase (service role key):"
  set /p SUPABASE_KEY=
)

REM التحقق من وجود curl للاتصال بـ API
where curl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
  echo "خطأ: لم يتم العثور على curl. يرجى تثبيت curl أولاً."
  pause > nul
  exit /b 1
)

REM قراءة ملف SQL وإرساله إلى Supabase
set SQL_FILE=fix-orders-rls.sql
if not exist %SQL_FILE% (
  echo "خطأ: ملف %SQL_FILE% غير موجود."
  pause > nul
  exit /b 1
)

echo "جاري قراءة ملف SQL..."
set /p SQL_CONTENT=<%SQL_FILE%

echo "جاري تطبيق سياسات RLS..."
curl -X POST ^
  "%SUPABASE_URL%/rest/v1/rpc/exec_sql" ^
  -H "apikey: %SUPABASE_KEY%" ^
  -H "Authorization: Bearer %SUPABASE_KEY%" ^
  -H "Content-Type: application/json" ^
  -d "{\"query\": \"%SQL_CONTENT%\"}"

echo.
echo "تم محاولة تطبيق سياسات RLS. تحقق من النتيجة أعلاه."
echo "ملاحظة: يمكنك أيضًا نسخ محتوى ملف SQL ولصقه مباشرة في محرر SQL في Supabase."

echo.
echo "اضغط أي مفتاح للإغلاق."
pause > nul 