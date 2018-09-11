#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require_relative 'lib/remove_notes'
require_relative 'lib/unspan_all_tables'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links
  decorator RemoveNotes

  field :members do
    member_items.map { |li| fragment(li => MemberItem).to_h }
  end

  private

  def member_items
    noko.xpath('//table[.//th[contains(.,"Lista e Deputeteve")]]//following-sibling::table[1]//ul//li')
  end
end

class MemberItem < Scraped::HTML
  field :name do
    noko.xpath('.//text()').map(&:text).map(&:tidy).first
  end

  field :id do
    noko.xpath('.//a/@wikidata').text
  end

  field :party do
    last_party.text.tidy
  end

  field :party_id do
    last_party.xpath('a/@wikidata').text
  end

  field :area do
    noko.xpath('preceding::b').last.text.gsub('Qarku ', '').tidy
  end

  private

  def last_party
    noko.xpath('preceding::p').reject { |p| p.text.empty? }.last
  end
end

url = 'https://sq.wikipedia.org/wiki/Kuvendi_i_Shqip%C3%ABris%C3%AB'
Scraped::Scraper.new(url => MembersPage).store(:members, index: %i[name area party])
