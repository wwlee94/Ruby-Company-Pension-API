require 'nokogiri'

builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
    xml.body {
      xml.items {
        xml.item {
          xml.dataCrtYm '201910'
          xml.seq '22102808'
          xml.wkplNm '(주)그렙'
        }
        xml.item {
          xml.dataCrtYm '201909'
          xml.seq '21600669'
          xml.wkplNm '(주)그렙'
        }
        xml.item {
          xml.dataCrtYm '201907'
          xml.seq '20664480'
          xml.wkplNm '(주)그렙'
        }
      }
    }
  end.to_xml
  puts builder