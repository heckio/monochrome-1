import fs from 'fs';
import { spawn } from 'child_process';
import { platform, arch } from 'os';

const CONFIG_FILE = 'neutralino.config.json';
const DEV_CONFIG_FILE = 'neutralino.config.dev.json';
const BACKUP_CONFIG_FILE = 'neutralino.config.prod.bak';
const PUBLIC_CONFIG_FILE = 'public/neutralino.config.json'; // needed when --path=./public

function restoreConfig() {
    // Clean up the temp config copy in public/
    try {
        if (fs.existsSync(PUBLIC_CONFIG_FILE)) {
            fs.unlinkSync(PUBLIC_CONFIG_FILE);
        }
    } catch (e) { /* ignore */ }

    if (fs.existsSync(BACKUP_CONFIG_FILE)) {
        try {
            if (fs.existsSync(CONFIG_FILE)) {
                fs.unlinkSync(CONFIG_FILE);
            }
            fs.renameSync(BACKUP_CONFIG_FILE, CONFIG_FILE);
            console.log('Restored production configuration.');
        } catch (e) {
            console.error('Failed to restore configuration:', e);
        }
    }
}

function getBinaryPath() {
    const os = platform();
    const cpu = arch();
    if (os === 'darwin') {
        return cpu === 'arm64' ? './bin/neutralino-mac_arm64' : './bin/neutralino-mac_x64';
    } else if (os === 'linux') {
        return cpu === 'arm64' ? './bin/neutralino-linux_arm64' : './bin/neutralino-linux_x64';
    } else if (os === 'win32') {
        return './bin/neutralino-win_x64.exe';
    }
    throw new Error(`Unsupported platform: ${os} ${cpu}`);
}

// Ensure we clean up on exit
process.on('SIGINT', () => {
    restoreConfig();
    process.exit();
});

process.on('exit', () => {
    restoreConfig();
});

async function run() {
    if (!fs.existsSync(DEV_CONFIG_FILE)) {
        console.error('Error: neutralino.config.dev.json not found.');
        process.exit(1);
    }

    try {
        // Backup production config
        if (fs.existsSync(CONFIG_FILE)) {
            fs.renameSync(CONFIG_FILE, BACKUP_CONFIG_FILE);
        }

        // Copy dev config to main and into public/ (binary looks for config relative to --path)
        fs.copyFileSync(DEV_CONFIG_FILE, CONFIG_FILE);
        fs.copyFileSync(DEV_CONFIG_FILE, PUBLIC_CONFIG_FILE);
        console.log('Switched to development configuration.');

        // Run the binary directly with --path=./public to avoid indexing node_modules,
        // which causes a crash when Neutralino tries to build a file tree of the full project.
        const binaryPath = getBinaryPath();
        console.log(`Launching: ${binaryPath}`);
        const neu = spawn(
            binaryPath,
            [
                '--load-dir-res',
                '--path=./public',
                '--export-auth-info',
                '--neu-dev-extension',
                '--neu-dev-auto-reload',
            ],
            { stdio: 'inherit', shell: false }
        );

        neu.on('close', (code) => {
            console.log(`Neutralino process exited with code ${code}`);
            restoreConfig();
            process.exit(code ?? 0);
        });
    } catch (e) {
        console.error('Error running dev environment:', e);
        restoreConfig();
        process.exit(1);
    }
}

run();
