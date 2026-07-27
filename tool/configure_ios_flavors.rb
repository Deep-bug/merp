#!/usr/bin/env ruby

require "xcodeproj"

root = File.expand_path("..", __dir__)
project_path = File.join(root, "ios", "Runner.xcodeproj")
project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == "Runner" }
tests = project.targets.find { |target| target.name == "RunnerTests" }
abort "Runner target not found" unless runner

environments = {
  "qas" => {
    bundle_id: "com.delta.merpdelta.qas",
    test_bundle_id: "com.delta.merpdelta.qas.RunnerTests",
    display_name: "MERP QAS"
  },
  "prd" => {
    bundle_id: "com.delta.merpdelta",
    test_bundle_id: "com.delta.merpdelta.RunnerTests",
    display_name: "MERP"
  }
}.freeze

types = {
  "Debug" => :debug,
  "Profile" => :release,
  "Release" => :release
}.freeze

flutter_group = project.main_group.find_subpath("Flutter", true)

def clone_configuration(owner, source_name, target_name, type)
  existing = owner.build_configurations.find { |config| config.name == target_name }
  return existing if existing

  source = owner.build_configurations.find { |config| config.name == source_name }
  abort "#{source_name} configuration not found" unless source

  target = owner.add_build_configuration(target_name, type)
  target.build_settings.clear
  target.build_settings.update(source.build_settings)
  target.base_configuration_reference = source.base_configuration_reference
  target
end

types.each_key do |base_name|
  runner_config = runner.build_configurations.find do |config|
    config.name == base_name
  end
  runner_config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] =
    environments.fetch("prd")[:bundle_id]
  runner_config.build_settings["APP_DISPLAY_NAME"] =
    environments.fetch("prd")[:display_name]

  next unless tests

  test_config = tests.build_configurations.find do |config|
    config.name == base_name
  end
  test_config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] =
    environments.fetch("prd")[:test_bundle_id]
end

environments.each do |environment, values|
  types.each do |base_name, type|
    configuration_name = "#{base_name}-#{environment}"
    clone_configuration(project, base_name, configuration_name, type)

    runner_config = clone_configuration(
      runner,
      base_name,
      configuration_name,
      type
    )
    runner_config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] = values[:bundle_id]
    runner_config.build_settings["APP_DISPLAY_NAME"] = values[:display_name]

    xcconfig_name = "#{base_name}-#{environment}.xcconfig"
    xcconfig_path = "Flutter/#{xcconfig_name}"
    file_reference = flutter_group.files.find do |file|
      file.path == xcconfig_name || file.path == xcconfig_path
    end
    file_reference ||= flutter_group.new_file(xcconfig_path)
    file_reference.path = xcconfig_path
    runner_config.base_configuration_reference = file_reference

    next unless tests

    test_config = clone_configuration(
      tests,
      base_name,
      configuration_name,
      type
    )
    test_config.build_settings["PRODUCT_BUNDLE_IDENTIFIER"] =
      values[:test_bundle_id]
  end
end

project.save
puts "Configured iOS qas/prd build configurations."
