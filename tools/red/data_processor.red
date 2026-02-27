Red [
    Title: "NullKia Data Processor"
    Author: "bad-antics"
    Version: 2.0.0
    Date: 2025-01-01
    Purpose: "Mobile data extraction and processing"
    Discord: "x.com/AnonAntics"
    GitHub: "bad-antics"
]

; ╭──────────────────────────────────────────╮
; │        📱 NULLKIA DATA PROCESSOR         │
; │       ════════════════════════════       │
; │                                          │
; │   🔧 Symbolic Data Processing            │
; │   📡 Call Log / SMS / Contact Extract    │
; │   💾 Database Analysis                   │
; │                                          │
; │            bad-antics | NullSec         │
; ╰──────────────────────────────────────────╯

VERSION: "2.0.0"
AUTHOR: "bad-antics"
DISCORD: "x.com/AnonAntics"

; Color functions
print-banner: does [
    print "^[[36m"
    print "╭──────────────────────────────────────────╮"
    print "│        📱 NULLKIA DATA PROCESSOR         │"
    print "│       ════════════════════════════       │"
    print "│                                          │"
    print "│   🔧 Symbolic Data Processing v2.0       │"
    print "│   📡 Call Log / SMS / Contact Extract    │"
    print "│   💾 Database Analysis                   │"
    print "│                                          │"
    print "│            bad-antics | NullSec         │"
    print "╰──────────────────────────────────────────╯"
    print "^[[0m"
]

print-success: func [msg [string!]] [
    print rejoin ["^[[32m✅ " msg "^[[0m"]
]

print-error: func [msg [string!]] [
    print rejoin ["^[[31m❌ " msg "^[[0m"]
]

print-warning: func [msg [string!]] [
    print rejoin ["^[[33m⚠️  " msg "^[[0m"]
]

print-info: func [msg [string!]] [
    print rejoin ["^[[34mℹ️  " msg "^[[0m"]
]

; License management
license-tier: 'free
license-key: none

validate-license: func [
    key [string!]
    /local parts tier-code
] [
    if not key [return 'free]
    if 24 <> length? key [return 'free]
    if not find/part key "NKIA-" 5 [return 'free]
    
    parts: split key "-"
    if 5 <> length? parts [return 'free]
    
    tier-code: copy/part pick parts 2 2
    
    case [
        tier-code = "PR" ['premium]
        tier-code = "EN" ['enterprise]
        true ['free]
    ]
]

is-premium: does [
    any [license-tier = 'premium license-tier = 'enterprise]
]

; ADB execution
adb-exec: func [
    args [block!]
    /local result
] [
    result: call/output rejoin ["adb " form args] ""
    either result [trim result] [""]
]

; Get connected devices
get-devices: func [
    /local output lines device devices
] [
    devices: copy []
    output: call/output "adb devices -l" ""
    
    if not output [return devices]
    
    lines: split output newline
    foreach line lines [
        if any [
            find/part line "List" 4
            empty? trim line
        ] [continue]
        
        parts: split line tab
        if 1 < length? parts [
            serial: first parts
            
            device: object [
                serial: serial
                model: adb-exec compose ["-s" (serial) "shell" "getprop" "ro.product.model"]
                manufacturer: adb-exec compose ["-s" (serial) "shell" "getprop" "ro.product.manufacturer"]
                rooted: false
            ]
            
            ; Check root
            root-check: adb-exec compose ["-s" (serial) "shell" "su" "-c" "id"]
            if find root-check "uid=0" [
                device/rooted: true
            ]
            
            append devices device
        ]
    ]
    
    devices
]

; Data extraction functions
extract-contacts: func [
    serial [string!]
    output-dir [string!]
    /local result contacts
] [
    unless is-premium [
        print-warning "Contact extraction requires premium license"
        print-warning "Get premium at x.com/AnonAntics"
        return none
    ]
    
    print-info "Extracting contacts..."
    
    ; Pull contacts database
    result: call/output rejoin [
        "adb -s " serial " shell su -c 'cat /data/data/com.android.providers.contacts/databases/contacts2.db'"
    ] ""
    
    if result [
        file-path: rejoin [output-dir "/contacts2.db"]
        write/binary file-path result
        print-success rejoin ["Saved contacts database to " file-path]
    ]
    
    ; Also try to get contacts via content provider
    contacts: adb-exec compose ["-s" (serial) "shell" "content" "query" "--uri" "content://contacts/phones"]
    
    if contacts [
        file-path: rejoin [output-dir "/contacts.txt"]
        write file-path contacts
        print-success rejoin ["Saved contacts list to " file-path]
    ]
    
    true
]

extract-sms: func [
    serial [string!]
    output-dir [string!]
    /local result
] [
    unless is-premium [
        print-warning "SMS extraction requires premium license"
        print-warning "Get premium at x.com/AnonAntics"
        return none
    ]
    
    print-info "Extracting SMS messages..."
    
    ; Pull SMS database
    result: call/output rejoin [
        "adb -s " serial " shell su -c 'cat /data/data/com.android.providers.telephony/databases/mmssms.db'"
    ] ""
    
    if result [
        file-path: rejoin [output-dir "/mmssms.db"]
        write/binary file-path result
        print-success rejoin ["Saved SMS database to " file-path]
    ]
    
    ; Also try content provider
    sms: adb-exec compose ["-s" (serial) "shell" "content" "query" "--uri" "content://sms"]
    
    if sms [
        file-path: rejoin [output-dir "/sms.txt"]
        write file-path sms
        print-success rejoin ["Saved SMS list to " file-path]
    ]
    
    true
]

extract-call-log: func [
    serial [string!]
    output-dir [string!]
    /local result
] [
    unless is-premium [
        print-warning "Call log extraction requires premium license"
        return none
    ]
    
    print-info "Extracting call log..."
    
    ; Pull call log via content provider
    calls: adb-exec compose ["-s" (serial) "shell" "content" "query" "--uri" "content://call_log/calls"]
    
    if calls [
        file-path: rejoin [output-dir "/call_log.txt"]
        write file-path calls
        print-success rejoin ["Saved call log to " file-path]
    ]
    
    ; Also pull the database
    result: call/output rejoin [
        "adb -s " serial " shell su -c 'cat /data/data/com.android.providers.contacts/databases/calllog.db'"
    ] ""
    
    if result [
        file-path: rejoin [output-dir "/calllog.db"]
        write/binary file-path result
        print-success rejoin ["Saved call log database to " file-path]
    ]
    
    true
]

extract-wifi-passwords: func [
    serial [string!]
    output-dir [string!]
    /local result
] [
    unless is-premium [
        print-warning "WiFi password extraction requires premium license"
        return none
    ]
    
    print-info "Extracting WiFi passwords..."
    
    ; Try new location (Android 8+)
    result: adb-exec compose ["-s" (serial) "shell" "su" "-c" "cat /data/misc/wifi/WifiConfigStore.xml"]
    
    if result [
        file-path: rejoin [output-dir "/WifiConfigStore.xml"]
        write file-path result
        print-success rejoin ["Saved WiFi config (new format) to " file-path]
    ]
    
    ; Try old location
    result: adb-exec compose ["-s" (serial) "shell" "su" "-c" "cat /data/misc/wifi/wpa_supplicant.conf"]
    
    if result [
        file-path: rejoin [output-dir "/wpa_supplicant.conf"]
        write file-path result
        print-success rejoin ["Saved WiFi config (old format) to " file-path]
    ]
    
    true
]

extract-accounts: func [
    serial [string!]
    output-dir [string!]
    /local result
] [
    unless is-premium [
        print-warning "Account extraction requires premium license"
        return none
    ]
    
    print-info "Extracting accounts..."
    
    ; Get accounts list
    result: adb-exec compose ["-s" (serial) "shell" "dumpsys" "account"]
    
    if result [
        file-path: rejoin [output-dir "/accounts.txt"]
        write file-path result
        print-success rejoin ["Saved accounts list to " file-path]
    ]
    
    ; Pull accounts database
    result: call/output rejoin [
        "adb -s " serial " shell su -c 'cat /data/system_ce/0/accounts_ce.db'"
    ] ""
    
    if result [
        file-path: rejoin [output-dir "/accounts_ce.db"]
        write/binary file-path result
        print-success rejoin ["Saved accounts database to " file-path]
    ]
    
    true
]

extract-browser-data: func [
    serial [string!]
    output-dir [string!]
    /local result
] [
    unless is-premium [
        print-warning "Browser data extraction requires premium license"
        return none
    ]
    
    print-info "Extracting browser data..."
    
    ; Chrome history
    result: call/output rejoin [
        "adb -s " serial " shell su -c 'cat /data/data/com.android.chrome/app_chrome/Default/History'"
    ] ""
    
    if result [
        file-path: rejoin [output-dir "/chrome_history.db"]
        write/binary file-path result
        print-success "Saved Chrome history"
    ]
    
    ; Chrome bookmarks
    result: adb-exec compose ["-s" (serial) "shell" "su" "-c" "cat /data/data/com.android.chrome/app_chrome/Default/Bookmarks"]
    
    if result [
        file-path: rejoin [output-dir "/chrome_bookmarks.json"]
        write file-path result
        print-success "Saved Chrome bookmarks"
    ]
    
    true
]

; Full extraction
full-extraction: func [
    serial [string!]
    /local output-dir timestamp
] [
    unless is-premium [
        print-warning "Full extraction requires premium license"
        print-warning "Get premium at x.com/AnonAntics"
        return none
    ]
    
    timestamp: now/precise
    output-dir: rejoin [
        home-dir "/.nullkia/extractions/"
        serial "_"
        replace/all form timestamp "/" "-"
    ]
    
    make-dir/deep output-dir
    
    print-info rejoin ["Output directory: " output-dir]
    print ""
    
    extract-contacts serial output-dir
    extract-sms serial output-dir
    extract-call-log serial output-dir
    extract-wifi-passwords serial output-dir
    extract-accounts serial output-dir
    extract-browser-data serial output-dir
    
    ; Write manifest
    manifest: rejoin [
        "NullKia Data Processor Extraction^/"
        "Version: " VERSION "^/"
        "Author: " AUTHOR "^/"
        "Discord: " DISCORD "^/"
        "^/"
        "Device: " serial "^/"
        "Timestamp: " form timestamp "^/"
        "^/"
        "Files extracted:^/"
        "- contacts2.db^/"
        "- contacts.txt^/"
        "- mmssms.db^/"
        "- sms.txt^/"
        "- call_log.txt^/"
        "- calllog.db^/"
        "- WifiConfigStore.xml^/"
        "- wpa_supplicant.conf^/"
        "- accounts.txt^/"
        "- accounts_ce.db^/"
        "- chrome_history.db^/"
        "- chrome_bookmarks.json^/"
    ]
    
    write rejoin [output-dir "/manifest.txt"] manifest
    
    print ""
    print-success rejoin ["Extraction complete: " output-dir]
    
    output-dir
]

; Interactive menu
home-dir: to-string system/options/home

run-interactive: func [
    /local devices device idx op serial
] [
    print-banner
    
    devices: get-devices
    
    if empty? devices [
        print-error "No devices connected"
        exit
    ]
    
    print ""
    print "📱 Connected Devices:"
    print ""
    
    idx: 1
    foreach device devices [
        print rejoin [
            "  [" idx "] "
            device/manufacturer " "
            device/model
        ]
        print rejoin ["      Serial: " device/serial]
        print rejoin ["      Status: " either device/rooted ["🔓 Rooted"] ["🔒 Not rooted"]]
        print ""
        idx: idx + 1
    ]
    
    serial: input "Select device [1-N]: "
    idx: to-integer serial
    
    if any [idx < 1 idx > length? devices] [
        print-error "Invalid selection"
        exit
    ]
    
    device: pick devices idx
    serial: device/serial
    
    unless device/rooted [
        print-warning "Device is not rooted. Most features require root."
    ]
    
    print ""
    print "📦 Operations:"
    print ""
    print "  [1] Extract contacts (Premium)"
    print "  [2] Extract SMS (Premium)"
    print "  [3] Extract call log (Premium)"
    print "  [4] Extract WiFi passwords (Premium)"
    print "  [5] Extract accounts (Premium)"
    print "  [6] Extract browser data (Premium)"
    print "  [7] Full extraction (Premium)"
    print "  [8] Device info (Free)"
    print "  [0] Exit"
    print ""
    
    op: input "Select operation: "
    op: to-integer op
    
    output-dir: rejoin [home-dir "/.nullkia/extractions/" serial]
    make-dir/deep output-dir
    
    switch op [
        1 [extract-contacts serial output-dir]
        2 [extract-sms serial output-dir]
        3 [extract-call-log serial output-dir]
        4 [extract-wifi-passwords serial output-dir]
        5 [extract-accounts serial output-dir]
        6 [extract-browser-data serial output-dir]
        7 [full-extraction serial]
        8 [
            print ""
            print-info "Device Information:"
            print ""
            props: [
                "ro.product.model"
                "ro.product.manufacturer"
                "ro.product.brand"
                "ro.build.version.release"
                "ro.build.version.sdk"
                "ro.build.id"
                "ro.serialno"
                "ro.build.fingerprint"
            ]
            foreach prop props [
                value: adb-exec compose ["-s" (serial) "shell" "getprop" (prop)]
                print rejoin ["  " prop ": " value]
            ]
        ]
        0 [print "Exiting..."]
    ]
    
    print ""
    print "─────────────────────────────────────────"
    print "📱 NullKia Data Processor"
    print "🔑 Premium: x.com/AnonAntics"
    print "🐦 GitHub: bad-antics"
    print "─────────────────────────────────────────"
]

; Main entry
parse-args: func [
    /local args key
] [
    args: system/script/args
    
    if args [
        args: split form args " "
        
        foreach [opt val] args [
            case [
                any [opt = "-k" opt = "--key"] [
                    license-key: val
                    license-tier: validate-license val
                    print-info rejoin ["License tier: " license-tier]
                ]
                any [opt = "-h" opt = "--help"] [
                    print rejoin ["NullKia Data Processor v" VERSION]
                    print rejoin [AUTHOR " | " DISCORD]
                    print ""
                    print "Usage: red data_processor.red [options]"
                    print ""
                    print "Options:"
                    print "  -k, --key KEY    License key"
                    print "  -h, --help       Show help"
                    print "  -v, --version    Show version"
                    quit
                ]
                any [opt = "-v" opt = "--version"] [
                    print rejoin ["NullKia Data Processor v" VERSION]
                    quit
                ]
            ]
        ]
    ]
]

; Run
parse-args
run-interactive
