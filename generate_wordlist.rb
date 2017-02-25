#!/usr/bin/env ruby

require 'rubygems'
require 'trollop'
require 'nokogiri'
require 'fileutils'
require 'yaml'
require 'erubis'

mydir=File.expand_path(File.dirname(__FILE__))
builddir=mydir + "/build"

parser = Trollop::Parser.new do
  text "\nLoops over the given ERB template, once for each word, in frequency-of-usage order, and collects the results in the output file.\n\nSee the README.md for more detail.\n\n"

  opt :template, %q{The name of the template file to use}, :type => String, :short => 't'
  opt :blob, %q{In this mode, pass all the words to the template at once; no looping; the ERB variable is called 'words'}, :short => 'b'
  opt :output, %q{The name of the output file}, :type => String, :short => 'o'

  stop_on_unknown
end

opts = Trollop::with_standard_exception_handling parser do
  raise Trollop::HelpNeeded if ARGV.empty? # show help screen
  parser.parse ARGV
end

blobmode=opts[:blob]
template_fname=opts[:template]
output_fname=opts[:output]

if ! template_fname || ! output_fname
  abort "Need both a template and an output file."
end

freq_raw={}
File.readlines("#{builddir}/freq.raw").each do |line|
  line =~ %r{^\s*([0-9]+)\s+(.*)}
  freq_raw[$2] = $1
  # puts "fr: #{$2} , #{freq_raw[$2]}"
end

# puts YAML.dump(freq_raw)

def jvs_to_hash( word )
  hash={}

  # FIXME: Factor these out somehow?

  # Stuff is in a sub-element and we only want one
  if word.css('definition').length > 0
    hash['definition'] = word.css('definition').map { |x| x.content }.join(' ')
  end
  if word.css('selmaho').length > 0
    hash['selmaho'] = word.css('selmaho').map { |x| x.content }.join(' ')
  end
  if word.css('notes').length > 0
    hash['notes'] = word.css('notes').map { |x| x.content }.join(' ')
  end

  # Stuff is in a sub-element and we only want one
  if word.css('rafsi').length > 0
    hash['rafsi'] = word.css('rafsi').map { |x| x.content }
  end

  # Stuff is in attrs in sub-elements and we want all of them
  if word.css('glossword').length > 0
    hash['glosswords'] = word.css('glossword').map do |x|
      ihash={}
      ihash['word'] = x['word']
      if x['sense']
        ihash['sense'] = x['sense']
      end

      ihash
    end
  end
  if word.css('keyword').length > 0
    hash['keywords'] = word.css('keyword').map do |x|
      ihash={}
      ihash['word'] = x['word']
      if x['sense']
        ihash['sense'] = x['sense']
      end
      if x['place']
        ihash['place'] = x['place']
      end

      ihash
    end
  end

  # Stuff is in an attr on the valsi item
  if word.key?('type')
    hash['type'] = word['type']
  end

  return hash
end

jbovlaste_tree=Nokogiri::XML(open "#{builddir}/jbovlaste.xml")

valid_words=jbovlaste_tree.css('valsi').map { |x| [ x['word'], jvs_to_hash(x) ] }.to_h
# puts YAML.dump(valid_words)

freq_valid=[]
freq_raw.keys.each do |key|
  if valid_words[key]
    ihash = valid_words[key]
    ihash['word'] = key
    ihash['frequency'] = freq_raw[key].to_i
    freq_valid << ihash
  end
end

rank_up=1
rank_down=freq_valid.count
freq_valid.each do |item|
  item['rank_up'] = rank_up
  rank_up += 1
  item['rank_down'] = rank_down
  rank_down -= 1
  item['rafsi_or_selmaho'] = ((defined? rafsi) && rafsi.join(' ')) || ((defined? selmaho) && selmaho) || ''
end
#puts YAML.dump(freq_valid)

output=''

if blobmode
  erb = Erubis::Eruby.new(File.read(template_fname))
  # puts YAML.dump(freq_valid)
  output = erb.result({ 'words' => freq_valid })
else
  erb = Erubis::Eruby.new(File.read(template_fname))
  freq_valid.each do |locals|
    # puts YAML.dump(locals)
    locals['words_all'] = freq_valid
    locals['word_all'] = locals
    output += erb.result(locals)
  end
end

File.open(output_fname, 'w') { |file| file.write(output) }

puts "Done generating wordlist from template #{template_fname} into #{output_fname}."
