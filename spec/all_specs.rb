files = if ARGV.any? {|x| x.length > 0 }
  ARGV
else
  Dir['spec/**/*_spec.rb']
end

files.each do |f|
  load f
end
