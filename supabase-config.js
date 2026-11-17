// Supabase connection for the public site.
// The anon key is public by design; all writes go through database functions
// that check each visitor's personal code (see supabase/migrations/001_init.sql).
export const SUPABASE_URL = 'https://zhocbkdadiuhdyjdqjfn.supabase.co';
export const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpob2Nia2RhZGl1aGR5amRxamZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ5NDQ2ODgsImV4cCI6MjExMDUyMDY4OH0.mbNahiLlaRauqElRd5lT7MwlFnnx-XJdGVl1FMa_SXQ';
