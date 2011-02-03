require 'rbbt/util/open'
require 'nokogiri'
require 'digest/md5'

module Polyphen2
  URL="http://genetics.bwh.harvard.edu/cgi-bin/ggi/ggi2.cgi"
  URL_BASE="http://genetics.bwh.harvard.edu/"

  OPTIONS = {
    "ContAllHits"        => 0,
    "ContThresh"         => 6,
    "Map2Mismatch"       => 0,
    "MaxHitGaps"         => 20,
    "MinHitIde"          => 0.5,
    "MinHitLen"          => 100,
    "SortByIde"          => 1,
    "StructAllHits"      => 0,
    "_ggi_jpover"        => 1,
    "_ggi_origin"        => "query",
    "_ggi_project"       => "PPHWeb2",
    "_ggi_target_submit" => "submit",
    "accid"              => "A6NFZ4",
    "description"        => "",
    "seqpos"             => "34",
    "seqres"             => "",
    "seqvar1"            => "Y",
    "seqvar2"            => "D",
    "Submit"             => "Submit+Query",
  }

  REFRESH_OPTIONS = {
    "sid"                => "",
    "_ggi_project"       => "PPHWeb2",
    "_ggi_origin"        => "manage",
    "_ggi_target_manage" => "Refresh",
  }

  def self.parse_mutation(mutation)
    mutation.match(/([A-Z])(\d+)([A-Z])/i).values_at 1,2,3
  end

  def self.predict(accession, mutation)
    reference, pos, substitution = parse_mutation(mutation)

    options = OPTIONS.merge "accid" => accession, "seqpos" => pos, "seqvar1" => reference, "seqvar2" => substitution

    desc =  Digest::MD5.hexdigest(options.inspect)
    options["description"] = desc

    doc = Nokogiri::HTML(Open.read(URL, :wget_options => {"--post-data" => "'#{options.collect{|k,v| [k,v] * "="} * "&"}'"}, :nocache => true))

    sid = doc.css('input[name=sid]').attr('value')

    options = REFRESH_OPTIONS.merge "sid" => sid
    finished = false

    view_link = nil
    while not finished do
      doc = Nokogiri::HTML(Open.read(URL, :wget_options => {"--post-data" => "'#{options.collect{|k,v| [k,v] * "="} * "&"}'"}, :nocache => true))

      result_table =  doc.css('body > table')[1].css('table')[2]

      rows = result_table.css('tr')
      
      row = rows.select{|row| row.css('td').length == 6}.select{|row| row.css('td').last.content.strip == desc}.first

      cells = row.css('td')
      if cells[2].content =~ /Error/
        view_link = nil
        break
      end

      if cells[1].content =~ /View/
        view_link =  cells[1].css('a').attr('href')
        break
      end

      sleep 1
    end

    return nil if view_link.nil?


    doc = Nokogiri::HTML(Open.read(URL_BASE + view_link, :nocache => true))

    para = doc.css('div#HumDivConf > p').first
    div_prediction = para.css('span').first.content
    div_score      = para.css('b').first.content

    para = doc.css('div#HumVarConf > p').first
    var_prediction = para.css('span').first.content
    var_score      = para.css('b').first.content

    return [div_prediction, div_score, var_prediction, var_score]

  end
end
