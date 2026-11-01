# APK banane ka aasan tareeka (apne computer par kuch install nahi karna)

GitHub ka free cloud aapke liye APK bana dega.

1. https://github.com par free account banao (ya login karo).
2. Upar "+" dabao, "New repository" chuno. Naam: `kharcha-tracker`. "Create repository" dabao.
3. "uploading an existing file" link dabao. Is zip ko **extract** karke uske andar ki
   saari files aur folders (`app_src`, `.github`, ...) drag karke daal do. "Commit changes" dabao.
   Note: `.github` folder hidden hota hai. Agar computer mein na dikhe toh "Show hidden files" on karo.
4. Repository mein upar "Actions" tab kholo. "Build APK" chuno, phir "Run workflow" dabao.
5. 5-8 minute baad hara tick aa jayega. Us run par click karo, neeche "Artifacts" mein
   `kharcha-tracker-apk` download karo.
6. Zip extract karo, andar `app-release.apk` hogi. Phone mein bhejo aur install karo
   (Settings mein "Install unknown apps" allow karna padega).

Agar koi step par error aaye toh screenshot ya error text mujhe bhej do.
