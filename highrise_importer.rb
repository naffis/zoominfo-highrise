module HighriseImporter

  require 'rubygems'
  require 'mime'
  require 'gmail'
  require 'tmail'
  require 'net/smtp'
  require 'highrise.rb'

  Highrise::Base.site = 'https://XXX:X@subdomain.highrisehq.com'

  EMAILS_TO_IGNORE = ['support', 'do-not-reply', 'no-reply', 'noreply', 'calendar-notification', 
    'info@', 'webinar', 'email.techwebevents-sf.com', 'mailer-daemon', 'group-digest', 
    'notification+', 'postmaster@', 'system@', 'ePayStub', 'connections@', 'reservations@',
    'updates@linkedin.com', 'onduty@cotweet.com', 'Receipts@linkedin.com']
    
  def self.import_to_highrise(email_account, email_password)
    gmail = Gmail.new("#{email_account}", "#{email_password}") 

    gmail.inbox.emails.each do |email|
      mail = TMail::Mail.parse(gmail.imap.uid_fetch(email.uid, "RFC822")[0].attr["RFC822"])
        
      if process_email?(mail)
        unless mail['from'].to_s.grep(/domain.com/).empty?
          # it's from someone at Domain so check who it's to and create
          # an email record for each person that's not @domain
          email.to.each do |email_address|
            next if email_address.include?("domain.com")
            puts "adding email from #{email.from.to_s} to #{email_address}"
            person = find_or_create_highrise_person(email_address)
            create_email_record(person.id, mail.subject, mail.body.to_s, mail.date.to_s)
          end
          email.mark(:read)
        else              
          person = find_or_create_highrise_person(email.from.to_s)          
          puts "adding email from #{mail['from'].to_s} #{mail.subject}"
          create_email_record(person.id, mail.subject, mail.body.to_s, mail.date.to_s)
          email.mark(:read)
        end          
      end  
    end
  end

  def self.process_email?(mail)
    if EMAILS_TO_IGNORE.collect { |str| mail['from'].to_s.match(str) }.compact.empty?
      return true
    else
      puts "skipping mail from #{mail['from'].to_s}"
      email.mark(:read)
      return false
    end  
  end

  def self.find_or_create_highrise_person(email_address)
    person = find_highrise_person(email_address)
    person = create_highrise_person(email_address) unless person
    person
  end

  def self.find_highrise_person(email_address)
    person = Highrise::Person.find(:all, :from => "/people/search.xml?criteria[email]=#{email_address}").first
    puts "find_highrise_person: found #{email_address}"
    person    
  end

  def self.create_highrise_person(email_address)
    person = Highrise::Person.create('first-name' => email_address.partition('@').first, 
                            'contact_data'=> { 
                              'email_addresses' => [ { 
                                'address' => email_address,
                                'location' => 'Work'
                              } ]
                            })
    puts "create_highrise_person: created #{email_address}"
    person
  end

  def self.create_email_record(person_id, subject, body, created_at)
    Highrise::Email.create( 'title' => subject, 
                            'subject-id' => person_id, 
                            'subject-type' => 'Party',
                            'body' => body,
                            'created_at' => created_at )  
    puts "created email record for #{subject}"
  end
  
end