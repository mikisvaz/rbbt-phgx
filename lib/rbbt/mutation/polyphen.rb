require 'rbbt/util/open'
require 'rbbt/tsv'
require 'nokogiri'
require 'digest/md5'

module Polyphen2

  URL="http://genetics.bwh.harvard.edu/cgi-bin/ggi/ggi2.cgi"
  URL_BASE="http://genetics.bwh.harvard.edu/"

  module Batch
    OPTIONS = {
      "_ggi_project"                      => "PPHWeb2",
      "_ggi_origin"                       => "query",
      "_ggi_batch_file"                   => "",
      "description"                       => "",
      "NOTIFYME"                          => "",
      "uploaded_sequences_1"              => "",
      "description_of_uploaded_sequences" => "",
      "MODELNAME"                         => "HumDiv",
      "UCSCDB"                            => "hg19",
      "SNPFILTER"                         => "1",
      "SNPFUNC"                           => "m",
      "_ggi_target_pipeline"              => "Submit Batch",
    }

    REFRESH_OPTIONS = {
      "sid"                => "",
      "_ggi_project"       => "PPHWeb2",
      "_ggi_origin"        => "manage",
      "_ggi_target_manage" => "Refresh",
    }

    def self.predict(query)
      options = OPTIONS.merge "_ggi_batch" => query

      desc =  Digest::MD5.hexdigest(options.inspect)
      options["description"] = desc

      doc = Nokogiri::HTML(Open.read(Polyphen2::URL, :wget_options => {"--post-data" => "'#{options.collect{|k,v| [k,v] * "="} * "&"}'"}, :nocache => true))

      sid = doc.css('input[name=sid]').attr('value')

      options = REFRESH_OPTIONS.merge "sid" => sid
      finished = false

      view_link = nil
      while not finished do
        doc = Nokogiri::HTML(Open.read(Polyphen2::URL, :wget_options => {"--post-data" => "'#{options.collect{|k,v| [k,v] * "="} * "&"}'"}, :nocache => true))

        result_table =  doc.css('body > table')[1].css('table')[2]

        rows = result_table.css('tr')

        row = rows.select{|row| row.css('td').length == 6}.select{|row| row.css('td').last.content.strip == desc}.first

        cells = row.css('td')
        if cells[2].content =~ /Error/
          view_link = nil
          break
        end

        if cells[1].content =~ /Short/
          view_link =  cells[1].css('a').attr('href')
          break
        end

        sleep 5
      end

      return nil if view_link.nil?

      tsv = TSV.open Open.open(Polyphen2::URL_BASE + view_link, :nocache => true), :double, :merge => true, :fix => Proc.new{|l| l.gsub(/ *\t */, "\t")}
      tsv.fields = tsv.fields.collect{|f| f.strip}
      tsv.key_field = tsv.key_field.strip

      new_tsv = TSV.setup({}, :key_field => "Protein Mutation", :fields => tsv.fields)

      tsv.through do |acc, values|
        values.zip_fields.each do |v|
          pos, wt, mt = v.values_at "o_pos", "o_aa1", "o_aa2"
          key = [acc, [wt,pos,mt] * "" ] * ":"
          new_tsv[key] = v
        end
      end

      return new_tsv
    end

    def self.chunked_predict(query, max = 1000)
      mutations = query.split("\n")
      chunks = mutations.length.to_f / max
      chunks = chunks.ceil

      Log.debug("Polyphen2 ran with #{chunks} chunks of #{ max } mutations") if chunks > 1
      Misc.divide(mutations, chunks).inject(nil) do |acc, list|
        list = list * "\n"
        if acc.nil?
          acc = predict(list)
        else
          acc = TSV.setup(acc.merge(predict(list)))
        end
        acc
      end
    end

  end


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

      sleep 3
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
