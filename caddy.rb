#!/usr/bin/env ruby

require 'fileutils'
require 'open-uri'
require 'uri'
require 'pstore'
require 'optparse'
require 'net/http'

Net::HTTP.version_1_2

$: << SRC_DIR = File.expand_path(File.dirname(__FILE__))

GOLF_DIR = File.join(ENV['HOME'], '.golf')
AG_DIR = File.join(GOLF_DIR, 'ag')
CODE_DIR = File.join(GOLF_DIR, 'code')
TEST_DIR = File.join(GOLF_DIR, 'test')

FileUtils.mkdir_p(GOLF_DIR)
FileUtils.mkdir_p(AG_DIR)
FileUtils.mkdir_p(CODE_DIR)

configfile = File.join(GOLF_DIR, 'config.rb')
if !File.exist?(configfile)
  puts "Installing config.rb into #{configfile}"
  FileUtils.cp(File.join(SRC_DIR, 'config.rb'), configfile)
end
require configfile

require 'db'
require 'cases'
require 'install_apt'
require 'execute'
require 'squeeze'
require 'net/http/multipart'

def help
  print %Q(Usage: caddy [OPTION]... FILE|update|install_apt [URL]

Options:
 -l : local test only
 -r : remote test only
 -s1: skip pre-squeezing test
 -s2: skip post-squeezing test
 -i : run all process ignoring errors
 -n : skip squeezing
 -s : suppress stderr
 -c : copy squeezed file into current directory
 -dn: change diff style to 'none'
 -dd: change diff style to 'diff'
 -da: change diff style to 'all'
 -u [suffix]: add user suffix (e.g. sym)
)
  exit 0
end

if !File.exist?(golf_db_file)
  puts "Initializing DB in #{GOLF_DIR}"
  print 'Enter your user name: '
  user = STDIN.gets
  golf_db = get_golf_db
  golf_db.transaction do
    golf_db['file2problem'] = {}
    golf_db['user'] = user
  end
end

do_local1 = true
do_local2 = true
do_remote = true
do_squeeze = true
user_suffix = nil
ignore_errors = false

argn = 0
while opt = ARGV[argn]
  if opt =~ /^-/
    case opt
    when '-l'
      do_remote = false
    when '-r'
      do_local1 = do_local2 = false
    when '-s1'
      do_local1 = false
    when '-s2'
      do_local2 = false
    when '-n'
      do_squeeze = false
    when '-i'
      ignore_errors = true
    when '-s'
      $suppress_stderr = true
    when '-c'
      $copy_squeezed = true
    when '-dn'
      $diff_style = :none
    when '-dd'
      $diff_style = :diff
    when '-da'
      $diff_style = :all
    when '-u'
      user_suffix = ARGV[argn+1]
      ARGV.delete_at(argn)
    else
      puts "Unknown option: #{opt}"
      help
    end
    ARGV.delete_at(argn)
  else
    argn += 1
  end
end

case ARGV[0]
when 'update'
  update_ag
when 'install_apt'
  install_apt
when nil
  help
else
  filename = ARGV[0]
  problem = ARGV[1]

  if problem && problem !~ /^http:/
    puts "Problem must be a URL"
    exit(1)
  end

  if !File.exist?(filename)
    raise "#{filename}: file not found"
  end
  ext = File.extname(filename)
  base = File.basename(filename, ext)
  if ext == '.z8' || ext == '.zasm'
    if !system("z80asm #{filename} -o #{base}.z8b")
      puts "Couldn't compile #{filename}"
      exit(1)
    end
    filename = "#{base}.z8b"
    ext = '.z8b'
  elsif ext == '.asm'
    if !system("nasm #{filename} -o #{base}.out")
      puts "Couldn't compile #{filename}"
      exit(1)
    end
    filename = "#{base}.out"
    ext = '.out'
  end

  tests = get_testcases(base, problem)
  if !tests
    raise "Couldn't obtain test for #{filename}"
  end

  type, testcases = tests
  if do_local1
    if !execute(type, filename, testcases)
      puts 'FAILED'
      if !ignore_errors
        exit(1)
      end
    end
  end

  if do_squeeze
    squeezed, code_size = squeeze(filename)
    if do_local2
      if !execute(type, squeezed, testcases)
        puts 'FAILED'
        if !ignore_errors
          exit(1)
        end
      end
    end

    if $copy_squeezed
      FileUtils.cp(squeezed, 'out' + ext)
    end
  else
    squeezed = filename
    code_size = File.size(filename)
  end

  problem = file2problem(base, false)
  if do_remote && problem =~ /^http:\/\/golf.shinh.org\/p.rb\?/
    pn = $'
    user = get_user
    if user_suffix
      user = "#{user}(#{user_suffix})"
    end

    if $submit_confirm
      print "Submit this #{code_size}B code as #{user} (Y/n) ? : "
      yn = STDIN.gets
      if yn !~ /^$/ && yn !~ /^[yY]$/
        exit 0
      end
    end

    print 'Submitting... '
    data = {
      'problem' => pn,
      'user' => user,
      'reveal' => $open_code_statistics ? '1' : '',
    }
    Net::HTTP.start('golf.shinh.org', 80) do |http|
      req = Net::HTTP::Post.new('/submit.rb')
      FileUtils.cp(squeezed, tmpfile = File.join('/tmp', base+ext))
      req.set_multipart_form_data({'file' => tmpfile}, data)
      File.unlink(tmpfile)
      res = http.request(req)
      if res.class.superclass != Net::HTTPSuccess
        puts "Failed to connect the golf server"
        exit 1
      end

      res = res.read_body
      if res =~ /Success[^<]*/
        puts $&
      else
        puts 'FAILED'
        puts
        puts res.sub(/.*<body>/m, '').gsub(/<.*?>/, '').sub('return top', '')
      end
    end
  end
end