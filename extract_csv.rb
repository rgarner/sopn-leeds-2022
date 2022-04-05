require 'rubygems'
require 'bundler/setup'

require 'nokogiri'
require 'csv'

class String
  def squish
    gsub!(/\A[[:space:]]+/, '')
    gsub!(/[[:space:]]+\z/, '')
    gsub!(/[[:space:]]+/, ' ')
    self
  end
end

WARD_NAME_ID_MAPPINGS = {
  'Gipton & Harehills' => 'local.leeds.gipton-harehills.2022-05-05',
  'Garforth & Swillington' => 'local.leeds.garforth-swillington.2022-05-05',
  'Farnley & Wortley' => 'local.leeds.farnley-wortley.2022-05-05',
  'Cross Gates & Whinmoor' => 'local.leeds.cross-gates-whinmoor.2022-05-05',
  'Chapel Allerton' => 'local.leeds.chapel-allerton.2022-05-05',
  'Killingbeck & Seacroft' => 'local.leeds.killingbeck-seacroft.2022-05-05',
  'Calverley & Farsley' => 'local.leeds.calverley-farsley.2022-05-05',
  'Harewood' => 'local.leeds.harewood.2022-05-05',
  'Headingley & Hyde Park' => 'local.leeds.headingley-hyde-park.2022-05-05',
  'Horsforth' => 'local.leeds.horsforth.2022-05-05',
  'Adel and Wharfedale' => 'local.leeds.adel-wharfedale.2022-05-05',
  'Alwoodley' => 'local.leeds.alwoodley.2022-05-05',
  'Ardsley & Robin Hood' => 'local.leeds.ardsley-robin-hood.2022-05-05',
  'Middleton Park' => 'local.leeds.middleton-park.2022-05-05',
  'Moortown' => 'local.leeds.moortown.2022-05-05',
  'Morley North' => 'local.leeds.morley-north.2022-05-05',
  'Morley South' => 'local.leeds.morley-south.2022-05-05',
  'Otley & Yeadon' => 'local.leeds.otley-yeadon.2022-05-05',
  'Pudsey' => 'local.leeds.pudsey.2022-05-05',
  'Rothwell' => 'local.leeds.rothwell.2022-05-05',
  'Roundhay' => 'local.leeds.roundhay.2022-05-05',
  'Temple Newsam' => 'local.leeds.temple-newsam.2022-05-05',
  'Weetwood' => 'local.leeds.weetwood.2022-05-05',
  'Wetherby' => 'local.leeds.wetherby.2022-05-05',
  'Little London & Woodhouse' => 'local.leeds.little-london-woodhouse.2022-05-05',
  'Kirkstall' => 'local.leeds.kirkstall.2022-05-05',
  'Guiseley & Rawdon' => 'local.leeds.guiseley-rawdon.2022-05-05',
  'Kippax & Methley' => 'local.leeds.kippax-methley.2022-05-05',
  'Armley' => 'local.leeds.armley.2022-05-05',
  'Beeston & Holbeck' => 'local.leeds.beeston-holbeck.2022-05-05',
  'Bramley & Stanningley' => 'local.leeds.bramley-stanningley.2022-05-05',
  'Burmantofts & Richmond Hill' => 'local.leeds.burmantofts-richmond-hill.2022-05-05',
  'Hunslet & Riverside' => 'local.leeds.hunslet-riverside.2022-05-05'
}.freeze

class ExtractCsv
  HEADER = ['ballot_paper_id','ward name','Ballot Paper Name','Address','Description']

  def html
    @html ||= Nokogiri::HTML(File.read('leeds-city-council-elections.html'))
  end

  def heading_nodes
    @heading_nodes ||= html.css('h3.accordion__heading').reject { |n| n.text =~ /(Notice of Leeds|May 2022)/ }
  end

  def extract_csv
    CSV.new(File.open('leeds.csv', 'w+')).tap do |csv|
      csv << HEADER
      heading_nodes.each do |node|
        WardTable.new(node).candidate_rows.each { |row| csv << row }
      end
    end
  end

  class WardTable
    def initialize(heading_node)
      @heading_node = heading_node
    end

    def table_rows
      @heading_node.next_sibling.xpath(".//table/tbody/tr")
    end

    def ward_name
      @heading_node.text.strip.sub(' Ward', '')
    end

    def ballot_paper_id
      WARD_NAME_ID_MAPPINGS[ward_name]
    end

    def candidate_rows
      table_rows.map do |row|
        [ballot_paper_id, ward_name] + row.xpath('td').take(3).map { |td| td.text.squish }
      end
    end
  end
end

ExtractCsv.new.extract_csv
