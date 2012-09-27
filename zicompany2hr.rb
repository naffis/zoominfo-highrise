require 'rubygems'
require 'zoominfo.rb'
require 'highrise.rb'

Highrise::Base.site = 'https://XXX:X@domain.highrisehq.com'

z_people = ZoomInfo::Company.new("XXX")
h_people = Highrise::Person.find(:all)
h_people.each do |p|
  begin
  	h_person = Highrise::Person.find(p.id)
    h_email = h_person.contact_data.email_addresses.first.address.to_s
    z_person = z_people.search(:EmailAddress => h_email)

  	if z_person.PeopleSearchRequest && z_person.PeopleSearchRequest.PeopleSearchResults
  	  # update company name
    	z_company = z_person.PeopleSearchRequest.PeopleSearchResults.PersonRecord.CurrentEmployment.Company.CompanyName
  	  h_person.company.name = z_company

  	  # update person's tittle
  	  z_title = z_person.PeopleSearchRequest.PeopleSearchResults.PersonRecord.CurrentEmployment.JobTitle
  	  h_person.title = z_title
  	  puts "Updating #{h_email}"
  		h_person.save!
    else
      puts "Skipping #{h_email}"
  	end
	rescue
	  puts "encountered problem so skipping record"
  end
	  
end