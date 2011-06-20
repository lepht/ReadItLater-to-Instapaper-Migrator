#!/usr/bin/env ruby
require 'rubygems'
require 'progressbar'
require 'uri'
require 'open-uri'
require 'json'
require 'highline/import'

def get_ril_links(ril_user,ril_pass)
	ril_url = "https://readitlaterlist.com/v2/get?username=#{ril_user}&password=#{ril_pass}&apikey=3b2p1o6aA560xh9611g4540C6bd8YaX4&state=unread"
	
	ril_link_objects = JSON.parse(open(ril_url).read)["list"].values
	
	ril_link_urls = ril_link_objects.collect{|i| i["url"]}
end

def add_link_to_instapaper(insta_user, insta_pass, link)
	insta_url = "https://www.instapaper.com/api/add?username=#{insta_user}&url=#{URI.escape(link)}"
	insta_url += "&password=#{insta_pass}" unless insta_pass.empty?

	begin
		return open(insta_url).read
	rescue OpenURI::HTTPError => e
		e.io.status[0]
	end
end

def ask_for_user_creds
	@ril_user = ask("ReadItLater username:")
	@ril_pass = ask("ReadItLater password:") {|q| q.echo = false}

	@insta_user = ask("Instapaper username/email address:")
	@insta_pass = ask("Instapaper password (optional):") {|q| q.echo = false}
end

# Main script execution
ask_for_user_creds

ril_links = get_ril_links(@ril_user,@ril_pass)

success_count = 0
failed_urls = []

progress = ProgressBar.new("Sending links to Instapaper", ril_links.size)

ril_links.each do |link|
	result = add_link_to_instapaper(@insta_user,@insta_pass, link)

	progress.inc

	case result
	when "201"
		success_count += 1
	else
		failed_urls << link
	end
end

progress.finish

#Print results
puts "Migration complete!
		\tLinks transferred to Instapaper: #{success_count}
		\tLinks failed: #{failed_urls.size}"

if failed_urls.size > 0 then
	puts "Failed links were: "
	failed_urls.each {|link| puts link}
end