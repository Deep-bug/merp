#!/usr/bin/env ruby
# Maintainer-only generator. Commit outputs; teammates do NOT need xcodeproj.
require 'json'
require 'fileutils'
require 'xcodeproj'
require 'rexml/document'

root = File.expand_path('..', __dir__)
project = Xcodeproj::Project.open(File.join(root, 'ios/Runner.xcodeproj'))
runner = project.targets.find { |target| target.name == 'Runner' }
tests = project.targets.find { |target| target.name == 'RunnerTests' }
abort 'Runner target not found' unless runner
profiles = JSON.parse(File.read(File.join(root, 'config/build_profiles.json')))
# Xcode also stores a UI-level Team hint outside buildSettings. Keep personal
# ownership out of the shared project; actual signing comes from the xcconfigs.
project.root_object.attributes.fetch('TargetAttributes', {}).each_value do |attributes|
  attributes.delete('DevelopmentTeam')
end
types = { 'Debug' => :debug, 'Profile' => :release, 'Release' => :release }
config_dir = File.join(root, 'ios/Config')
FileUtils.mkdir_p(config_dir)

# Preserve the working personal Team once, in an ignored local file.
dev_local = File.join(config_dir, 'Dev.local.xcconfig')
old = runner.build_configurations.find { |config| config.name == 'Debug-qas' }
if !File.exist?(dev_local) && old && old.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] == profiles['dev']['iosBundleId']
  team = old.build_settings['DEVELOPMENT_TEAM'].to_s
  if team.match?(/\A[A-Z0-9]+\z/)
    File.write(dev_local, "// Migrated personal development Team; never committed.\nDEVELOPMENT_TEAM = #{team}\n")
  end
end

flutter_group = project.main_group.find_subpath('Flutter', true)
def clone_configuration(owner, base, name, type)
  existing = owner.build_configurations.find { |config| config.name == name }
  return existing if existing
  source = owner.build_configurations.find { |config| config.name == base }
  abort "Missing #{base}" unless source
  target = owner.add_build_configuration(name, type)
  target.build_settings.update(source.build_settings)
  target.base_configuration_reference = source.base_configuration_reference
  target
end

def clear_identity_settings(config)
  # Target settings override xcconfigs; remove them so local Team overrides work.
  config.build_settings.keys.grep(/\A(?:PRODUCT_BUNDLE_IDENTIFIER|APP_DISPLAY_NAME|DEVELOPMENT_TEAM|CODE_SIGN_IDENTITY|CODE_SIGN_STYLE|PROVISIONING_PROFILE(?:_SPECIFIER)?)(?:\[|\z)/).each do |key|
    config.build_settings.delete(key)
  end
end

profiles.each do |profile, values|
  title = profile.capitalize
  development = profile == 'dev'
  File.write(File.join(config_dir, "#{title}.xcconfig"), <<~CONFIG)
    // Generated from config/build_profiles.json. Edit the source, then regenerate.
    MERP_BUNDLE_ID = #{values.fetch('iosBundleId')}
    APP_DISPLAY_NAME = #{values.fetch('displayName')}
    DEVELOPMENT_TEAM =
    CODE_SIGN_STYLE = #{development ? 'Automatic' : 'Manual'}
    CODE_SIGN_IDENTITY[sdk=iphoneos*] = #{development ? 'Apple Development' : 'Apple Distribution'}
    PROVISIONING_PROFILE_SPECIFIER =
    #include? "#{title}.local.xcconfig"
    PRODUCT_BUNDLE_IDENTIFIER = $(MERP_BUNDLE_ID)
  CONFIG

  types.each do |base, type|
    name = "#{base}-#{profile}"
    clear_identity_settings(clone_configuration(project, base, name, type))
    config = clone_configuration(runner, base, name, type)
    clear_identity_settings(config)
    xcconfig_name = "#{name}.xcconfig"
    File.write(File.join(root, 'ios/Flutter', xcconfig_name), <<~CONFIG)
      #include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.#{name.downcase}.xcconfig"
      #include "Generated.xcconfig"
      #include "../Config/#{title}.xcconfig"
    CONFIG
    path = "Flutter/#{xcconfig_name}"
    ref = flutter_group.files.find { |file| [path, xcconfig_name].include?(file.path) }
    ref ||= flutter_group.new_file(path)
    ref.path = path
    config.base_configuration_reference = ref
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = development ? 'Runner/DebugProfile.entitlements' : 'Runner/Release.entitlements'
    if tests
      test_config = clone_configuration(tests, base, name, type)
      clear_identity_settings(test_config)
      # Tests inherit native identity but keep their own CocoaPods linkage.
      test_path = "Flutter/Tests-#{name}.xcconfig"
      File.write(File.join(root, 'ios', test_path), <<~CONFIG)
        #include? "Pods/Target Support Files/Pods-RunnerTests/Pods-RunnerTests.#{name.downcase}.xcconfig"
        #include "../Config/#{title}.xcconfig"
        PRODUCT_BUNDLE_IDENTIFIER = $(MERP_BUNDLE_ID).RunnerTests
      CONFIG
      test_ref = flutter_group.files.find { |file| file.path == test_path }
      test_ref ||= flutter_group.new_file(test_path)
      test_config.base_configuration_reference = test_ref
    end
  end
end

# Legacy Runner scheme is personal development, never an enterprise fallback.
types.each_key do |base|
  clear_identity_settings(project.build_configurations.find { |config| config.name == base })
  [runner, tests].compact.each do |target|
    config = target.build_configurations.find { |item| item.name == base }
    clear_identity_settings(config)
    dev = target.build_configurations.find { |item| item.name == "#{base}-dev" }
    config.base_configuration_reference = dev.base_configuration_reference
  end
end

runner.shell_script_build_phases.each do |phase|
  if phase.name == 'Run Script'
    phase.shell_script = '/bin/bash "$SRCROOT/../tool/xcode_backend" build'
  elsif phase.name == 'Thin Binary'
    phase.shell_script = '/bin/bash "$SRCROOT/../tool/xcode_backend" embed_and_thin'
  end
end

scheme_dir = File.join(root, 'ios/Runner.xcodeproj/xcshareddata/xcschemes')
source = File.read(File.join(scheme_dir, 'Runner.xcscheme'))
profiles.each_key do |profile|
  document = REXML::Document.new(source)
  document.root.elements.each do |action|
    base = action.attributes['buildConfiguration']
    action.attributes['buildConfiguration'] = "#{base}-#{profile}" if types.key?(base)
  end
  launch = document.root.elements['LaunchAction']
  launch.attributes['buildConfiguration'] = "Debug-#{profile}"
  if profile != 'dev'
    launch.attributes['buildConfiguration'] = "Release-#{profile}"
    launch.attributes['selectedDebuggerIdentifier'] = ''
    launch.attributes['selectedLauncherIdentifier'] = 'Xcode.IDEFoundation.Launcher.PosixSpawn'
  end
  serialized = ''
  REXML::Formatters::Default.new.write(document, serialized)
  File.write(File.join(scheme_dir, "#{profile}.xcscheme"), serialized.rstrip + "\n")
end

project.save
puts 'Configured dev / qas / prd. Commit outputs; daily builds do not run this generator.'
