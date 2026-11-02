#!/usr/bin/env ruby
# Shared config resolution for CLI and the Xcode Flutter build phase.
# Keys are resolved by installation identity, never by Debug/Release mode.
require 'json'
require 'base64'
require 'uri'

module MerpBuildConfiguration
  ROOT = File.expand_path('..', __dir__)
  MAP_KEYS = %w[BAIDU_MAP_ANDROID_AK BAIDU_MAP_IOS_AK BAIDU_MAP_WEB_AK].freeze

  def self.read_json(path)
    return {} unless File.file?(path)
    value = JSON.parse(File.read(path))
    raise "Expected JSON object: #{path}" unless value.is_a?(Hash)
    value
  end

  def self.resolve(profile, environment, overrides = {}, root: ROOT)
    raise 'Unknown build profile' unless %w[dev qas prd].include?(profile)
    raise 'Unknown API environment' unless %w[qas prd mock].include?(environment)
    if profile != 'dev' && profile != environment
      raise 'Enterprise identity must match its API environment; mock is development-only'
    end
    base = environment == 'mock' ? 'qas' : environment
    config_dir = File.join(root, 'config')
    result = read_json(File.join(config_dir, "#{base}.json"))
    result.merge!(read_json(File.join(config_dir, "#{base}.local.json")))
    if environment == 'mock'
      result.merge!(read_json(File.join(config_dir, 'mock.json')))
      result.merge!(read_json(File.join(config_dir, 'mock.local.json')))
    end
    result.merge!(read_json(File.join(config_dir, 'webview.local.json')))
    result.merge!(overrides)
    # Always replace keys as a set. Never inherit an enterprise AK from Generated.xcconfig.
    MAP_KEYS.each { |key| result[key] = '' }
    map_config = read_json(File.join(config_dir, "baidu_map.#{profile}.local.json"))
    MAP_KEYS.each do |key|
      value = map_config.fetch(key, '').to_s.strip
      # Old template contained Chinese placeholder text, which is not an AK.
      result[key] = value.ascii_only? ? value : ''
    end
    result['APP_ENV'] = environment
    result['MERP_BUILD_PROFILE'] = profile
    if profile != 'dev'
      result['DEV_BYPASS_LOGIN'] = false
      result['MOCK_APP_UPDATE'] = false
      result['MOCK_MENUS'] = false
    end
    if environment == 'prd'
      uri = URI.parse(result.fetch('API_BASE_URL', ''))
      raise 'Configure API_BASE_URL in config/prd.local.json' unless %w[http https].include?(uri.scheme) && uri.host
    end
    result
  end

  def self.decode(value)
    value.to_s.split(',').reject(&:empty?).to_h do |item|
      key, content = Base64.strict_decode64(item).split('=', 2)
      [key, content || '']
    end
  end

  def self.encode(values)
    values.map { |key, value| Base64.strict_encode64("#{key}=#{value}") }.join(',')
  end

  def self.for_xcode(env, root: ROOT)
    profile = env.fetch('CONFIGURATION').split('-').last
    # Unflavored Runner defaults to dev, matching the base xcconfigs.
    profile = 'dev' if %w[Debug Profile Release].include?(profile)
    inherited = decode(env['DART_DEFINES'])
    inherited = {} unless inherited['MERP_BUILD_PROFILE'] == profile
    environment = profile == 'dev' ? inherited.fetch('APP_ENV', 'qas') : profile
    explicit_env = env['MERP_API_ENV'].to_s.strip
    unless explicit_env.empty?
      inherited = {} if environment != explicit_env
      environment = explicit_env
    end
    result = resolve(profile, environment, inherited, root: root)
    if profile != 'dev' && result['BAIDU_MAP_IOS_AK'].to_s.strip.empty?
      raise "Fill BAIDU_MAP_IOS_AK in config/baidu_map.#{profile}.local.json"
    end
    result
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    if ARGV.first == 'xcode'
      puts MerpBuildConfiguration.encode(MerpBuildConfiguration.for_xcode(ENV))
    else
      profile, environment = ARGV
      puts JSON.pretty_generate(MerpBuildConfiguration.resolve(profile, environment))
    end
  rescue StandardError => error
    warn "MERP build configuration: #{error.message}"
    exit 1
  end
end
