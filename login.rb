require 'rack'
require 'json'
require 'ncmb'
require 'nokogiri'
require 'httparty'

application_key = 'YOUR_APPLICATION_KEY'
client_key = 'YOUR_CLIENT_KEY'

NCMB.initialize application_key: application_key,  client_key: client_key

def call(env)
  req = Rack::Request.new(env)
  query = NCMB::DataStore.new 'Config'
  config = query.limit(1).get.first
  # Login to connpass
  cookie = login_to_connpass(config)
  results = {}
  if cookie['sessionid']
    config.sessionid = cookie['sessionid']
    config.save
    results['login'] = 'success'
  else
    results['login'] = 'failed'
  end
  [
    200, {"Content-Type" => "application/json"}, [results.to_json]
  ]
end

def login_to_connpass(config)
  response = HTTParty.get 'https://connpass.com/login/'
  cookies = parse_set_cookie response.headers['set-cookie']
  login_doc = Nokogiri::HTML response.body
  csrfmiddlewaretoken = login_doc.css('[name=csrfmiddlewaretoken]').first.attribute('value')
  response2 = HTTParty.post 'https://connpass.com/login/', body: {
    csrfmiddlewaretoken: csrfmiddlewaretoken,
    username: config.username,
    password: config.password
  }, headers: {
    'Cookie': cookies.map{|k, v| "#{k}=#{v}"}.join("; "),
    'Content-Type': 'application/x-www-form-urlencoded',
    'Referer': 'https://connpass.com/login/'
  }, follow_redirects: false
  parse_set_cookie response2.headers['set-cookie']
end


def parse_set_cookie(all_cookies_string)
  cookies = Hash.new
  all_cookies_string.split(',').each {|single_cookie_string|
    cookie_part_string  = single_cookie_string.strip.split(';')[0]
    cookie_part         = cookie_part_string.strip.split('=')
    key                 = cookie_part[0]
    value               = cookie_part[1]
    cookies[key] = value
  }
  cookies.reject! {|key, value| value.nil? }
end