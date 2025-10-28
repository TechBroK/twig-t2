<?php
// Simple front controller for the standalone Twig app.
// It expects vendor/autoload.php to be present if you install dependencies via Composer.

declare(strict_types=1);

$projectRoot = dirname(__DIR__);

// basic router
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$uri = rtrim($uri, '/');
if ($uri === '') { $uri = '/'; }

require_once $projectRoot . '/src/bootstrap.php';

$routes = require $projectRoot . '/src/routes.php';

// Server-side protection for specific paths: if the cookie 'ticketapp_session' is missing, redirect to login
$protected = ['/', '/dashboard', '/tickets'];
// Note: keep '/' unprotected or remove it from the array if you don't want to protect the home page.
foreach ($protected as $p) {
    if ($p !== '/' && strpos($uri, $p) === 0) {
        $cookie = $_COOKIE['ticketapp_session'] ?? null;
        if (empty($cookie)) {
            header('Location: /auth/login');
            exit;
        }
    }
}

if (isset($routes[$uri])) {
    echo render_template($routes[$uri]);
} else {
    http_response_code(404);
    // If a 404 template exists, render it; otherwise output a simple message
    if (file_exists($projectRoot . '/templates/404.html.twig')) {
        echo render_template('404.html.twig');
    } else {
        echo '<h1>404 - Not Found</h1>';
    }
}
