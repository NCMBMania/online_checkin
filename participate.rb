require 'rack'
require 'json'
require 'ncmb'
require 'httparty'
require 'csv'

application_key = 'YOUR_APPLICATION_KEY'
client_key = 'YOUR_CLIENT_KEY'

NCMB.initialize application_key: application_key,  client_key: client_key

def call(env)
  req = Rack::Request.new(env)
  query = NCMB::DataStore.new 'Config'
  config = query.limit(1).get.first
  query = NCMB::DataStore.new 'Event'
  event = query.equalTo('key', req.params['key']).get.first
  rows = get_csv(config.sessionid, event)
  
  # Remove old data
  query = NCMB::DataStore.new event.classname
  query.equalTo('key', event.key).get.each do |p|
    p.delete
  end
  
  rows.each do |row|
    p = NCMB::Object.new event.classname
    p.set 'key', event.key
    p.set 'name', row['表示名']
    p.set 'paticipate', row['参加ステータス']
    p.set 'attend', row['出欠ステータス']
    p.set 'no', row['受付番号']
    p.save
  end
  [
    200, {"Content-Type" => "application/json"}, [{attendees: rows.length}.to_json]
  ]
end

def get_csv(sessionid, event)
  puts "#{event.url}participants_csv/"
  id = event.url.match(/https:\/\/.*?\.connpass\.com\/event\/([0-9]+)(\/|$)/)[1]
  response = HTTParty.get "https://connpass.com/event/#{id}/participants_csv/", headers: {
    'Cookie': "sessionid=#{sessionid}",
    'Referer': event.url
  }
  CSV.parse response.body.encode(Encoding::UTF_8, Encoding::SJIS, replace: '?', invalid: :replace), headers: true 
end
