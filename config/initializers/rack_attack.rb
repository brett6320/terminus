# frozen_string_literal: true

require "ipaddr"
require "rack/attack"
require "redis-client"

# :nocov:
DEFAULT_PRIVATE_SUBNETS = [
  IPAddr.new("10.0.0.0/8"),
  IPAddr.new("172.16.0.0/12"),
  IPAddr.new("192.168.0.0/16"),
  IPAddr.new("127.0.0.1"),
  IPAddr.new("::1")
].freeze

parse_subnets = lambda do |value|
  value.to_s.split(",").map { |address| IPAddr.new address.strip }
end

# Subnets exempt from throttling (trusted, e.g. your local network).
extra_allowed = parse_subnets.call ENV.fetch("RACK_ATTACK_ALLOWED_SUBNETS", "")
allowed_subnets = DEFAULT_PRIVATE_SUBNETS + extra_allowed

# Subnets allowed to reach administrative paths (Sidekiq Web, user management).
# Defaults to private/loopback so local networks keep working; set ADMIN_ALLOWED_SUBNETS
# to your own trusted ranges when exposing the server publicly.
extra_admin = parse_subnets.call ENV.fetch("ADMIN_ALLOWED_SUBNETS", "")
admin_subnets = DEFAULT_PRIVATE_SUBNETS + extra_admin

Rack::Attack.cache.store = RedisClient.new url: ENV.fetch("KEYVALUE_URL")
# :nocov:

ADMIN_PATHS = %r(\A/(sidekiq|users)(/|\z))
LOGIN_LIMIT = Integer ENV.fetch("RACK_ATTACK_LOGIN_LIMIT", "5")
JWT_LIMIT = Integer ENV.fetch("RACK_ATTACK_JWT_LIMIT", "10")
DEVICE_LIMIT = Integer ENV.fetch("RACK_ATTACK_DEVICE_LIMIT", "60")
REQUEST_LIMIT = Integer ENV.fetch("RACK_ATTACK_REQUEST_LIMIT", "300")
DEVICE_PATHS = %w[/api/display /api/log /api/setup].freeze

Rack::Attack.safelist "allow subnets" do |request|
  allowed_subnets.any? { |subnet| subnet.include? request.ip }
end

# Block administrative paths from outside the trusted admin subnets.
Rack::Attack.blocklist "admin ip" do |request|
  request.path.match?(ADMIN_PATHS) && admin_subnets.none? { |subnet| subnet.include? request.ip }
end

# Throttle login attempts to blunt credential stuffing.
Rack::Attack.throttle "login/ip", limit: LOGIN_LIMIT, period: 60 do |request|
  request.ip if request.post? && request.path == "/login"
end

# Throttle account registration.
Rack::Attack.throttle "register/ip", limit: LOGIN_LIMIT, period: 60 do |request|
  request.ip if request.post? && request.path == "/register"
end

# Throttle JWT refreshes.
Rack::Attack.throttle "jwt/ip", limit: JWT_LIMIT, period: 60 do |request|
  request.ip if request.post? && request.path == "/api/jwt"
end

# Throttle device firmware endpoints per device (MAC address in the ID header),
# falling back to IP when the header is absent.
Rack::Attack.throttle "device/id", limit: DEVICE_LIMIT, period: 60 do |request|
  next unless DEVICE_PATHS.include? request.path

  request.get_header("HTTP_ID") || request.get_header("HTTP_ACCESS_TOKEN") || request.ip
end

# Global per-IP ceiling as a catch-all.
Rack::Attack.throttle "req/ip", limit: REQUEST_LIMIT, period: 60, &:ip

Rack::Attack.throttled_responder = lambda do |request|
  retry_after = (request.env["rack.attack.match_data"] || {})[:period]
  [
    429,
    {"Content-Type" => "text/plain", "Retry-After" => retry_after.to_s},
    ["Too many requests. Retry later.\n"]
  ]
end
