#!/usr/bin/ruby

require 'json'

# Get bulk list of names, separate by gender
# Remove names of facebook friends
# Remove shared boy/girl names

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
    choices = choice.scan(/\d/).map(&:to_i).uniq
    chosen_names = choices.map { |i| name_subset[i] }
    puts "Adding #{chosen_names.join(", ")}"
    reviewed_names[:selected] += chosen_names
	end

  reviewed_names[:to_review] = names

  puts "You've selected the following names: #{reviewed_names[:selected].join(", ")}, with #{reviewed_names[:to_review].size} names left to review."
  reviewed_names
end

def present_main_menu(names)
  choice = ""

  while choice != "q"
    puts "Please make a selection from the menu below and press Enter."
    puts %q{
    [b] - Choose boy names
    [g] - Choose girl names
    [r] - Resume previous session
    [q] - Save and quit
    }
    choice = $stdin.gets.downcase.strip!
    case choice
    when "b"
      reviewed_names = review_names(names[:to_review][:boy])
      selected_names = reviewed_names[:selected] & names[:selected][:boy]
      puts "You've added the following names: #{selected_names.join(",")}"
      names[:selected][:boy] = selected_names
      names[:to_review][:boy] = reviewed_names[:to_review]
    when "g"
      
    when "r"
      names = JSON.parse(File.read("./baby_names.resume"))
    when "q"
      break
    else
      puts "Choice not recognized, please try again."
    end
  end

  File.open("./baby_names.resume", "w") { |f| f.write names.to_json }
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
    names[:to_review][gender] = names[:to_review][gender] | names_from_file
  end
end

names = names.merge(remove_ambiguous_names(names))
names[:to_review].each { |gender, names| puts "Got #{names.size} #{gender.to_s} names." }

present_main_menu(names)
