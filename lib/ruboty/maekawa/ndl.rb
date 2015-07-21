require 'erb'
require 'open-uri'
require 'rexml/document'

module Ruboty
    module Maekawa
        class Book
            TAG_TITLE           = 'dc:title'
            TAG_SERIES_TITLE    = 'dcndl:seriesTitle'
            TAG_CREATOR         = 'dc:creator'
            TAG_ISSUED          = 'dcterms:issued'
            TAG_MATERIALTYPE    = 'dcndl:materialType'
            TAG_PRICE           = 'dcndl:price'
            TAG_IDENTIFIER_ISBN = 'dc:identifier[@xsi:type = \'dcndl:ISBN\']'
            TAG_IDENTIFIER_URI  = 'dc:identifier[@xsi:type = \'dcterms:URI\']'
            TAG_PUBLISHER       = 'dc:publisher'

            def initialize(element)
                @raw_record = '<?xml version="1.0" encoding="UTF-8"?>' + element.to_s
                @element = element
            end

            def get_record_data_text(tag)
                ary = []
                @element.elements.each("recordData/dcndl_simple:dc/#{tag}") { |e|
                    ary << e.text
                }
                return ary
            end

            def title
                get_record_data_text(TAG_TITLE)[0]
            end

            def isbn
                get_record_data_text(TAG_IDENTIFIER_ISBN)
            end

            def get_all_info_str()
                str = ''
                REXML::XPath.each(@element.elements['recordData/dcndl_simple:dc'], "*") do |e|
                    if e.has_elements? == false
                        attrs = e.attributes
                        str += "#{e.name} #{(attrs.length == 0) ? ('') : (attrs.to_s)}: #{e.text}\n"
                    end
                end
                return str
            end

            def inspect
                "#<NDL::Book \n#{get_all_info_str()}>"
            end

            attr_reader :raw_record, :element
        end

        class Searcher
            CONNECTOR_AND     = 0
            CONNECTOR_OR      = 1
            FIND_ENABLE_LIMIT = 100
            RETRY_LIMIT       = 10
            RETRY_WAIT_TIME   = 5
            API_URL           = 'http://iss.ndl.go.jp/api/sru?operation=searchRetrieve&recordSchema=dcndl_simple&maximumRecords=10&query='

            def self.request(connector_type, params = {})
                connector_str = (connector_type == CONNECTOR_AND) ? (" AND ") : (" OR ")

                query = params.map { |k, v|
                    if v.instance_of?(Array) == true
                        str = Array.new()
                        v.each do |s|
                            str.push("#{k} = \"#{s}\"")
                        end
                        str.join(connector_str)
                    else
                        "#{k} = \"#{v}\""
                    end
                }.join(connector_str).to_s

                # url = "#{API_URL}#{query}"
                escaped_url = "#{API_URL}#{ERB::Util.url_encode(query)}"
                # puts(url)
                # puts(escaped_url)

                response = open(escaped_url).read
                # puts(response)

                doc = REXML::Document.new(response)
                books = Array.new(doc.elements['/searchRetrieveResponse/numberOfRecords'].text.to_i)
                doc.elements.each_with_index('/searchRetrieveResponse/records/record') do |e, i|
                    books[i] = Book.new(e)
                end

                return books
            end
        end
    end
end
