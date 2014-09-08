#!/usr/bin/env ruby

require 'rubygems'
require 'progressbar'
require 'uri'
require 'open-uri'
require 'json'
require 'highline/import'

def convert_url(link)
  url = link;

  # habrahabr.ru
  if(link.match(/:\/\/habrahabr\.ru/))
    url = link.sub("habrahabr.ru", "m.habrahabr.ru").sub(/\.ru\/.+\/(\d+)/, '.ru/post/\1').sub(/#habracut$/, "");
  end

  # livejournal.ru
  if(link.match(/:\/\/.+\.livejournal\.(com|ru)/) && !link.match(/:\/\/m\.livejournal\.(com|ru)/))
    # blog post
    url = link.sub(/:\/\/(.+).livejournal.com\/(\d+).html/, ':#m.livejournal.com/read/user/\1/\2');
    # theme
    url = url.sub(/www.livejournal.ru\/themes\/id\/(\d+)$/, 'm.livejournal.com/themes/all/\1');
  end

  # www.trud.ru
  if(link.match(/:\/\/www.trud.ru/))
    url = link.sub(/\.html$/, "/print")
  end

  # lenta.ru
  if(link.match(/:\/\/lenta.ru/))
    url = link.sub(/\/?$/, "/_Printed.htm");
  end

  # roem.ru
  if(link.match(/:\/\/roem.ru/) && !link.match("reom.ru/pda"))
    url = link.sub(/\/(\?.*)?$/, "").sub(/\/\d{4}\/\d{2}\/\d{2}\/\D+(\d+)$/, '/pda/?element_id=\1');
  end

  # www.guardian.co.uk
  if(link.match(/guardian.co.uk\//) && !link.match("print"))
    url = link.sub(/$/, "/print");
  end
  if(link.match("news.rambler.ru") && !link.match("m.rambler.ru"))
    url = link.sub(/news.rambler.ru\/(\d+)\/.+/, 'm.rambler.ru/news/head/\1/');
  end

  # TODO: http:#www.vedomosti.ru/politics/news/1502544/kurator_pokoleniya
  # TODO: ttp:#www.vedomosti.ru/politics/print/2012/02/14/1502544

  return url;
end

def get_ril_links(ril_user, ril_pass)
  url = "https://readitlaterlist.com/v2/get?state=0&username=#{ril_user}&password=#{ril_pass}&apikey=3b2p1o6aA560xh9611g4540C6bd8YaX4&state=unread"
  JSON.parse(open(url).read)["list"].values.collect { |i| [i["url"], i["title"], i["time_updated"]] }
end

def add_link_to_instapaper(insta_user, insta_pass, link, title=nil)
  url = "https://www.instapaper.com/api/add?username=#{insta_user}&url=#{URI.escape(convert_url(link))}"
  url += "&title=#{URI.escape(title)}" unless title.nil?
  url += "&password=#{insta_pass}" unless insta_pass.empty?

  begin
    return open(url).read
  rescue OpenURI::HTTPError => e
    e.io.status[0]
  end
end

def ask_for_credentials
  @ril_user = ask("ReadItLater username:")
  @ril_pass = ask("ReadItLater password:") { |q| q.echo = false }

  @insta_user = ask("Instapaper username/email address:")
  @insta_pass = ask("Instapaper password (optional):") { |q| q.echo = false }
end

# Main script execution
ask_for_credentials

ril_links = get_ril_links(@ril_user, @ril_pass).sort_by{ |e| e[2] }

success_count = 0
failed_urls = []

progress = ProgressBar.new("Sending links to Instapaper", ril_links.size)

ril_links.each do |entry|
  link = entry[0]
  title = entry[1]
  result = add_link_to_instapaper(@insta_user, @insta_pass, link, title)
  progress.inc

  case result
  when "201"
    success_count += 1
  else
    failed_urls << link
  end
end

progress.finish

puts ["Migration complete!", "Links transferred to Instapaper: #{success_count}", "Links failed: #{failed_urls.size}"].join("\t")

if failed_urls.any?
  puts "Failed links were: "
  failed_urls.each { |link| puts link }
end
