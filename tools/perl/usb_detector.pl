#!/usr/bin/env perl
#═══════════════════════════════════════════════════════════════════════════════
#  ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ 
#  ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗
#  ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║    USB-DETECTOR
#  ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║    Mobile USB Detection
#  ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║    & Analysis Tool
#  ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝    v1.0 | Perl Edition
#═══════════════════════════════════════════════════════════════════════════════
# NullKia Mobile Security Framework - USB Device Intelligence
# Detects and analyzes USB-connected mobile devices
# Supports: ADB, MTP, PTP, Fastboot, Recovery modes
#═══════════════════════════════════════════════════════════════════════════════

use strict;
use warnings;
use Getopt::Long;
use Term::ANSIColor;
use File::Basename;
use POSIX qw(strftime);

our $VERSION = "1.0.0";

# ═══════════════════════════════════════════════════════════════════════════════
# VENDOR DATABASE
# ═══════════════════════════════════════════════════════════════════════════════

my %VENDORS = (
    '0502' => 'Acer',
    '0b05' => 'ASUS',
    '413c' => 'Dell',
    '0489' => 'Foxconn',
    '04c5' => 'Fujitsu',
    '091e' => 'Garmin',
    '18d1' => 'Google',
    '201e' => 'Haier',
    '109b' => 'Hisense',
    '0bb4' => 'HTC',
    '12d1' => 'Huawei',
    '24e3' => 'K-Touch',
    '2116' => 'KT Tech',
    '0482' => 'Kyocera',
    '17ef' => 'Lenovo',
    '1004' => 'LG',
    '22b8' => 'Motorola',
    '0e8d' => 'MediaTek',
    '0409' => 'NEC',
    '2080' => 'Nook',
    '1d4d' => 'Pegatron',
    '0471' => 'Philips',
    '04da' => 'Panasonic',
    '05c6' => 'Qualcomm',
    '1f53' => 'SK Telesys',
    '04e8' => 'Samsung',
    '04dd' => 'Sharp',
    '054c' => 'Sony',
    '0fce' => 'Sony Ericsson',
    '2340' => 'Teleepoch',
    '19d2' => 'ZTE',
    '2717' => 'Xiaomi',
    '1949' => 'Amazon',
    '2a70' => 'OnePlus',
    '2ae5' => 'Fairphone',
    '29a9' => 'Vivo',
    '2d95' => 'Realme',
    '22d9' => 'OPPO',
    '1ebf' => 'Xiaomi (Redmi)',
);

my %PRODUCT_HINTS = (
    '4ee1' => 'MTP Device',
    '4ee2' => 'ADB Device',
    '4ee7' => 'Fastboot',
    'd001' => 'ADB Device',
    'd002' => 'Fastboot Device',
    'b00b' => 'Recovery Mode',
    '0c02' => 'ADB Composite',
    '0c03' => 'MTP+ADB',
);

# ═══════════════════════════════════════════════════════════════════════════════
# TERMINAL OUTPUT
# ═══════════════════════════════════════════════════════════════════════════════

sub banner {
    print colored(['cyan'], <<'BANNER');
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗                       ║
║   ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗   USB-DETECTOR       ║
║   ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║   Mobile USB Intel   ║
║   ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║   v1.0 Perl Edition  ║
║   ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║                      ║
║   ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝                      ║
║                                                                               ║
║   Mobile Security Framework - USB Device Intelligence                         ║
╚═══════════════════════════════════════════════════════════════════════════════╝
BANNER
}

sub info    { print colored(['green'],  "[+] ") . "@_\n"; }
sub warn_   { print colored(['yellow'], "[!] ") . "@_\n"; }
sub error   { print colored(['red'],    "[-] ") . "@_\n"; }
sub debug   { print colored(['blue'],   "[*] ") . "@_\n" if $ENV{DEBUG}; }

# ═══════════════════════════════════════════════════════════════════════════════
# USB DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

sub detect_usb_devices {
    my @devices;
    
    # Try lsusb first
    if (-x '/usr/bin/lsusb' || -x '/bin/lsusb') {
        my @lsusb = `lsusb 2>/dev/null`;
        foreach my $line (@lsusb) {
            if ($line =~ /Bus\s+(\d+)\s+Device\s+(\d+):\s+ID\s+([0-9a-f]{4}):([0-9a-f]{4})\s+(.*)$/i) {
                push @devices, {
                    bus     => $1,
                    device  => $2,
                    vendor  => $3,
                    product => $4,
                    name    => $5,
                };
            }
        }
    }
    
    # Also check /sys/bus/usb/devices
    if (-d '/sys/bus/usb/devices') {
        opendir(my $dh, '/sys/bus/usb/devices') or return @devices;
        while (my $dev = readdir($dh)) {
            next if $dev =~ /^\./;
            my $path = "/sys/bus/usb/devices/$dev";
            next unless -d $path;
            next unless -f "$path/idVendor";
            
            my $vendor  = read_sysfs("$path/idVendor");
            my $product = read_sysfs("$path/idProduct");
            my $mfg     = read_sysfs("$path/manufacturer");
            my $prod    = read_sysfs("$path/product");
            my $serial  = read_sysfs("$path/serial");
            
            next unless $vendor && $product;
            
            # Check if already detected via lsusb
            my $found = 0;
            foreach my $d (@devices) {
                if ($d->{vendor} eq $vendor && $d->{product} eq $product) {
                    $d->{manufacturer} = $mfg if $mfg;
                    $d->{product_name} = $prod if $prod;
                    $d->{serial} = $serial if $serial;
                    $d->{sysfs_path} = $path;
                    $found = 1;
                    last;
                }
            }
        }
        closedir($dh);
    }
    
    return @devices;
}

sub read_sysfs {
    my ($path) = @_;
    return undef unless -f $path;
    open(my $fh, '<', $path) or return undef;
    my $val = <$fh>;
    close($fh);
    chomp($val) if $val;
    return $val;
}

# ═══════════════════════════════════════════════════════════════════════════════
# MOBILE DEVICE FILTERING
# ═══════════════════════════════════════════════════════════════════════════════

sub is_mobile_device {
    my ($device) = @_;
    my $vendor_lc = lc($device->{vendor});
    
    # Check known mobile vendors
    return 1 if exists $VENDORS{$vendor_lc};
    
    # Check for common mobile USB classes
    my $name_lc = lc($device->{name} // '');
    return 1 if $name_lc =~ /android|mtp|adb|phone|mobile|fastboot/;
    
    # Check product hints
    my $product_lc = lc($device->{product});
    return 1 if exists $PRODUCT_HINTS{$product_lc};
    
    return 0;
}

sub detect_device_mode {
    my ($device) = @_;
    my $vendor_lc  = lc($device->{vendor});
    my $product_lc = lc($device->{product});
    my $name_lc    = lc($device->{name} // '');
    
    # Detect mode from product ID patterns
    return 'fastboot' if $name_lc =~ /fastboot/i;
    return 'fastboot' if $product_lc =~ /^(d00d|4ee7|d002)$/;
    
    return 'recovery' if $name_lc =~ /recovery/i;
    return 'recovery' if $product_lc eq 'b00b';
    
    return 'adb' if $name_lc =~ /adb|debug/i;
    return 'adb' if $product_lc =~ /^(4ee2|d001|0c02)$/;
    
    return 'mtp' if $name_lc =~ /mtp|media/i;
    return 'mtp' if $product_lc eq '4ee1';
    
    return 'ptp' if $name_lc =~ /ptp|camera/i;
    
    return 'unknown';
}

# ═══════════════════════════════════════════════════════════════════════════════
# ADB DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

sub check_adb_devices {
    return () unless -x '/usr/bin/adb' || -x '/usr/local/bin/adb';
    
    my @adb_devices;
    my @output = `adb devices -l 2>/dev/null`;
    
    foreach my $line (@output) {
        next if $line =~ /^List of devices/;
        next unless $line =~ /\S/;
        
        if ($line =~ /^(\S+)\s+(device|unauthorized|offline|recovery|sideload)\s*(.*)$/) {
            my %dev = (
                serial => $1,
                state  => $2,
                info   => $3 // '',
            );
            
            # Parse additional info
            if ($dev{info} =~ /product:(\S+)/) { $dev{product} = $1; }
            if ($dev{info} =~ /model:(\S+)/)   { $dev{model} = $1; }
            if ($dev{info} =~ /device:(\S+)/)  { $dev{device} = $1; }
            
            push @adb_devices, \%dev;
        }
    }
    
    return @adb_devices;
}

sub check_fastboot_devices {
    return () unless -x '/usr/bin/fastboot' || -x '/usr/local/bin/fastboot';
    
    my @fb_devices;
    my @output = `fastboot devices 2>/dev/null`;
    
    foreach my $line (@output) {
        if ($line =~ /^(\S+)\s+(fastboot|bootloader)/) {
            push @fb_devices, {
                serial => $1,
                mode   => $2,
            };
        }
    }
    
    return @fb_devices;
}

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

sub display_device {
    my ($device, $index) = @_;
    
    my $vendor_name = $VENDORS{lc($device->{vendor})} // 'Unknown';
    my $mode = detect_device_mode($device);
    
    print colored(['white'], "─" x 60) . "\n";
    printf colored(['cyan'], "DEVICE #%d\n"), $index;
    print colored(['white'], "─" x 60) . "\n";
    
    printf "  %-20s %s\n", "Vendor ID:",    uc($device->{vendor});
    printf "  %-20s %s\n", "Product ID:",   uc($device->{product});
    printf "  %-20s %s\n", "Manufacturer:", $vendor_name;
    printf "  %-20s %s\n", "Description:",  $device->{name} // 'N/A';
    
    if ($device->{serial}) {
        printf "  %-20s %s\n", "Serial:", $device->{serial};
    }
    
    # Mode with color
    my $mode_color = {
        'adb'      => 'green',
        'fastboot' => 'yellow',
        'recovery' => 'red',
        'mtp'      => 'blue',
        'ptp'      => 'magenta',
        'unknown'  => 'white',
    }->{$mode} // 'white';
    
    printf "  %-20s %s\n", "Mode:", colored([$mode_color], uc($mode));
    
    if ($device->{sysfs_path}) {
        printf "  %-20s %s\n", "Sysfs:", $device->{sysfs_path};
    }
    
    print "\n";
}

sub display_adb_device {
    my ($device) = @_;
    
    my $state_color = {
        'device'       => 'green',
        'unauthorized' => 'yellow',
        'offline'      => 'red',
        'recovery'     => 'magenta',
        'sideload'     => 'cyan',
    }->{$device->{state}} // 'white';
    
    printf "  %-15s ", $device->{serial};
    printf "%s", colored([$state_color], sprintf("%-15s", uc($device->{state})));
    
    if ($device->{model}) {
        printf " %s", $device->{model};
    }
    print "\n";
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

sub main {
    my $watch    = 0;
    my $json     = 0;
    my $all      = 0;
    my $help     = 0;
    my $interval = 2;
    
    GetOptions(
        'watch|w'      => \$watch,
        'json|j'       => \$json,
        'all|a'        => \$all,
        'interval|i=i' => \$interval,
        'help|h'       => \$help,
    ) or die "Error in command line arguments\n";
    
    if ($help) {
        print <<'HELP';
USB-DETECTOR - NullKia Mobile USB Intelligence Tool

USAGE:
    usb_detector.pl [OPTIONS]

OPTIONS:
    -w, --watch         Continuous monitoring mode
    -a, --all           Show all USB devices (not just mobile)
    -j, --json          Output in JSON format
    -i, --interval N    Watch interval in seconds (default: 2)
    -h, --help          Show this help

EXAMPLES:
    usb_detector.pl              # Scan for mobile devices
    usb_detector.pl --all        # Show all USB devices
    usb_detector.pl --watch      # Continuous monitoring
    usb_detector.pl -w -i 5      # Watch with 5s interval

HELP
        exit 0;
    }
    
    banner() unless $json;
    
    do {
        my @usb_devices = detect_usb_devices();
        my @adb_devices = check_adb_devices();
        my @fb_devices  = check_fastboot_devices();
        
        # Filter mobile devices unless --all
        my @mobile_devices = $all ? @usb_devices : grep { is_mobile_device($_) } @usb_devices;
        
        unless ($json) {
            my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
            print colored(['white'], "\n[$timestamp] Scanning USB bus...\n\n");
            
            if (@mobile_devices) {
                info("Found " . scalar(@mobile_devices) . " mobile device(s):");
                print "\n";
                
                my $i = 1;
                foreach my $dev (@mobile_devices) {
                    display_device($dev, $i++);
                }
            } else {
                warn_("No mobile devices detected on USB bus");
            }
            
            # ADB devices
            if (@adb_devices) {
                print colored(['cyan'], "\nADB DEVICES:\n");
                print colored(['white'], "─" x 50) . "\n";
                foreach my $dev (@adb_devices) {
                    display_adb_device($dev);
                }
            }
            
            # Fastboot devices
            if (@fb_devices) {
                print colored(['yellow'], "\nFASTBOOT DEVICES:\n");
                print colored(['white'], "─" x 50) . "\n";
                foreach my $dev (@fb_devices) {
                    printf "  %-15s %s\n", $dev->{serial}, uc($dev->{mode});
                }
            }
            
            print "\n";
        }
        
        if ($watch) {
            sleep $interval;
            system('clear') unless $json;
            banner() unless $json;
        }
        
    } while ($watch);
}

main();
