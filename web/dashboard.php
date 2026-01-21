<?php
/**
 * ═══════════════════════════════════════════════════════════════════
 *  NULLKIA PHP WEB DASHBOARD
 *  Web-based device management interface
 *  @author bad-antics | discord.gg/killers
 * ═══════════════════════════════════════════════════════════════════
 */

declare(strict_types=1);

namespace NullKia\Dashboard;

const VERSION = '2.0.0';
const AUTHOR = 'bad-antics';
const DISCORD = 'discord.gg/killers';

/**
 * License Tier Enumeration
 */
enum LicenseTier: string
{
    case FREE = 'Free';
    case PREMIUM = 'Premium ⭐';
    case ENTERPRISE = 'Enterprise 💎';
    
    public function getFeatures(): array
    {
        return match($this) {
            self::FREE => ['Basic device info', 'ADB commands', 'Community support'],
            self::PREMIUM => ['All Free features', 'Firmware tools', 'Priority support', 'Exploit DB access'],
            self::ENTERPRISE => ['All Premium features', 'Custom modules', 'API access', 'Dedicated support'],
        };
    }
}

/**
 * License Data Transfer Object
 */
readonly class License
{
    public function __construct(
        public string $key,
        public LicenseTier $tier,
        public bool $valid,
        public ?\DateTimeImmutable $expiresAt = null
    ) {}
}

/**
 * Device Data Transfer Object
 */
readonly class Device
{
    public function __construct(
        public string $serial,
        public string $model,
        public string $product,
        public string $status,
        public string $mode,
        public array $properties = []
    ) {}
}

/**
 * License Validator
 */
class LicenseValidator
{
    private const PATTERN = '/^NKIA-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/';
    
    public static function validate(string $key): License
    {
        if (!preg_match(self::PATTERN, $key)) {
            return new License('', LicenseTier::FREE, false);
        }
        
        $parts = explode('-', $key);
        if (count($parts) !== 5) {
            return new License('', LicenseTier::FREE, false);
        }
        
        $tierCode = substr($parts[1], 0, 2);
        $tier = match($tierCode) {
            'PR' => LicenseTier::PREMIUM,
            'EN' => LicenseTier::ENTERPRISE,
            default => LicenseTier::FREE,
        };
        
        // Parse expiry from last segment
        $expiryCode = $parts[4];
        try {
            $month = (int)substr($expiryCode, 0, 2);
            $year = 2024 + (int)substr($expiryCode, 2, 2);
            $expiresAt = new \DateTimeImmutable("$year-$month-01");
        } catch (\Exception) {
            $expiresAt = new \DateTimeImmutable('+1 year');
        }
        
        return new License($key, $tier, true, $expiresAt);
    }
    
    public static function isExpired(License $license): bool
    {
        return $license->expiresAt?->getTimestamp() < time();
    }
}

/**
 * Device Manager
 */
class DeviceManager
{
    private array $devices = [];
    private License $license;
    
    public function __construct()
    {
        $this->license = new License('', LicenseTier::FREE, false);
    }
    
    public function setLicense(string $key): void
    {
        $this->license = LicenseValidator::validate($key);
    }
    
    public function getLicense(): License
    {
        return $this->license;
    }
    
    public function isPremium(): bool
    {
        return $this->license->valid && $this->license->tier !== LicenseTier::FREE;
    }
    
    public function detectDevices(): array
    {
        $this->devices = [];
        
        // Detect ADB devices
        $output = shell_exec('adb devices -l 2>&1') ?? '';
        $lines = explode("\n", $output);
        
        foreach (array_slice($lines, 1) as $line) {
            $line = trim($line);
            if (empty($line)) continue;
            
            if (preg_match('/^(\S+)\s+(device|offline|unauthorized)/', $line, $matches)) {
                $serial = $matches[1];
                $status = $matches[2];
                
                preg_match('/model:(\S+)/', $line, $modelMatch);
                preg_match('/product:(\S+)/', $line, $productMatch);
                
                $this->devices[] = new Device(
                    serial: $serial,
                    model: $modelMatch[1] ?? 'Unknown',
                    product: $productMatch[1] ?? 'Unknown',
                    status: $status,
                    mode: 'adb'
                );
            }
        }
        
        // Detect Fastboot devices
        $output = shell_exec('fastboot devices -l 2>&1') ?? '';
        $lines = explode("\n", $output);
        
        foreach ($lines as $line) {
            $line = trim($line);
            if (empty($line)) continue;
            
            if (preg_match('/^(\S+)\s+fastboot/', $line, $matches)) {
                $serial = $matches[1];
                
                // Check if already exists
                $exists = false;
                foreach ($this->devices as $key => $device) {
                    if ($device->serial === $serial) {
                        $this->devices[$key] = new Device(
                            serial: $device->serial,
                            model: $device->model,
                            product: $device->product,
                            status: 'fastboot',
                            mode: 'fastboot'
                        );
                        $exists = true;
                        break;
                    }
                }
                
                if (!$exists) {
                    $this->devices[] = new Device(
                        serial: $serial,
                        model: 'Unknown',
                        product: 'Unknown',
                        status: 'fastboot',
                        mode: 'fastboot'
                    );
                }
            }
        }
        
        return $this->devices;
    }
    
    public function getDevices(): array
    {
        return $this->devices;
    }
    
    public function getDeviceProperties(string $serial): array
    {
        if (!$this->isPremium()) {
            return ['error' => 'Premium feature'];
        }
        
        $props = [
            'ro.product.model',
            'ro.product.brand',
            'ro.product.device',
            'ro.build.version.release',
            'ro.build.version.sdk',
            'ro.build.fingerprint',
            'ro.serialno',
            'ro.hardware'
        ];
        
        $properties = [];
        foreach ($props as $prop) {
            $value = trim(shell_exec("adb -s $serial shell getprop $prop 2>&1") ?? '');
            $properties[$prop] = $value;
        }
        
        return $properties;
    }
    
    public function rebootDevice(string $serial, string $mode = 'system'): bool
    {
        $validModes = ['system' => '', 'recovery' => 'recovery', 'bootloader' => 'bootloader'];
        
        if (!isset($validModes[$mode])) {
            return false;
        }
        
        $cmd = $validModes[$mode] 
            ? "adb -s $serial reboot {$validModes[$mode]}"
            : "adb -s $serial reboot";
        
        shell_exec($cmd . ' 2>&1');
        return true;
    }
    
    public function executeShell(string $serial, string $command): string
    {
        $command = escapeshellarg($command);
        return shell_exec("adb -s $serial shell $command 2>&1") ?? '';
    }
}

/**
 * HTML Template Renderer
 */
class DashboardRenderer
{
    private DeviceManager $dm;
    
    public function __construct(DeviceManager $dm)
    {
        $this->dm = $dm;
    }
    
    public function renderHeader(): string
    {
        $version = VERSION;
        $author = AUTHOR;
        $discord = DISCORD;
        $tier = $this->dm->getLicense()->tier->value;
        
        return <<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>NullKia Dashboard - $author</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #e4e4e4;
            min-height: 100vh;
        }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        header {
            background: rgba(0,0,0,0.3);
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            border: 1px solid #333;
        }
        h1 { color: #00ff88; font-size: 2em; margin-bottom: 10px; }
        .meta { color: #888; font-size: 0.9em; }
        .card {
            background: rgba(0,0,0,0.2);
            border: 1px solid #333;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
        }
        .card h2 { color: #00d4ff; margin-bottom: 15px; }
        .device {
            background: rgba(0,255,136,0.1);
            border: 1px solid #00ff88;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 10px;
        }
        .device-serial { font-weight: bold; color: #00ff88; }
        .device-info { color: #aaa; font-size: 0.9em; margin-top: 5px; }
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 4px;
            font-size: 0.8em;
            margin-left: 10px;
        }
        .badge-online { background: #00ff88; color: #000; }
        .badge-offline { background: #ff4444; color: #fff; }
        .badge-premium { background: gold; color: #000; }
        .btn {
            background: #00ff88;
            color: #000;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-weight: bold;
            margin-right: 10px;
            transition: all 0.3s;
        }
        .btn:hover { background: #00cc6a; transform: translateY(-2px); }
        .btn-danger { background: #ff4444; color: #fff; }
        .btn-warning { background: #ffaa00; color: #000; }
        input[type="text"], input[type="password"] {
            background: rgba(0,0,0,0.3);
            border: 1px solid #444;
            color: #fff;
            padding: 10px;
            border-radius: 5px;
            width: 100%;
            margin-bottom: 10px;
        }
        .premium-notice {
            background: linear-gradient(135deg, gold, orange);
            color: #000;
            padding: 15px;
            border-radius: 8px;
            text-align: center;
            margin-bottom: 20px;
        }
        .premium-notice a { color: #000; font-weight: bold; }
        footer {
            text-align: center;
            padding: 20px;
            color: #666;
            margin-top: 40px;
            border-top: 1px solid #333;
        }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 15px; }
        .stat-box { background: rgba(0,212,255,0.1); padding: 15px; border-radius: 8px; text-align: center; }
        .stat-value { font-size: 2em; color: #00d4ff; }
        .stat-label { color: #888; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📱 NullKia Dashboard</h1>
            <div class="meta">
                Version $version | Author: $author | License: $tier
            </div>
        </header>
HTML;
    }
    
    public function renderDevices(): string
    {
        $devices = $this->dm->getDevices();
        $html = '<div class="card"><h2>📱 Connected Devices</h2>';
        
        if (empty($devices)) {
            $html .= '<p>No devices connected. Connect a device and refresh.</p>';
        } else {
            foreach ($devices as $device) {
                $badgeClass = $device->status === 'device' ? 'badge-online' : 'badge-offline';
                $html .= <<<HTML
                <div class="device">
                    <div class="device-serial">
                        {$device->serial}
                        <span class="badge $badgeClass">{$device->status}</span>
                        <span class="badge">{$device->mode}</span>
                    </div>
                    <div class="device-info">
                        Model: {$device->model} | Product: {$device->product}
                    </div>
                </div>
HTML;
            }
        }
        
        $html .= '<button class="btn" onclick="location.reload()">🔄 Refresh</button>';
        $html .= '</div>';
        
        return $html;
    }
    
    public function renderPremiumNotice(): string
    {
        if ($this->dm->isPremium()) {
            return '';
        }
        
        $discord = DISCORD;
        return <<<HTML
        <div class="premium-notice">
            🔑 <strong>Get Premium Features!</strong> 
            Join <a href="https://$discord">$discord</a> for license keys and unlock all features!
        </div>
HTML;
    }
    
    public function renderStats(): string
    {
        $deviceCount = count($this->dm->getDevices());
        $tier = $this->dm->getLicense()->tier->value;
        
        return <<<HTML
        <div class="card">
            <h2>📊 Stats</h2>
            <div class="stats">
                <div class="stat-box">
                    <div class="stat-value">$deviceCount</div>
                    <div class="stat-label">Devices</div>
                </div>
                <div class="stat-box">
                    <div class="stat-value">$tier</div>
                    <div class="stat-label">License</div>
                </div>
            </div>
        </div>
HTML;
    }
    
    public function renderFooter(): string
    {
        $author = AUTHOR;
        $discord = DISCORD;
        
        return <<<HTML
        <footer>
            <p>📱 NullKia PHP Dashboard | 🔑 Premium: $discord | 👤 Author: $author</p>
            <p>© 2025-2026 $author - Part of NullSec Framework</p>
        </footer>
    </div>
</body>
</html>
HTML;
    }
    
    public function render(): string
    {
        return 
            $this->renderHeader() .
            $this->renderPremiumNotice() .
            $this->renderStats() .
            $this->renderDevices() .
            $this->renderFooter();
    }
}

// ═══════════════════════════════════════════════════════════════════
// Main Entry Point
// ═══════════════════════════════════════════════════════════════════

$dm = new DeviceManager();

// Handle license key from query/post
$licenseKey = $_GET['key'] ?? $_POST['key'] ?? '';
if ($licenseKey) {
    $dm->setLicense($licenseKey);
}

// Detect devices
$dm->detectDevices();

// Handle actions
$action = $_GET['action'] ?? '';
$serial = $_GET['serial'] ?? '';

if ($action && $serial) {
    header('Content-Type: application/json');
    
    switch ($action) {
        case 'info':
            echo json_encode($dm->getDeviceProperties($serial));
            exit;
        case 'reboot':
            $mode = $_GET['mode'] ?? 'system';
            echo json_encode(['success' => $dm->rebootDevice($serial, $mode)]);
            exit;
        case 'shell':
            $cmd = $_GET['cmd'] ?? '';
            echo json_encode(['output' => $dm->executeShell($serial, $cmd)]);
            exit;
    }
}

// Render dashboard
$renderer = new DashboardRenderer($dm);
echo $renderer->render();
