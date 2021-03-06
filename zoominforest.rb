
require 'rubygems'
require 'active_resource'

module Zoominforest

  class Base < ActiveResource::Base
    self.site = 'http://api.zoominfo.com/PartnerAPI/XmlOutput.aspx?'
  end

  class Person < Base

    def self.find_all_across_pages_since(time)
      find_all_across_pages(:params => { :since => time.to_s(:db).gsub(/[^\d]/, '') })
    end

    def company
      Company.find(company_id) if company_id
    end

    def name
      "#{first_name} #{last_name}".strip
    end
  end

end


class Hash

  # Converts all of the keys to strings, optionally formatting key name
  def rubyify_keys!
    keys.each{|k|
      v = delete(k)
      new_key = k.to_s.underscore
      self[new_key] = v
      v.rubyify_keys! if v.is_a?(Hash)
      v.each{|p| p.rubyify_keys! if p.is_a?(Hash)} if v.is_a?(Array)
    }
    self
  end

end