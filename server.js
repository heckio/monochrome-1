// Minimal static file server — no dependencies, no child processes
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 4173;
const DIST = path.resolve(__dirname, 'dist');

const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.webp': 'image/webp',
    '.webmanifest': 'application/manifest+json',
    '.txt': 'text/plain',
};

http.createServer((req, res) => {
    const url = req.url.split('?')[0];

    // Health check
    if (url === '/health') {
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end('OK');
        return;
    }

    let filePath = path.join(DIST, url);

    // Prevent path traversal
    if (!filePath.startsWith(DIST)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }

    // SPA fallback: if file doesn't exist, serve index.html
    try {
        const stat = fs.statSync(filePath);
        if (stat.isDirectory()) filePath = path.join(DIST, 'index.html');
    } catch {
        filePath = path.join(DIST, 'index.html');
    }

    const ext = path.extname(filePath);
    const contentType = MIME[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('Not found');
            return;
        }
        const headers = { 'Content-Type': contentType };
        if (url.startsWith('/assets/')) {
            headers['Cache-Control'] = 'public, max-age=31536000, immutable';
        }
        res.writeHead(200, headers);
        res.end(data);
    });
}).listen(PORT, '0.0.0.0', () => {
    console.log(`Monochrome serving on http://0.0.0.0:${PORT}`);
});
