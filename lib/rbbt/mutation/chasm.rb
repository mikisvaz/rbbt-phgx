require 'rbbt/util/open'
require 'rbbt/tsv'
require 'nokogiri'
require 'digest/md5'
require 'net/http/post/multipart'

module CHASM

  class NotDone < StandardError; end

  URL="http://www.cravat.us/ClassifierSelect1"
  ASTERISK = "*"[0]

  # Hash of samples pointing to mutations specified in Ensembl Transcript ID
  def self.predict(mutations_by_sample, options = {})
    options = Misc.add_defaults options, :chosendb => "CHASM", :emailbox => 'dev@null.org', :analysistype => 'driver', :inputfile => nil
    mutationbox = []
    i = 1
    mutations_by_sample.each do |sample,mutations|
      mutations.each do |mutation|
        mutationbox << [i, sample].concat(mutation.split(":"))
      end
      i += 1
    end

    options[:mutationbox] = mutationbox.collect{|line| line * "\t"} * "\n"
    post_data = options.collect{|k,v| [k,v] * "="} * "&"

    Log.debug "Querying CHASM for: #{mutationbox.length} mutations in #{mutations_by_sample.length} samples"

    tries = 0
    nocache = false
    begin
      doc = nil
      TmpFile.with_file(post_data) do |post_file|
        Log.medium "Updating cache:" if nocache == :update

        url = URI.parse(URL)
        req = Net::HTTP::Post::Multipart.new url.path, options
        res = Net::HTTP.start(url.host, url.port) do |http|
          http.request(req)
        end
        job_id = JSON.parse(res.body)["jobId"]
        puts job_id
      end
    end
  end

  def self.chunked_predict(mutations, max = 1000)
    flattened_mutations = mutations.collect{|g,list| list = [list] unless Array === list; list.collect{|m| [g,m] } }.flatten(1)
    chunks = flattened_mutations.length.to_f / max
    chunks = chunks.ceil

    Log.debug("Mutation Assessor ran with #{chunks} chunks of #{ max } mutations") if chunks > 1
    num = 1
    Misc.divide(flattened_mutations, chunks).inject(nil) do |acc, list|
      Log.debug("Mutation Assessor ran with #{chunks} chunks: chunk #{num}") if chunks > 1
      unflattened_mutations = {}
      list.each{|g,m| next if g.nil?; unflattened_mutations[g] ||= []; unflattened_mutations[g] << m}
      if acc.nil?
        acc = predict(unflattened_mutations)
      else
        acc = TSV.setup(acc.merge(predict(unflattened_mutations)))
      end
      num += 1
      acc
    end
  end
end


__END__

name="mutationbox" 1 NP_001135977 R641W 1 
name="inputfile" 
name="analysistype" driver
name="chosendb" CHASM 
name="cancertype" Breast 
name="emailbox" mikisvaz@gmail.com
