ENV['TIMEZONE'] = 'Europe/Paris'
ENV['LOGGING'] = 'true'
ENV['OPENID_URI'] = 'http://archiloque-openid.myopenid.com/'
require './tidal'
run Tidal
