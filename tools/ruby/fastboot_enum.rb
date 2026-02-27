#!/usr/bin/env ruby
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  NullKia Fastboot Enumerator - Ruby Edition                               ║
# ║  Enumerate connected fastboot devices and gather intel                    ║
# ║  github.com/bad-antics/nullkia | x.com/AnonAntics                       ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

module NullKia
  class FastbootEnum
    VERSION = "1.0.0"
    
    VARIABLES = %w[
      product variant serialno secure
      unlocked off-mode-charge
      battery-voltage battery-soc-ok
      slot-count current-slot
      max-download-size partition-type:boot
      partition-size:boot has-slot:boot
      version-bootloader version-baseband
      version-hardware version
    ]
    
    BANNER = <<~BANNER
    \e[35m
    ╭─────────────────────────────────────────╮
    │  NullKia Fastboot Enumerator v#{VERSION}    │
    │  Device Intelligence Gathering          │
    │  github.com/bad-antics/nullkia          │
    ╰─────────────────────────────────────────╯
    \e[0m
    BANNER
    
    def initialize
      @devices = []
      @info = {}
    end
    
    def check_fastboot
      `which fastboot 2>/dev/null`.strip.empty? ? nil : true
    end
    
    def list_devices
      output = `fastboot devices 2>/dev/null`.strip
      return [] if output.empty?
      
      output.lines.map do |line|
        parts = line.strip.split(/\s+/)
        { serial: parts[0], mode: parts[1] || 'fastboot' }
      end
    end
    
    def get_var(var, serial = nil)
      cmd = serial ? "fastboot -s #{serial} getvar #{var} 2>&1" : "fastboot getvar #{var} 2>&1"
      output = `#{cmd}`.strip
      
      # Parse fastboot output
      if output =~ /#{Regexp.escape(var)}:\s*(.+)/i
        return $1.strip
      elsif output =~ /OKAY/
        return output.lines.first&.strip
      end
      nil
    end
    
    def enumerate(serial = nil)
      puts BANNER
      
      unless check_fastboot
        puts "\e[31m[!] fastboot not found in PATH\e[0m"
        puts "    Install Android Platform Tools"
        return
      end
      
      @devices = list_devices
      
      if @devices.empty?
        puts "\e[33m[!] No fastboot devices detected\e[0m"
        puts "    Ensure device is in fastboot/bootloader mode"
        return
      end
      
      puts "\e[32m[+] Found #{@devices.length} device(s)\e[0m"
      puts
      
      @devices.each do |device|
        next if serial && device[:serial] != serial
        
        puts "\e[36m═══════════════════════════════════════════════════════════════\e[0m"
        puts "\e[37m  Device: #{device[:serial]}\e[0m"
        puts "\e[36m═══════════════════════════════════════════════════════════════\e[0m"
        
        info = {}
        
        VARIABLES.each do |var|
          value = get_var(var, device[:serial])
          if value && !value.empty?
            info[var] = value
            
            # Color-code security-relevant vars
            display = case var
            when 'unlocked'
              value == 'yes' ? "\e[32m#{value}\e[0m" : "\e[31m#{value}\e[0m"
            when 'secure'
              value == 'yes' ? "\e[31m#{value}\e[0m" : "\e[32m#{value}\e[0m"
            else
              value
            end
            
            puts "  #{var.ljust(25)} #{display}"
          end
        end
        
        @info[device[:serial]] = info
        
        # Security assessment
        puts
        puts "\e[33m  Security Assessment:\e[0m"
        
        if info['unlocked'] == 'yes'
          puts "    \e[32m✓ Bootloader UNLOCKED - full access\e[0m"
        elsif info['unlocked'] == 'no'
          puts "    \e[31m✗ Bootloader LOCKED\e[0m"
        end
        
        if info['secure'] == 'no'
          puts "    \e[32m✓ Secure boot DISABLED\e[0m"
        elsif info['secure'] == 'yes'
          puts "    \e[33m⚠ Secure boot ENABLED\e[0m"
        end
        
        puts
      end
      
      @info
    end
    
    def export_json(filename = nil)
      require 'json'
      filename ||= "fastboot_enum_#{Time.now.strftime('%Y%m%d_%H%M%S')}.json"
      File.write(filename, JSON.pretty_generate(@info))
      puts "\e[32m[+] Exported to #{filename}\e[0m"
    end
  end
end

# Main execution
if __FILE__ == $0
  enum = NullKia::FastbootEnum.new
  enum.enumerate(ARGV[0])
  enum.export_json if ARGV.include?('--json')
end
