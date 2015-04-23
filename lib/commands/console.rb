if ARGV.first == '--help' || ARGV.first == '-h'
  puts File.open(File.join(PAK_PATH, 'commands/USAGE-CONSOLE')).read
else
  $:.unshift(Dir.pwd)

  require 'pakyow'
  Pakyow::App.stage(ARGV.first)

  def reload
    puts "Reloading..."
    Pakyow.app.reload
  end

  require 'irb'
  ARGV.clear
  IRB.start
end
