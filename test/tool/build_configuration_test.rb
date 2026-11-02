require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rexml/document'
require_relative '../../tool/build_configuration'

class BuildConfigurationTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir('merp-build-test-')
    FileUtils.mkdir_p(File.join(@root, 'config'))
    write_json('qas.json', 'APP_ENV' => 'qas', 'API_BASE_URL' => 'https://qas.example.test')
    write_json('prd.json', 'APP_ENV' => 'prd', 'API_BASE_URL' => 'https://prd.example.test')
    write_json('mock.json', 'DEV_BYPASS_LOGIN' => true, 'APP_ENV' => 'mock')
    %w[dev qas prd].each do |profile|
      write_json("baidu_map.#{profile}.local.json", 'BAIDU_MAP_IOS_AK' => "#{profile}-ios", 'BAIDU_MAP_ANDROID_AK' => "#{profile}-android")
    end
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def write_json(name, data)
    File.write(File.join(@root, 'config', name), JSON.generate(data))
  end

  def resolve(profile, environment, overrides = {})
    MerpBuildConfiguration.resolve(profile, environment, overrides, root: @root)
  end

  def test_development_can_use_both_backends_without_switching_map_identity
    %w[qas prd mock].each do |environment|
      result = resolve('dev', environment)
      assert_equal environment, result['APP_ENV']
      assert_equal 'dev-ios', result['BAIDU_MAP_IOS_AK']
      assert_equal 'dev-android', result['BAIDU_MAP_ANDROID_AK']
    end
  end

  def test_map_key_cannot_leak_from_other_configuration
    result = resolve('qas', 'qas', 'BAIDU_MAP_IOS_AK' => 'old-personal-key')
    assert_equal 'qas-ios', result['BAIDU_MAP_IOS_AK']
    assert_raises(RuntimeError) { resolve('qas', 'prd') }
    assert_raises(RuntimeError) { resolve('prd', 'mock') }
  end

  def test_production_local_file_merges_instead_of_replacing_base
    write_json('prd.local.json', 'ENABLE_LOG' => true)
    assert_equal 'https://prd.example.test', resolve('prd', 'prd')['API_BASE_URL']
    write_json('prd.local.json', 'API_BASE_URL' => '')
    assert_raises(RuntimeError) { resolve('prd', 'prd') }
  end

  def test_enterprise_forces_mock_flags_off
    result = resolve('qas', 'qas', 'DEV_BYPASS_LOGIN' => 'true', 'MOCK_APP_UPDATE' => true)
    assert_equal false, result['DEV_BYPASS_LOGIN']
    assert_equal false, result['MOCK_APP_UPDATE']
  end

  def test_xcode_archive_discards_stale_dev_defines
    inherited = MerpBuildConfiguration.encode(resolve('dev', 'mock').merge('API_BASE_URL' => 'https://wrong.example.test'))
    result = MerpBuildConfiguration.for_xcode({ 'CONFIGURATION' => 'Release-qas', 'DART_DEFINES' => inherited }, root: @root)
    assert_equal 'https://qas.example.test', result['API_BASE_URL']
    assert_equal 'qas-ios', result['BAIDU_MAP_IOS_AK']
    assert_equal false, result['DEV_BYPASS_LOGIN']
  end

  def test_dev_profile_and_release_still_use_personal_key
    %w[Profile-dev Release-dev].each do |mode|
      result = MerpBuildConfiguration.for_xcode({ 'CONFIGURATION' => mode }, root: @root)
      assert_equal 'dev-ios', result['BAIDU_MAP_IOS_AK']
    end
  end

  def test_xcode_explicit_api_environment_replaces_stale_backend
    inherited = MerpBuildConfiguration.encode(resolve('dev', 'qas'))
    result = MerpBuildConfiguration.for_xcode({ 'CONFIGURATION' => 'Debug-dev', 'DART_DEFINES' => inherited, 'MERP_API_ENV' => 'prd' }, root: @root)
    assert_equal 'https://prd.example.test', result['API_BASE_URL']
    assert_equal 'dev-ios', result['BAIDU_MAP_IOS_AK']
  end

  def test_enterprise_missing_or_placeholder_map_key_fails
    write_json('baidu_map.qas.local.json', 'BAIDU_MAP_IOS_AK' => '请填写百度地图 iOS AK')
    assert_raises(RuntimeError) do
      MerpBuildConfiguration.for_xcode({ 'CONFIGURATION' => 'Release-qas' }, root: @root)
    end
  end

  def test_shared_schemes_select_development_or_distribution_launch
    source = File.expand_path('../..', __dir__)
    %w[dev qas prd].each do |profile|
      path = File.join(source, 'ios/Runner.xcodeproj/xcshareddata/xcschemes', "#{profile}.xcscheme")
      scheme = REXML::Document.new(File.read(path)).root
      launch = scheme.elements['LaunchAction']
      assert_equal "#{profile == 'dev' ? 'Debug' : 'Release'}-#{profile}", launch.attributes['buildConfiguration']
      assert_equal "Release-#{profile}", scheme.elements['ArchiveAction'].attributes['buildConfiguration']
      assert_equal '', launch.attributes['selectedDebuggerIdentifier'] unless profile == 'dev'
    end
  end

  def test_cli_uses_dev_for_runs_and_enterprise_for_builds
    source = File.expand_path('../..', __dir__)
    FileUtils.mkdir_p(File.join(@root, 'tool'))
    %w[app versions configure_ide build_configuration.rb].each do |file|
      FileUtils.cp(File.join(source, 'tool', file), File.join(@root, 'tool', file))
    end
    FileUtils.mkdir_p(File.join(@root, 'ios/Config'))
    Dir[File.join(source, 'ios/Config/*.example.xcconfig')].each { |file| FileUtils.cp(file, File.join(@root, 'ios/Config')) }
    FileUtils.cp(File.join(source, 'config/baidu_map.example.json'), File.join(@root, 'config'))
    FileUtils.cp(File.join(source, 'config/build_profiles.json'), File.join(@root, 'config'))
    File.write(File.join(@root, 'pubspec.yaml'), "version: 1.0.0+10000\n")
    platform = `uname -m`.strip == 'arm64' ? 'macos-arm64' : 'macos-x64'
    fvm_dir = File.join(@root, '.tool-cache/fvm/4.1.2', platform)
    FileUtils.mkdir_p(fvm_dir)
    fake_fvm = File.join(fvm_dir, 'fvm')
    File.write(fake_fvm, <<~'RUBY')
      #!/usr/bin/env ruby
      require 'json'
      require 'fileutils'
      args = ARGV
      config_path = args.find { |arg| arg.start_with?('--dart-define-from-file=') }.split('=', 2).last
      config = JSON.parse(File.read(config_path))
      puts "TEST_CAPTURE=#{JSON.generate({args: args, config: config})}"
      if args.include?('build')
        FileUtils.mkdir_p('build/ios/ipa')
        File.write('build/ios/ipa/test.ipa', 'test artifact')
      end
    RUBY
    FileUtils.chmod(0755, fake_fvm)
    %w[qas prd mock].each do |environment|
      output, status = Open3.capture2e({ 'CI' => 'true' }, 'bash', File.join(@root, 'tool/app'), 'run', environment, 'ios', '-d', 'test-device')
      assert status.success?, output
      capture = JSON.parse(output.lines.find { |line| line.start_with?('TEST_CAPTURE=') }.delete_prefix('TEST_CAPTURE='))
      assert_equal 'dev', capture['args'][capture['args'].index('--flavor') + 1]
      assert_equal environment, capture['config']['APP_ENV']
      assert_equal 'dev-ios', capture['config']['BAIDU_MAP_IOS_AK']
    end
    # Recovery must stop the installed dev package, never the enterprise QAS ID.
    fake_bin = File.join(@root, 'fake-bin')
    FileUtils.mkdir_p(fake_bin)
    fake_adb = File.join(fake_bin, 'adb')
    File.write(fake_adb, <<~'RUBY')
      #!/usr/bin/env ruby
      File.open(ENV.fetch('TEST_ADB_TRACE'), 'a') { |file| file.puts(ARGV.join(' ')) }
      puts 'device' if ARGV.include?('get-state')
    RUBY
    FileUtils.chmod(0755, fake_adb)
    fake_java = File.join(fake_bin, 'java')
    File.write(fake_java, "#!/bin/sh\nprintf 'openjdk version \"17\"\\n'\n")
    FileUtils.chmod(0755, fake_java)
    trace = File.join(@root, 'adb-trace')
    output, status = Open3.capture2e({ 'PATH' => "#{fake_bin}:#{ENV['PATH']}", 'JAVA_HOME' => '', 'TEST_ADB_TRACE' => trace },
      'bash', File.join(@root, 'tool/app'), 'run', 'qas', 'android', '-d', 'test-device', '--recover')
    assert status.success?, output
    assert_includes File.read(trace), 'shell am force-stop com.delta.merpdelta.qas'
    refute_includes File.read(trace), 'com.delta.MERPDeltaTest'
    %w[qas prd].each do |profile|
      output, status = Open3.capture2e({ 'CI' => 'true' }, 'bash', File.join(@root, 'tool/app'), 'build', profile, 'ios')
      assert status.success?, output
      capture = JSON.parse(output.lines.find { |line| line.start_with?('TEST_CAPTURE=') }.delete_prefix('TEST_CAPTURE='))
      assert_equal profile, capture['args'][capture['args'].index('--flavor') + 1]
      assert_equal 'enterprise', capture['args'][capture['args'].index('--export-method') + 1]
      assert_equal "#{profile}-ios", capture['config']['BAIDU_MAP_IOS_AK']
    end
  end
end
