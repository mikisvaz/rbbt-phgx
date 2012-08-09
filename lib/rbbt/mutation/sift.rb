require 'rbbt/util/open'
require 'nokogiri'
module SIFT
  URL_AMINOACID="http://sift.jcvi.org/sift-bin/SIFT_pid_subst_all_submit.pl"
  URL_GENOMIC="http://sift.jcvi.org/sift-bin/SIFT_feed_to_chr_coords.pl"
  URL_ENSP="http://sift.jcvi.org/sift-bin/retrieve_enst.pl"

  def self.predict(mutations)
    data_str = mutations.collect{|mut| mut.sub(':', ',')}.uniq * "\n"
    doc = Nokogiri::HTML(Open.read(URL_ENSP, :wget_options => {"--post-data=" => "'ENSP=#{data_str}'"}))

    if doc.to_s.match(/Your computer has exceeded its daily limit/)
      Open.clean_cache(URL_ENSP, :wget_options => {"--post-data=" => "'ENSP=#{data_str}'"})
      raise "Daily limit reached" 
    end

    rows = []
    doc.css('tr').each do |row|
      rows << row.css('td').collect{|cell| content = cell.content.strip; content.sub(/\s*&nbsp.*/, "").sub(/[^\w,]*$/,'')}
    end

    rows.shift

    if rows.any?
      TSV.open StringIO.new(rows.collect{|row| row.collect{|v| v.sub(/(ENSP\d+),/,'\1:')} * "\t"} * "\n"), :list,
        :key_field => "Mutated Isoform", :fields =>["Ensembl Protein ID", "Amino Acid Position", "Wildtype Amino Acid", "Mutant Amino Acid", "Prediction", "Score 1", "Score 2", "Score 3"]
    else
      TSV.setup({}, :type => :list, :key_field => "Mutated Isoform", :fields =>["Ensembl Protein ID", "Amino Acid Position", "Wildtype Amino Acid", "Mutant Amino Acid", "Prediction", "Score 1", "Score 2", "Score 3"])
    end
  end

  def self.chunked_predict(mutations)
    chunks = mutations.length.to_f / 500
    chunks = chunks.ceil
    tsv = TSV.setup({}, :type => :list, :key_field => "Mutated Isoform", :fields =>["Ensembl Protein ID", "Amino Acid Position", "Wildtype Amino Acid", "Mutant Amino Acid", "Prediction", "Score 1", "Score 2", "Score 3"])
    Misc.divide(mutations.uniq.sort, chunks).inject(tsv) do |acc, list|
        acc = TSV.setup(acc.merge(predict(list)))
    end
  end

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

    raise "Field 'RefSeq Protein ID' Not in TSV" unless tsv.fields.include? "RefSeq Protein ID" 

    raise "Field 'Protein Mutation' Not in TSV" unless tsv.fields.include? "Protein Mutation" 

    data = []
    if tsv.type == :double
      tsv.through :key, ["Refseq Protein ID", "Protein Mutation"] do |key,values|
        refseqs, mutations = values
        mutations = mutations.reject{|mutation| mutation[0] == mutation[-1]}
        next if refseqs.nil? or refseqs.compact.reject{|v| v.nil? or v.empty?}.empty? or mutations.empty?
        refseqs.compact.uniq.each do |refseq|
          data << [refseq, mutations]
        end
      end
    else
      tsv.through :key, ["Refseq Protein ID", "Protein Mutation"] do |key,values|
        refseq, mutation = values
        next if refseq.nil? or refseq.empty?
        next if mutation[0] == mutation[-1]
        data << [refseq, mutation]
      end
    end

    data.sort!

    predictions = {}
    predict_aminoacid_mutation_batch(data).each{|values| predictions[values[0] + ":" << values[1]] = values.values_at 3,4,5,6}

    refseq_field = tsv.identify_field "RefSeq Protein ID" 
    protein_field = tsv.identify_field "Protein Mutation" 
 
    if tsv.type == :double
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
    else
      tsv.add_field "SIFT:Prediction" do |key,values|
        refseq = if refseq_field === :key
                    key
                  else
                    values[refseq_field]
                  end

        next if refseq.nil? or refseq.empty?

        mutation = values[protein_field]

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
