#!/usr/bin/env tclsh
#═══════════════════════════════════════════════════════════════════════════════
#  ███╗   ██╗██╗   ██╗██╗     ██╗     ██╗  ██╗██╗ █████╗ 
#  ████╗  ██║██║   ██║██║     ██║     ██║ ██╔╝██║██╔══██╗
#  ██╔██╗ ██║██║   ██║██║     ██║     █████╔╝ ██║███████║    DEVICE-POLLER
#  ██║╚██╗██║██║   ██║██║     ██║     ██╔═██╗ ██║██╔══██║    TCL USB/ADB Monitor
#  ██║ ╚████║╚██████╔╝███████╗███████╗██║  ██╗██║██║  ██║    v1.0
#  ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝
#═══════════════════════════════════════════════════════════════════════════════
# NullKia Mobile Security Framework - TCL Device Polling Tool
# Continuously monitors for device connections/disconnections
#═══════════════════════════════════════════════════════════════════════════════

package require Tcl 8.5

namespace eval NullKia {
    variable VERSION "1.0.0"
    variable poll_interval 2000
    variable known_devices [dict create]
    variable device_history [list]
    variable max_history 100
    
    # ANSI Colors
    variable colors
    array set colors {
        reset   "\033\[0m"
        red     "\033\[0;31m"
        green   "\033\[0;32m"
        yellow  "\033\[0;33m"
        blue    "\033\[0;34m"
        magenta "\033\[0;35m"
        cyan    "\033\[0;36m"
        white   "\033\[1;37m"
        gray    "\033\[0;90m"
    }
    
    # Known mobile vendor IDs
    variable vendors
    array set vendors {
        18d1 "Google"
        04e8 "Samsung"
        22b8 "Motorola"
        0bb4 "HTC"
        12d1 "Huawei"
        2717 "Xiaomi"
        1004 "LG"
        0fce "Sony"
        2a70 "OnePlus"
        22d9 "OPPO"
        29a9 "Vivo"
        05c6 "Qualcomm"
        1949 "Amazon"
        2ae5 "Fairphone"
        17ef "Lenovo"
    }
}

proc NullKia::banner {} {
    variable colors
    puts "$colors(cyan)╔═══════════════════════════════════════════════════════════════════════════════╗$colors(reset)"
    puts "$colors(cyan)║$colors(white)  DEVICE-POLLER v1.0 - NullKia TCL USB/ADB Monitor$colors(cyan)                           ║$colors(reset)"
    puts "$colors(cyan)╚═══════════════════════════════════════════════════════════════════════════════╝$colors(reset)"
    puts ""
}

proc NullKia::log {level msg} {
    variable colors
    set timestamp [clock format [clock seconds] -format "%H:%M:%S"]
    
    switch $level {
        "info"  { puts "$colors(green)\[$timestamp\] \[+\]$colors(reset) $msg" }
        "warn"  { puts "$colors(yellow)\[$timestamp\] \[!\]$colors(reset) $msg" }
        "error" { puts "$colors(red)\[$timestamp\] \[-\]$colors(reset) $msg" }
        "event" { puts "$colors(magenta)\[$timestamp\] \[*\]$colors(reset) $msg" }
        default { puts "\[$timestamp\] $msg" }
    }
}

proc NullKia::get_adb_devices {} {
    set devices [dict create]
    
    if {[catch {set output [exec adb devices -l 2>/dev/null]} err]} {
        return $devices
    }
    
    foreach line [split $output "\n"] {
        if {[regexp {^(\S+)\s+(device|unauthorized|offline|recovery)\s*(.*)$} $line -> serial state info]} {
            set dev [dict create serial $serial state $state]
            
            # Parse additional info
            if {[regexp {product:(\S+)} $info -> product]} {
                dict set dev product $product
            }
            if {[regexp {model:(\S+)} $info -> model]} {
                dict set dev model $model
            }
            if {[regexp {device:(\S+)} $info -> device]} {
                dict set dev device $device
            }
            
            dict set devices $serial $dev
        }
    }
    
    return $devices
}

proc NullKia::get_usb_devices {} {
    set devices [dict create]
    
    if {[catch {set output [exec lsusb 2>/dev/null]} err]} {
        return $devices
    }
    
    foreach line [split $output "\n"] {
        if {[regexp {Bus\s+(\d+)\s+Device\s+(\d+):\s+ID\s+([0-9a-f]{4}):([0-9a-f]{4})\s+(.*)$} $line -> bus dev vendor product name]} {
            set key "${vendor}:${product}"
            dict set devices $key [dict create \
                bus $bus \
                device $dev \
                vendor $vendor \
                product $product \
                name $name]
        }
    }
    
    return $devices
}

proc NullKia::is_mobile_vendor {vendor_id} {
    variable vendors
    return [info exists vendors([string tolower $vendor_id])]
}

proc NullKia::get_vendor_name {vendor_id} {
    variable vendors
    set vid [string tolower $vendor_id]
    if {[info exists vendors($vid)]} {
        return $vendors($vid)
    }
    return "Unknown"
}

proc NullKia::add_history {event_type device_info} {
    variable device_history
    variable max_history
    
    set entry [dict create \
        timestamp [clock seconds] \
        event $event_type \
        info $device_info]
    
    lappend device_history $entry
    
    # Trim history if too large
    if {[llength $device_history] > $max_history} {
        set device_history [lrange $device_history end-[expr {$max_history-1}] end]
    }
}

proc NullKia::check_devices {} {
    variable known_devices
    variable colors
    
    # Get current ADB devices
    set current_adb [get_adb_devices]
    
    # Get current USB devices (filter mobile vendors)
    set all_usb [get_usb_devices]
    set current_usb [dict create]
    dict for {key dev} $all_usb {
        set vendor [dict get $dev vendor]
        if {[is_mobile_vendor $vendor]} {
            dict set current_usb $key $dev
        }
    }
    
    # Check for new ADB devices
    dict for {serial dev} $current_adb {
        if {![dict exists $known_devices "adb:$serial"]} {
            set state [dict get $dev state]
            set model [expr {[dict exists $dev model] ? [dict get $dev model] : "Unknown"}]
            
            log "event" "$colors(green)NEW ADB DEVICE:$colors(reset) $serial ($model) - State: $state"
            add_history "adb_connect" $dev
            dict set known_devices "adb:$serial" $dev
        } else {
            # Check for state changes
            set old_state [dict get [dict get $known_devices "adb:$serial"] state]
            set new_state [dict get $dev state]
            if {$old_state ne $new_state} {
                log "event" "$colors(yellow)STATE CHANGE:$colors(reset) $serial: $old_state -> $new_state"
                add_history "adb_state_change" $dev
                dict set known_devices "adb:$serial" $dev
            }
        }
    }
    
    # Check for disconnected ADB devices
    set adb_keys [list]
    dict for {key dev} $known_devices {
        if {[string match "adb:*" $key]} {
            lappend adb_keys $key
        }
    }
    foreach key $adb_keys {
        set serial [string range $key 4 end]
        if {![dict exists $current_adb $serial]} {
            set dev [dict get $known_devices $key]
            set model [expr {[dict exists $dev model] ? [dict get $dev model] : "Unknown"}]
            log "event" "$colors(red)ADB DISCONNECTED:$colors(reset) $serial ($model)"
            add_history "adb_disconnect" $dev
            dict unset known_devices $key
        }
    }
    
    # Check for new USB devices
    dict for {key dev} $current_usb {
        if {![dict exists $known_devices "usb:$key"]} {
            set vendor [dict get $dev vendor]
            set vendor_name [get_vendor_name $vendor]
            set name [dict get $dev name]
            
            log "event" "$colors(cyan)NEW USB DEVICE:$colors(reset) $vendor_name - $name"
            add_history "usb_connect" $dev
            dict set known_devices "usb:$key" $dev
        }
    }
    
    # Check for disconnected USB devices
    set usb_keys [list]
    dict for {key dev} $known_devices {
        if {[string match "usb:*" $key]} {
            lappend usb_keys $key
        }
    }
    foreach key $usb_keys {
        set usb_key [string range $key 4 end]
        if {![dict exists $current_usb $usb_key]} {
            set dev [dict get $known_devices $key]
            set name [dict get $dev name]
            log "event" "$colors(red)USB DISCONNECTED:$colors(reset) $name"
            add_history "usb_disconnect" $dev
            dict unset known_devices $key
        }
    }
}

proc NullKia::show_status {} {
    variable known_devices
    variable colors
    
    puts ""
    puts "$colors(white)═══════════════════════════════════════════════════════════════$colors(reset)"
    puts "$colors(white)  CURRENT CONNECTED DEVICES$colors(reset)"
    puts "$colors(white)═══════════════════════════════════════════════════════════════$colors(reset)"
    
    set adb_count 0
    set usb_count 0
    
    dict for {key dev} $known_devices {
        if {[string match "adb:*" $key]} {
            incr adb_count
            set serial [dict get $dev serial]
            set state [dict get $dev state]
            set model [expr {[dict exists $dev model] ? [dict get $dev model] : "Unknown"}]
            puts "  $colors(green)\[ADB\]$colors(reset) $serial ($model) - $state"
        }
    }
    
    dict for {key dev} $known_devices {
        if {[string match "usb:*" $key]} {
            incr usb_count
            set vendor [dict get $dev vendor]
            set vendor_name [get_vendor_name $vendor]
            set name [dict get $dev name]
            puts "  $colors(cyan)\[USB\]$colors(reset) $vendor_name - $name"
        }
    }
    
    if {$adb_count == 0 && $usb_count == 0} {
        puts "  $colors(gray)No mobile devices connected$colors(reset)"
    }
    
    puts "$colors(white)═══════════════════════════════════════════════════════════════$colors(reset)"
    puts ""
}

proc NullKia::poll_loop {} {
    variable poll_interval
    
    check_devices
    after $poll_interval [list NullKia::poll_loop]
}

proc NullKia::main {args} {
    variable poll_interval
    variable colors
    
    # Parse arguments
    set watch 0
    set show_help 0
    set interval 2
    
    foreach arg $args {
        switch -glob $arg {
            "-w" - "--watch" { set watch 1 }
            "-h" - "--help"  { set show_help 1 }
            "-i*" { regexp {-i(\d+)} $arg -> interval }
            "--interval=*" { regexp {--interval=(\d+)} $arg -> interval }
        }
    }
    
    if {$show_help} {
        puts "DEVICE-POLLER - NullKia TCL USB/ADB Monitor"
        puts ""
        puts "USAGE:"
        puts "    device_poller.tcl \[OPTIONS\]"
        puts ""
        puts "OPTIONS:"
        puts "    -w, --watch         Continuous monitoring mode"
        puts "    -i N, --interval=N  Poll interval in seconds (default: 2)"
        puts "    -h, --help          Show this help"
        puts ""
        puts "EXAMPLES:"
        puts "    device_poller.tcl              # One-time scan"
        puts "    device_poller.tcl -w           # Continuous monitoring"
        puts "    device_poller.tcl -w -i5       # Monitor every 5 seconds"
        return
    }
    
    banner
    
    set poll_interval [expr {$interval * 1000}]
    
    # Initial scan
    log "info" "Scanning for mobile devices..."
    check_devices
    show_status
    
    if {$watch} {
        log "info" "Starting continuous monitoring (Ctrl+C to stop)..."
        puts ""
        
        poll_loop
        vwait forever
    }
}

# Run main
NullKia::main {*}$argv
