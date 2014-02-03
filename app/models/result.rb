require 'open-uri'

class Result < ActiveRecord::Base
  include ActionView::Helpers::DateHelper

  belongs_to :test

  attr_accessible :log, :recording

  def time_ago
    time_ago_in_words(self.updated_at)
  end

  def get
    # call sip:+18558435355@10.51.33.166:5054 18554120839 http://10.51.28.54:1433/vwra.php?result_id=999999 999999
    mcp_ip = self.test.mcp.ip_address
    mcp_port = 1433
    url = "http://#{mcp_ip}:#{mcp_port}/"

    # Read result log from server
    log = open(url + "#{self.id}.log").read.gsub!(/\d{2}-\d{2}-\d{2}.* : /, '')
    self.log = log

    # Determine the session ID from the log
    /Session ID: (.*) \n/.match(log)
    session_id = $1

    if log =~ /Error/
      self.status = 1
      self.test.status += 1
      self.test.save
    else
      self.status = 0
      self.test.status = 0
      self.test.save
    end

    # Parse directory listing for wav file name
    # callrec.006F012E-08004BA1.140201003134.wav
    listing = open(url).read
    /(callrec.#{session_id}.*.wav)"/.match(listing)
    wav = $1

    # Save the wav file locally
    File.open("/Users/pmispagel/Desktop/dev/voicewatch/app/assets/sounds/#{self.id}.wav", "wb") do |saved_wav|
      open("#{url}#{wav}", "rb") do |wav_file|
        saved_wav.write(wav_file.read)
      end
    end

    # update the wav file URL in database
    self.recording = "/assets/#{self.id}.wav"

    # save result information to database
    self.save
  end


end
