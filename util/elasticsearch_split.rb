#!/usr/bin/ruby

filename = "#{ARGV[0]}"
max_commands = 10000  # Max number of commands per file
lines_per_command = 2 # Each elasticsearch command is 2 lines

# Set up to iterate (don't change these)
count = 0
iteration = 0
outstring = ""

# Take the lines of the file and add them to temp string
File.open(filename).each_slice(lines_per_command) do |lines|
  count = count+1
  outstring << lines.join

  # once we hit our max, write it out
  if count> max_commands
    outstring << "\n"
    path = filename + ".#{iteration}"
    puts "Writing to #{path}"
    File.open(path, "w").puts outstring
    iteration = iteration+1

    # ... and reset for the next iteration
    count = 0
    outstring = ""
  end

end
