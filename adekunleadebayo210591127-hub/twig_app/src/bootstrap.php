<?php
// src/bootstrap.php - sets up Twig if available and a simple render helper
declare(strict_types=1);

$root = dirname(__DIR__);

// Try to load Composer autoload and Twig
if (file_exists($root . '/vendor/autoload.php')) {
    require_once $root . '/vendor/autoload.php';
    // Initialize Twig
    $loader = new \Twig\Loader\FilesystemLoader($root . '/templates');
    $twig = new \Twig\Environment($loader, [
        'cache' => false,
        'debug' => true,
    ]);
    function render_template(string $template, array $vars = []) {
        global $twig;
        return $twig->render($template, $vars);
    }
} else {
    // Fallback: very small PHP-based renderer that includes raw template (not real Twig)
    function render_template(string $template, array $vars = []) {
        $path = __DIR__ . '/../templates/' . $template;
        if (!file_exists($path)) {
            return '<h1>Template not found: ' . htmlentities($template) . '</h1>';
        }
        // Basic extraction of variables for simple placeholders
        extract($vars, EXTR_SKIP);
        ob_start();
        include $path;
        return ob_get_clean();
    }
}

// Provide a small helper to load JSON mock data
function load_json(string $path) {
    $full = dirname(__DIR__) . '/src/data/' . $path;
    if (!file_exists($full)) return [];
    $json = file_get_contents($full);
    return json_decode($json, true) ?: [];
}
