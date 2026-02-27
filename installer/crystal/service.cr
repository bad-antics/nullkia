# NullKia Service Manager - Crystal
# Ruby-like syntax with C performance
# @author bad-antics
# @twitter x.com/AnonAntics

require "json"
require "http/server"
require "option_parser"
require "file_utils"
require "digest/md5"

VERSION = "2.0.0"
BANNER = <<-BANNER
╭──────────────────────────────────────────╮
│        📱 NULLKIA SERVICE MANAGER        │
│       ════════════════════════════       │
│                                          │
│   🔧 Service Control Daemon v2.0.0       │
│   📡 REST API: http://127.0.0.1:9999     │
│   💾 Status: Running                     │
│                                          │
│            bad-antics | NullSec         │
╰──────────────────────────────────────────╯
BANNER

module NullKia
  # Configuration
  class Config
    include JSON::Serializable

    property host : String = "127.0.0.1"
    property port : Int32 = 9999
    property log_level : String = "info"
    property data_dir : String = "~/.nullkia/data"
    property license_key : String = ""
    property premium : Bool = false

    def initialize
    end

    def self.load(path : String) : Config
      if File.exists?(path)
        Config.from_json(File.read(path))
      else
        Config.new
      end
    end

    def save(path : String)
      File.write(path, self.to_json)
    end
  end

  # License validation
  class LicenseManager
    enum Tier
      Free
      Premium
      Enterprise
    end

    property tier : Tier = Tier::Free
    property key : String = ""
    property valid : Bool = false
    property expiry : Time?

    def initialize(@key : String = "")
      validate if @key.size > 0
    end

    def validate
      return unless @key.starts_with?("NKIA-")
      return unless @key.size == 24

      parts = @key.split("-")
      return unless parts.size == 5

      @tier = case parts[1][0..1]
              when "PR" then Tier::Premium
              when "EN" then Tier::Enterprise
              else Tier::Free
              end

      @valid = true
    end

    def premium?
      @valid && @tier != Tier::Free
    end

    def to_json(builder : JSON::Builder)
      builder.object do
        builder.field "tier", @tier.to_s
        builder.field "valid", @valid
        builder.field "premium", premium?
      end
    end
  end

  # Device detection
  class DeviceDetector
    struct Device
      include JSON::Serializable

      property id : String
      property name : String
      property manufacturer : String
      property model : String
      property serial : String
      property connection : String
      property status : String
    end

    def self.scan : Array(Device)
      devices = [] of Device

      # USB device detection (Linux)
      {% if flag?(:linux) %}
        if File.exists?("/sys/bus/usb/devices")
          Dir.children("/sys/bus/usb/devices").each do |dev|
            path = "/sys/bus/usb/devices/#{dev}"
            next unless File.exists?("#{path}/idVendor")

            vendor_id = File.read("#{path}/idVendor").strip rescue "0000"
            product_id = File.read("#{path}/idProduct").strip rescue "0000"
            manufacturer = File.read("#{path}/manufacturer").strip rescue "Unknown"
            product = File.read("#{path}/product").strip rescue "Unknown"
            serial = File.read("#{path}/serial").strip rescue "N/A"

            # Check if it's a phone (common vendor IDs)
            phone_vendors = ["04e8", "05ac", "2717", "22b8", "18d1", "0bb4", "2a70"]
            
            if phone_vendors.includes?(vendor_id)
              devices << Device.new(
                id: "#{vendor_id}:#{product_id}",
                name: product,
                manufacturer: get_manufacturer_name(vendor_id),
                model: product,
                serial: serial,
                connection: "USB",
                status: "connected"
              )
            end
          end
        end
      {% end %}

      # ADB devices
      adb_output = `adb devices -l 2>/dev/null` rescue ""
      adb_output.each_line do |line|
        next if line.starts_with?("List") || line.empty?
        
        parts = line.split(/\s+/)
        next unless parts.size >= 2

        serial = parts[0]
        status = parts[1]

        model = "Unknown"
        if match = line.match(/model:(\S+)/)
          model = match[1]
        end

        devices << Device.new(
          id: serial,
          name: model,
          manufacturer: detect_manufacturer(model),
          model: model,
          serial: serial,
          connection: "ADB",
          status: status
        )
      end

      devices
    end

    private def self.get_manufacturer_name(vendor_id : String) : String
      case vendor_id
      when "04e8" then "Samsung"
      when "05ac" then "Apple"
      when "2717" then "Xiaomi"
      when "22b8" then "Motorola"
      when "18d1" then "Google"
      when "0bb4" then "HTC"
      when "2a70" then "OnePlus"
      when "12d1" then "Huawei"
      when "0fce" then "Sony"
      when "0421" then "Nokia"
      else "Unknown"
      end
    end

    private def self.detect_manufacturer(model : String) : String
      model_lower = model.downcase
      
      return "Samsung" if model_lower.includes?("samsung") || model_lower.starts_with?("sm-")
      return "Apple" if model_lower.includes?("iphone") || model_lower.includes?("ipad")
      return "Google" if model_lower.includes?("pixel")
      return "OnePlus" if model_lower.includes?("oneplus")
      return "Xiaomi" if model_lower.includes?("xiaomi") || model_lower.includes?("redmi")
      return "Huawei" if model_lower.includes?("huawei")
      return "Motorola" if model_lower.includes?("moto")
      
      "Unknown"
    end
  end

  # Firmware tools
  class FirmwareManager
    struct FirmwareInfo
      include JSON::Serializable

      property device : String
      property version : String
      property build : String
      property security_patch : String
      property bootloader : String
      property baseband : String
    end

    def self.get_info(serial : String) : FirmwareInfo?
      # Get device info via ADB
      props = {} of String => String

      output = `adb -s #{serial} shell getprop 2>/dev/null` rescue ""
      output.each_line do |line|
        if match = line.match(/\[([^\]]+)\]: \[([^\]]*)\]/)
          props[match[1]] = match[2]
        end
      end

      return nil if props.empty?

      FirmwareInfo.new(
        device: props["ro.product.model"]? || "Unknown",
        version: props["ro.build.version.release"]? || "Unknown",
        build: props["ro.build.id"]? || "Unknown",
        security_patch: props["ro.build.version.security_patch"]? || "Unknown",
        bootloader: props["ro.bootloader"]? || "Unknown",
        baseband: props["ro.build.expect.baseband"]? || "Unknown"
      )
    end

    def self.dump(serial : String, output_path : String) : Bool
      # Create output directory
      FileUtils.mkdir_p(output_path)

      # Dump partitions
      partitions = ["boot", "recovery", "system", "vendor"]
      
      partitions.each do |partition|
        puts "Dumping #{partition}..."
        result = system("adb -s #{serial} pull /dev/block/by-name/#{partition} #{output_path}/#{partition}.img 2>/dev/null")
        puts result ? "✅ #{partition} dumped" : "⚠️ #{partition} skipped"
      end

      true
    end
  end

  # REST API Server
  class APIServer
    property config : Config
    property license : LicenseManager

    def initialize(@config : Config)
      @license = LicenseManager.new(@config.license_key)
    end

    def start
      puts BANNER
      puts "Starting API server on #{@config.host}:#{@config.port}..."

      server = HTTP::Server.new do |context|
        handle_request(context)
      end

      server.bind_tcp(@config.host, @config.port)
      puts "✅ Server running at http://#{@config.host}:#{@config.port}"
      puts "📱 Ready for device connections"
      puts "🔑 License: #{@license.tier}"
      puts ""
      
      server.listen
    end

    private def handle_request(context : HTTP::Server::Context)
      context.response.content_type = "application/json"
      
      path = context.request.path
      method = context.request.method

      case {method, path}
      when {"GET", "/"}
        json_response(context, {
          "name" => "NullKia API",
          "version" => VERSION,
          "author" => "bad-antics",
          "discord" => "x.com/AnonAntics",
          "status" => "running"
        })

      when {"GET", "/status"}
        json_response(context, {
          "status" => "online",
          "uptime" => Time.utc.to_unix,
          "license" => @license.tier.to_s,
          "premium" => @license.premium?
        })

      when {"GET", "/devices"}
        devices = DeviceDetector.scan
        json_response(context, {"devices" => devices, "count" => devices.size})

      when {"GET", "/devices/scan"}
        devices = DeviceDetector.scan
        json_response(context, {"devices" => devices, "count" => devices.size})

      when {"GET", "/license"}
        context.response.print(@license.to_json)

      when {"POST", "/license/activate"}
        body = context.request.body.try(&.gets_to_end) || "{}"
        data = JSON.parse(body)
        key = data["key"]?.try(&.as_s) || ""
        
        @license = LicenseManager.new(key)
        @config.license_key = key
        @config.premium = @license.premium?
        
        json_response(context, {
          "success" => @license.valid,
          "tier" => @license.tier.to_s,
          "message" => @license.valid ? "License activated" : "Invalid license"
        })

      else
        context.response.status = HTTP::Status::NOT_FOUND
        json_response(context, {"error" => "Not found"})
      end
    rescue ex
      context.response.status = HTTP::Status::INTERNAL_SERVER_ERROR
      json_response(context, {"error" => ex.message})
    end

    private def json_response(context, data)
      context.response.print(data.to_json)
    end

    private def require_premium(context) : Bool
      unless @license.premium?
        context.response.status = HTTP::Status::FORBIDDEN
        json_response(context, {
          "error" => "Premium required",
          "message" => "Get premium at x.com/AnonAntics"
        })
        return false
      end
      true
    end
  end
end

# Main entry point
config_path = Path.home / ".nullkia" / "config.json"
config = NullKia::Config.load(config_path.to_s)

OptionParser.parse do |parser|
  parser.banner = "NullKia Service Manager\nUsage: service [options]"

  parser.on("-p PORT", "--port=PORT", "API port (default: 9999)") do |port|
    config.port = port.to_i
  end

  parser.on("-k KEY", "--key=KEY", "License key") do |key|
    config.license_key = key
  end

  parser.on("-h", "--help", "Show help") do
    puts parser
    exit
  end

  parser.on("-v", "--version", "Show version") do
    puts "NullKia Service Manager v#{VERSION}"
    puts "bad-antics | x.com/AnonAntics"
    exit
  end
end

# Save config
FileUtils.mkdir_p(Path.home / ".nullkia")
config.save(config_path.to_s)

# Start server
server = NullKia::APIServer.new(config)
server.start
