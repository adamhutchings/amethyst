#!/usr/bin/env ruby
require 'http'
require 'json'
require 'optparse'
require 'ostruct'
require 'rubygems/package'
require 'zlib'
require 'fileutils'

package_upstream = 'https://jakeroggenbuck.github.io/impulse/'
config_directory = '/home/jake/.config/amethyst/'

def update_list(url, directory)
  package_list = HTTP.get url
  package_list = JSON.parse(package_list)
  File.open(directory + 'list.json', 'w') { |file| file.write(package_list) }
end

class Package
  def initialize(url, name)
    @package_name = name
    @tar_name = name + '.tar.gz'
    @tar_url = url + @tar_name
    @tar_full_path = '/tmp/' + @tar_name
    @stage_dir = '/tmp/' + @package_name
  end
  def download()
    puts 'Downloading from ' + @tar_url
    package = HTTP.get @tar_url
    File.open(@tar_full_path, 'w') { |file| file.write(package) }
    puts 'Downloaded successfully'
  end
  def install()
    tar = File.open(@tar_full_path, 'rb')
    if File.directory?(@stage_dir)
      FileUtils.rm_rf(@stage_dir)
    end
    Dir.mkdir '/tmp/' + @package_name
    tar_extract = Gem::Package.new("").extract_tar_gz(tar, @stage_dir)
    puts 'Extracted successfully'
    Dir.chdir(@stage_dir)
    tar_dir = Dir.glob('*').select { |f| File.path f }
    Dir.chdir(tar_dir[0])
    print 'See diff? [Y/n] '
    get_diff = gets
    if get_diff
      system('less impulse.build')
    end
    print 'Finish install? [Y/n] '
    finish_install = gets
    if finish_install 
      system('sudo sh impulse.build')
    end
    puts 'Installed successfully'
  end
end

def directory_exists(directory)
  unless File.directory?(directory)
    Dir.mkdir directory
  end
end

def list_exists(url, directory)
  unless File.file?(directory + 'list.json')
    update_list(url, directory)
  end
end

directory_exists(config_directory)
list_exists(package_upstream + 'list.json', config_directory)

options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('-U', '--update', 'Update list') { |o| options.update = o }
  opt.on('-S', '--search SEARCH', 'Search cached list') { |o| options.search = o }
  opt.on('-I', '--install INSTALL', 'Install package') { |o| options.install = o }
end.parse!

if options.update
  update_list(package_upstream + 'list.json', config_directory)
end

if options.install
  pack = Package.new(package_upstream, options.install)
  pack.download() 
  pack.install() 
end
