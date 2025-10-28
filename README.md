# twig_app (standalone Twig demo)

This folder is a simplified Twig-based frontend you can run with PHP's built-in server. It is intentionally lightweight and self-contained.

Structure

adekunleadebayo210591127-hub/
└── twig_app/
    ├── public/
    │   ├── css/main.css
    │   ├── js/main.js
    │   └── index.php
    ├── templates/
    │   ├── base.html.twig
    │   ├── landing.html.twig
    │   ├── login.html.twig
    │   ├── signup.html.twig
    │   ├── dashboard.html.twig
    │   ├── tickets.html.twig
    │   └── partials/
    ├── src/
    │   ├── bootstrap.php
    │   ├── routes.php
    │   └── data/tickets.json
    └── composer.json

Quick start

1. Install dependencies (optional, to enable real Twig rendering):

```powershell
cd C:\Users\HomePC\Development\Twig_t2\adekunleadebayo210591127-hub\twig_app
composer install
```

2. Run with PHP built-in server from the twig_app folder:

```powershell
php -S localhost:9000 -t public
```

3. Open http://localhost:9000 in your browser.

Notes
- The index.php/front controller uses `src/bootstrap.php` which will initialize Twig if `vendor/autoload.php` exists (after running `composer install`). Otherwise it'll use a tiny fallback PHP include-based renderer.
- Static mock data is available at `src/data/tickets.json`.

Demo credentials (for demos using the simple JS):
- username: demo
- password: demo

Server configuration & protection

The app can be served with PHP's built-in server. By default the project uses port 9000, but you can change the host:port in the command below.

Start the server from the `twig_app` folder (PowerShell):

```powershell
cd C:\Users\HomePC\Development\Twig_t2\adekunleadebayo210591127-hub\twig_app
php -S localhost:9000 -t public
```

If you prefer a different port, replace `9000` with your chosen port.

Server-side protection

The front controller (`public/index.php`) contains a small server-side guard: requests to protected paths (for example `/dashboard` and `/tickets`) will be redirected to `/auth/login` when the `ticketapp_session` cookie is not present. This mirrors the client-side protection implemented in the JS.

To disable or tune this behavior, edit `public/index.php` and adjust the `$protected` array near the top of the file.

Running in background (PowerShell example)

To start the server in the background on Windows PowerShell you can run:

```powershell
Start-Process -NoNewWindow -FilePath php -ArgumentList '-S','localhost:9000','-t','public'
```

Stop the server by killing the PHP process (or stop the PowerShell session that spawned it).
