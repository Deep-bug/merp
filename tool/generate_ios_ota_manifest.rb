#!/usr/bin/env ruby

require "cgi"
require "fileutils"
require "open3"
require "tmpdir"

ipa_path, manifest_path, ipa_url, title = ARGV

unless ipa_path && manifest_path && ipa_url && title
  abort "Usage: generate_ios_ota_manifest.rb <ipa> <manifest.plist> <ipa-url> <title>"
end

unless File.file?(ipa_path)
  abort "IPA does not exist: #{ipa_path}"
end

def plist_value(plist_path, key)
  stdout, stderr, status = Open3.capture3(
    "/usr/libexec/PlistBuddy",
    "-c",
    "Print #{key}",
    plist_path
  )
  abort "Failed to read #{key} from #{plist_path}: #{stderr}" unless status.success?
  stdout.strip
end

Dir.mktmpdir("merp-ios-ota") do |tmp_dir|
  stdout, stderr, status = Open3.capture3("unzip", "-q", ipa_path, "-d", tmp_dir)
  abort "Failed to unzip IPA: #{stderr}#{stdout}" unless status.success?

  app_dir = Dir.glob(File.join(tmp_dir, "Payload", "*.app")).first
  abort "IPA does not contain Payload/*.app" unless app_dir

  info_plist = File.join(app_dir, "Info.plist")
  bundle_id = plist_value(info_plist, "CFBundleIdentifier")
  bundle_version = plist_value(info_plist, "CFBundleShortVersionString")

  FileUtils.mkdir_p(File.dirname(manifest_path))
  File.write(
    manifest_path,
    <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>items</key>
        <array>
          <dict>
            <key>assets</key>
            <array>
              <dict>
                <key>kind</key>
                <string>software-package</string>
                <key>url</key>
                <string>#{CGI.escapeHTML(ipa_url)}</string>
              </dict>
            </array>
            <key>metadata</key>
            <dict>
              <key>bundle-identifier</key>
              <string>#{CGI.escapeHTML(bundle_id)}</string>
              <key>bundle-version</key>
              <string>#{CGI.escapeHTML(bundle_version)}</string>
              <key>kind</key>
              <string>software</string>
              <key>title</key>
              <string>#{CGI.escapeHTML(title)}</string>
            </dict>
          </dict>
        </array>
      </dict>
      </plist>
    PLIST
  )
end
