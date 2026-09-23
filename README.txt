DANZZ ID CHECKER - VERCEL

1. Upload/import this folder as a Vercel project.
2. index.html = customer checker.
3. admin.html = admin panel.
4. api/fullinfo.js = Vercel serverless proxy to the API server.
5. vercel.json keeps /access/DANZZ-XXXXXX working.
6. Put the same Supabase URL + publishable key into index.html and admin.html.
7. API server used by the proxy: http://161.202.221.10:30106

Open:
https://YOUR-DOMAIN.vercel.app/admin.html

Customer access:
https://YOUR-DOMAIN.vercel.app/access/DANZZ-XXXXXX
