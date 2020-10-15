require "csv"
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting ~~~"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone = phone_number.gsub(/[^0-9]/, '')

  if phone.length == 10
    phone
  elsif phone.length == 11 && phone.start_with?('1')
    phone.sub!('1', '')
  else 
    "this phone number is invalid"
  end
end

def fill_hash(time, hash)
  if hash.has_key? time
    hash[time] += 1
  else
    hash[time] = 1
  end
end

def popular_order (hash)
  hash.sort_by { |key, value| -value }.to_h
end

def thank_you_letters(contents) #for if we want to send letters to attendees
  template_letter = File.read 'form_letter.erb'
  erb_template = ERB.new template_letter
  
  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)
  
    form_letter = erb_template.result(binding)
  
    save_thank_you_letter(id, form_letter)
  end
end

def phone_contact(contents) #for mobile alerts
  contents.each do |row|
    phone_number = row[:homephone]
    
    phone = clean_phone_number(phone_number)

    puts phone
    ## could initiate similar procedure to form letter by creating output for mobile alert
  end
end

def time_targeting(contents) #for targeting online adds to popular hours of the day
  reg_hours_hash = {}
  contents.each do |row|
    reg_date = row[:regdate]

    date = DateTime.strptime(reg_date, '%m/%d/%y %k:%M')

    hour = date.hour
    
    fill_hash(hour, reg_hours_hash)
  end

  hours_by_popularity = popular_order(reg_hours_hash)

  hours_by_popularity
end

def day_of_the_week_targeting(contents) #for specifying day of the week to target
  reg_days_hash = {}
  contents.each do |row|
    reg_date = row[:regdate]

    date = DateTime.strptime(reg_date, '%m/%d/%y %k:%M')

    day = date.strftime("%A")

    fill_hash(day, reg_days_hash)
  end

  days_by_popularity = popular_order(reg_days_hash)

  days_by_popularity
end

def most_popular (time_hash)
  popular = time_hash.first(2).to_h
  popular.each_pair { |time, value| puts "#{time} was popular with #{value} hits"}
end
puts "EventManager Initialized."

contents = CSV.read 'event_attendees.csv', headers: true, header_converters: :symbol
#changed from 'open' to 'read' as program isn't changing data, and this way multiple methods can run without needing to reopen the document

day = day_of_the_week_targeting(contents)
time = time_targeting(contents)

most_popular(day)
most_popular(time)

#output could be tweaked further to comply with a particular format/report as needed