#!/usr/bin/env ruby
# ╔═══════════════════════════════════════════════════════════════════════════╗
# ║  NullKia ADB Scanner - Ruby Edition                                       ║
# ║  Scan network for exposed ADB debug bridges                               ║
# ║  github.com/bad-antics/nullkia | x.com/AnonAntics                       ║
# ╚═══════════════════════════════════════════════════════════════════════════╝

require 'socket'
require 'timeout'

module NullKia
  class ADBScanner
    VERSION = "1.0.0"
    ADB_PORT = 5555
    TIMEOUT = 2
    
    BANNER = <<~BANNER
    \e[36m
    ╭─────────────────────────────────────────╮
    │  NullKia ADB Scanner v#{VERSION}            │
    │  Network ADB Debug Bridge Detection     │
    │  github.com/bad-antics/nullkia          │
    ╰─────────────────────────────────────────╯
    \e[0m
    BANNER
    
    def initialize(target_range)
      @targets = parse_range(target_range)
      @found = []
      @threads = []
    end
    
    def parse_range(range)
      targets = []
      if range.include?('/')
        # CIDR notation
        network, bits = range.split('/')
        base = ip_to_int(network)
        mask = (0xFFFFFFFF << (32 - bits.to_i)) & 0xFFFFFFFF
        broadcast = base | ~mask & 0xFFFFFFFF
        (base..broadcast).each { |ip| targets << int_to_ip(ip) }
      elsif range.include?('-')
        # Range notation 192.168.1.1-254
        parts = range.split('.')
        if parts[3].include?('-')
          start_end = parts[3].split('-')
          (start_end[0].to_i..start_end[1].to_i).each do |i|
            targets << "#{parts[0..2].join('.')}.#{i}"
          end
        end
      else
        targets << range
      end
      targets
    end
    
    def ip_to_int(ip)
      ip.split('.').inject(0) { |total, part| (total << 8) + part.to_i }
    end
    
    def int_to_ip(int)
      [24, 16, 8, 0].map { |shift| (int >> shift) & 0xFF }.join('.')
    end
    
    def check_adb(ip)
      begin
        Timeout.timeout(TIMEOUT) do
          sock = TCPSocket.new(ip, ADB_PORT)
          sock.write("CNXN\x00\x00\x00\x01\x00\x10\x00\x00")
          response = sock.read(4) rescue nil
          sock.close
          
          if response
            @found << { ip: ip, port: ADB_PORT, status: 'OPEN' }
            puts "\e[32m[+] ADB FOUND: #{ip}:#{ADB_PORT}\e[0m"
            return true
          end
        end
      rescue Errno::ECONNREFUSED
        # Port closed
      rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH
        # Host unreachable
      rescue Timeout::Error
        # Timeout
      rescue => e
        # Other errors
      end
      false
    end
    
    def scan(threads: 50)
      puts BANNER
      puts "\e[33m[*] Scanning #{@targets.length} targets for ADB (port #{ADB_PORT})...\e[0m"
      puts "\e[90m[*] Using #{threads} threads\e[0m"
      puts
      
      start_time = Time.now
      
      @targets.each_slice(threads) do |batch|
        batch.each do |ip|
          @threads << Thread.new { check_adb(ip) }
        end
        @threads.each(&:join)
        @threads.clear
      end
      
      elapsed = Time.now - start_time
      
      puts
      puts "\e[36m═══════════════════════════════════════════════════════════════\e[0m"
      puts "\e[37m  Scan Complete\e[0m"
      puts "\e[36m═══════════════════════════════════════════════════════════════\e[0m"
      puts "  Targets scanned: #{@targets.length}"
      puts "  ADB bridges found: \e[32m#{@found.length}\e[0m"
      puts "  Time elapsed: #{elapsed.round(2)}s"
      puts "\e[36m═══════════════════════════════════════════════════════════════\e[0m"
      
      if @found.any?
        puts
        puts "\e[33m[!] Exposed ADB bridges:\e[0m"
        @found.each { |f| puts "    adb connect #{f[:ip]}:#{f[:port]}" }
      end
      
      @found
    end
  end
end

# Main execution
if __FILE__ == $0
  if ARGV.empty?
    puts "Usage: #{$0} <target>"
    puts "Examples:"
    puts "  #{$0} 192.168.1.0/24"
    puts "  #{$0} 192.168.1.1-254"
    puts "  #{$0} 10.0.0.5"
    exit 1
  end
  
  scanner = NullKia::ADBScanner.new(ARGV[0])
  scanner.scan(threads: ARGV[1]&.to_i || 50)
end
