class LexisDic < Formula
  desc "AI-powered English Dictionary for macOS"
  homepage "https://github.com/seabornlee/ai-dic-repos"
  version "{{ version }}"
  sha256 "{{ sha256 }}"

  url "https://github.com/seabornlee/ai-dic-repos/releases/download/v{{ version }}/LexisDic-{{ version }}.dmg"
  name "LexisDic"
  license "MIT"

  def install
    # Mount DMG and copy .app to /Applications
    system "hdiutil", "attach", url, "-nobrowse", "-plist", "/dev/stdin"
    # Find mounted volume
    json = `/usr/bin/hdiutil attach -nobrowse -plist "#{url}" 2>/dev/null`.chomp
    require 'json'
    plist = JSON.parse(json)
    dev_entry = plist['system-entities'].find { |e| e['mount-point'] }
    mount_point = dev_entry['mount-point']

    # Copy app
    system "cp", "-R", "#{mount_point}/LexisDic.app", "/Applications/LexisDic.app"

    # Detach
    system "hdiutil", "detach", mount_point, force: true
  end

  test do
    assert_predicate File.exist?("/Applications/LexisDic.app"), "App should be installed"
  end
end
