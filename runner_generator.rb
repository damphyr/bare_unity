#returns the source file as an Array of LOCs
#
#Preprocessor directives are considered one line
#and '{' and '}' also end a line along ';'.
def scrub_source_file source_raw
  #remove comments (block and line, in three steps to ensure correct precedence)
  source_raw.gsub!(/\/\/(?:.+\/\*|\*(?:$|[^\/])).*$/, '')  # remove line comments that comment out the start of blocks
  source_raw.gsub!(/\/\*.*?\*\//m, '')                     # remove block comments 
  source_raw.gsub!(/\/\/.*$/, '')                          # remove line comments (all that remain)
  source_raw.split(/(^\s*\#.*$)| (;|\{|\}) /x)
end
#Scan the source file for test functions and return an array with information on the tests
def find_tests source_raw
  lines=scrub_source_file(source_raw)
  tests_and_line_numbers=[]

  lines.each_with_index do |line, index|
    #find tests
    if line =~ /^((?:\s*TEST_CASE\s*\(.*?\)\s*)*)\s*void\s+(test.*?)\s*\(\s*(.*)\s*\)/
      arguments = $1
      name = $2
      call = $3
      tests_and_line_numbers << { :test => name, :call => call, :line_number => 0 }
    end
  end

  #determine line numbers and create tests to run
  source_lines = source_raw.split("\n")
  source_index = 0;
  tests_and_line_numbers.size.times do |i|
    source_lines[source_index..-1].each_with_index do |line, index|
      if (line =~ /#{tests_and_line_numbers[i][:test]}/)
        source_index += index
        tests_and_line_numbers[i][:line_number] = source_index + 1
        break
      end
    end
  end
  return tests_and_line_numbers
end
#Scan the source file for includes and return them in an Array
def find_includes source_raw
  source=scrub_source_file(source_raw).join("\n")
  #parse out includes
  includes = source.scan(/^\s*#include\s+\"\s*(.+\.[hH])\s*\"/).flatten
  includes.map!{|inc| "\"#{inc.strip}\""}  
  brackets_includes = source.scan(/^\s*#include\s+<\s*(.+)\s*>/).flatten
  brackets_includes.each { |inc| includes << '<' + inc +'>' }   
  return includes
end
#Parameters required for template generation
#
# template - the template file
# filename - the name of the test source file
# output - the filename for the runner
# tests - the list of test functions
# includes - the list of header files to include
def generate_runner_source params
  require 'erb'
  template_content=File.read(params['template'])
  template=ERB.new(template_content)
  template.result(binding)
end

def parse_command_line args
  require 'optparse'

  options = {'template'=>File.join(File.dirname(__FILE__),'unity_runner.erb')}
  optp=OptionParser.new do |opts|
    opts.banner = "Usage: #{$0} [options] source_file output_file"
    opts.on("-t", "--template", "Specify the template to use. The default value is unity_runner.erb") do |v|
      if File.exists?(v)
        options['template'] = File.expand_path(v)
      else
        puts "The template #{v} cannot be found"
        exit 1
      end
    end
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit 0
    end
  end
  optp.parse!(args)

  if args.size <2 
    puts optp.help
    exit 1
  else
    options['filenames']=[]
    while args.size!=1
      options['filenames']<<File.expand_path(args.shift)
    end
    options['output']=File.expand_path(args.shift)
  end
  return options
end

def parse_test_source filename
  if File.exists?(filename)
    source_raw=File.read(filename)
    tests=find_tests(source_raw)
    includes=find_includes(source_raw)
    return tests,includes
  else
    puts "Cannot find test source #{filename}"
    exit 1
  end
end

if $0==__FILE__
  cli_options=parse_command_line(ARGV)
  tests=[]
  includes=[]
  cli_options['filenames'].each do |fname|
    tsts,incs = *parse_test_source(fname)
    tests+=tsts
    includes+=incs
  end
  includes.uniq!
  
  params={
    'tests'=>tests,
    'includes'=>includes
  }
  if cli_options['filenames'].size>1
    params['filename']="Various"
  else
    params['filename']=cli_options['filenames'].first
  end
  params.merge!(cli_options)
  runner=generate_runner_source(params)  
  if Dir.exists?(File.dirname(params['output']))
    File.open(params['output'],"wb") do |f|
      f.write(runner)
    end
  else
    put "Cannot create #{params['output']}. The directory needs to exist"
  end
end