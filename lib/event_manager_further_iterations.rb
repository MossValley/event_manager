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

puts "EventManager Initialized."

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

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



