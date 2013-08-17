#!/usr/bin/ruby

require 'json'
require 'pp'

## Methods
def get_names(filename)
  File.readlines(filename).map { |name| (name.slice(0,1).capitalize + name.slice(1..-1)).chomp }.uniq
end

def remove_ambiguous_names(names)
  uniq_boy_names = names[:to_review][:boy] - names[:to_review][:girl]
  uniq_girl_names = names[:to_review][:girl] - names[:to_review][:boy]

  { :to_review => { :boy => uniq_boy_names, :girl => uniq_girl_names } }
end

def review_names(names)
  reviewed_names = {
    :to_review => [],
    :selected => []
  }

  choice = ""
  while true
    puts "\nPlease enter the number of the names you're interested in."
    name_subset = names.shift(10)
    name_subset.each_with_index { |name, i| puts "[#{i}] #{name}" }
    puts "[x] Exit to main menu"
    choice = $stdin.gets.downcase.strip
    break if choice == 'x'
    next if choice == ""
    choices = choice.scan(/\d/).map(&:to_i).uniq
    chosen_names = choices.map { |i| name_subset[i] }
    puts "Adding #{chosen_names.join(", ")}" 
    reviewed_names[:selected] += chosen_names
	end

  reviewed_names[:to_review] = names.sort!

  puts "You've selected the following names: #{reviewed_names[:selected].join(", ")}, with #{reviewed_names[:to_review].size} names left to review."
  reviewed_names
end

def present_main_menu(names)
  choice = ""

  while choice != "q"
    puts "Please make a selection from the menu below and press Enter."
    puts <<-menu 
    [b] - Choose boy names (#{names[:to_review][:boy].size} names to review)
    [g] - Choose girl names (#{names[:to_review][:girl].size} names to review)
    [r] - Resume previous session
    [q] - Save and quit
    menu
    choice = $stdin.gets.downcase.strip!
    case choice
    when "b"
      reviewed_names = review_names(names[:to_review][:boy])
      names[:selected][:boy] = (reviewed_names[:selected] | names[:selected][:boy]).sort!
      names[:to_review][:boy] = reviewed_names[:to_review]
      puts "Narrowed the list down to #{names[:selected][:boy].size} names."
      if names[:to_review][:boy].size == 0
        puts "Moving selected names to review list..."
        names[:to_review][:boy] = names[:selected][:boy].clone
        names[:selected][:boy].clear
      end
    when "g"
      reviewed_names = review_names(names[:to_review][:girl])
      names[:selected][:girl] = reviewed_names[:selected] | names[:selected][:girl]
      names[:to_review][:girl] = reviewed_names[:to_review]
      puts "Narrowed the list down to #{names[:selected][:girl].size} names."
      if names[:to_review][:girl].size == 0
        puts "Moving selected names to review list..."
        names[:to_review][:girl] = names[:selected][:girl].clone
        names[:selected][:girl].clear
      end
    when "r"
      filename = "./baby_names.resume"
      puts "Please enter the name of the file you'd like to resume from. (default #{filename.inspect})"
      entered_filename = $stdin.gets.strip
      filename =  entered_filename unless entered_filename == ""
      if File.exists? filename 
        begin
         print "Reading in #{filename}..."
         json = File.read(filename)
         names = JSON.parse(json, {:symbolize_names => true})
         puts "Success!"
         puts "Overall selected names: #{names[:selected][:boy].join(", ")}"
         puts "Names to review:"
         puts "\t Boy: #{names[:to_review][:boy].sort!.size}" 
         puts "\t Girl: #{names[:to_review][:girl].sort!.size}" 
        rescue => e
          puts "Error reading file: #{e}"
        end
      else
        puts "The file doesn't exist."
      end
    when "q"
      save_filename = "./baby_names.resume"
      puts "Choose filename for resume file. (defaults to #{save_filename.inspect})"
      input_filename = $stdin.gets.strip.downcase
      save_filename = input_filename unless input_filename == ""
      puts "Saving state to #{save_filename}..."
      File.open(save_filename, "w") { |f| f.write names.to_json }
      break
    else
      puts "Choice not recognized, please try again."
    end
  end

end

puts "Welcome to the Baby Name Chooser 3000!"

names = {
  :to_review => {
    :boy => [],
    :girl => []
  },
  :selected => {
    :boy => [],
    :girl => []
  }
}

puts "Loading lists of names..."
names[:to_review].keys.each do |gender|
  puts "\tfor #{gender.to_s}s..."
  Dir.glob("./#{gender.to_s}/*.names").each do |file|
    names_from_file = get_names(file)
    names[:to_review][gender] = (names[:to_review][gender] | names_from_file).sort
  end
end

names = names.merge(remove_ambiguous_names(names))

present_main_menu(names)
