require 'rbbt/util/open'
require 'nokogiri'
module SIFT
  URL_AMINOACID="http://sift.jcvi.org/sift-bin/SIFT_pid_subst_all_submit.pl"
  URL_GENOMIC="http://sift.jcvi.org/sift-bin/SIFT_feed_to_chr_coords.pl"

  def self.predict_aminoacid_mutation(accession, mutations)
    doc = Nokogiri::HTML(Open.read(URL_AMINOACID, :wget_options => {"--post-data" => "'GI=#{[accession, mutations].flatten * ","}&sequences_to_select=BEST&seq_identity_filter=90'"}, :nocache => false))

    rows = []
    doc.css('tr').each do |row|
      rows << row.css('td').collect{|cell| cell.content}
    end

    rows.shift

    if Array === mutations
      rows
    else
      rows.first
    end
  end

  def self.predict_aminoacid_mutation_batch(mutations)
    data = case
             when String === mutations
               mutations
             when Array === mutations
               mutations.collect{|p| p * ", "} * "\n" if Array === mutations
             end

    doc = Nokogiri::HTML(Open.read(URL_AMINOACID, :wget_options => {"--post-data" => "'GI=#{data}&sequences_to_select=BEST&seq_identity_filter=90'"}, :nocache => false))

    rows = []
    doc.css('tr').each do |row|
      rows << row.css('td').collect{|cell| cell.content}
    end

    rows.shift

    if Array === mutations 
      rows
    else
      rows.first
    end
  end

  def self.parse_genomic_mutation(mutation)
    mutation.match(/(\d+):(\d+):(1|-1):([A-Z])\/([A-Z])/).values_at 1,2,3,4,5
  end

  def self.add_predictions(tsv)
    raise "Input not TSV" unless TSV === tsv

    raise "Field 'Refseq Protein ID' Not in TSV" unless tsv.fields.include? "Refseq Protein ID" 

    raise "Field 'Protein Mutation' Not in TSV" unless tsv.fields.include? "Protein Mutation" 

    data = []
    tsv.through :key, ["Refseq Protein ID", "Protein Mutation"] do |key,values|
      refseqs, mutations = values
      mutations = mutations.reject{|mutation| mutation[0] == mutation[-1]}
      next if refseqs.nil? or refseqs.compact.reject{|v| v.nil? or v.empty?}.empty? or mutations.empty?

      refseqs.compact.uniq.each do |refseq|
        data << [refseq, mutations]
      end
    end

    data.sort!


    predictions = {}
    predict_aminoacid_mutation_batch(data).each{|values| predictions[values[0] + ":" << values[1]] = values.values_at 3,4,5,6}

    refseq_field = tsv.identify_field "Refseq Protein ID" 
    protein_field = tsv.identify_field "Protein Mutation" 
 
    tsv.add_field "SIFT:Prediction" do |key,values|
      refseqs = if refseq_field === :key
                  [key]
                else
                  values[refseq_field] || []
                end

      next if refseqs.compact.reject{|v| v.nil? or v.empty?}.empty?

      mutations = values[protein_field]

      refseqs.zip(mutations).collect do |refseq,mutation|
        case
        when (mutation.nil? or mutation.empty?)
          "No Prediction"
        when mutation[0] == mutation[-1]
          "TOLERATED"
        when (refseq.nil? or refseq.empty?)
          "No Prediction"
        else
          list = predictions[refseq + ":" << mutation]
          if list.nil?
            "No Prediction"
          else
            list.first
          end
        end
      end
    end

    tsv
  end

end
