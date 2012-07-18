require 'rbbt/util/open'
require 'rbbt/tsv'
require 'nokogiri'
require 'digest/md5'
module MutationAssessor

  class NotDone < StandardError; end
  URL="http://mutationassessor.org/"
  ASTERISK = "*"[0]

  # mutations is a hash of genes in Uniprot protein accession pointing to lists
  # of aminoacid substitutions
  def self.predict(mutations)
    vars = mutations.collect{|gene, list|
      list = [list] unless Array === list
      list.collect do |mut|
        [gene, mut] * "\t"
      end
    }.flatten.sort.uniq * "\n" + "\n"

    post_data = { :beenQ => "1",
      :info=> "on",
      :tableQ=> "on",
      :chr=> "on",
      :bsites=> "on",
      :timeout => 600,
      :vars => vars}.collect{|k,v| [k,v] * "="} * "&"

    Log.debug "Querying Mutation Assessor for: #{vars.split(/\n/).length}"
    tries = 0
    nocache = false
    begin
      doc = nil
      TmpFile.with_file(post_data) do |post_file|
        Log.medium "Updating cache:" if nocache == :update
        doc = Nokogiri::HTML(Open.read(URL, :wget_options => {"--post-file" => post_file }, :nocache => nocache))
      end

      textareas = doc.css('textarea')

      if textareas.empty?
        Log.debug "No text area"
        Log.debug doc.to_s
        raise NotDone, "No text aread found in response HTML"
      end

      result = textareas.last.content

      if result =~ /Cannot parse variant/
        tmp = TmpFile.tmp_file
        variants = tmp + ".list"
        Open.write(variants, post_data )
        raise "Cannot parse variants. Variants in file #{ variants }"
      end

      raise NotDone, "Not done" if result =~ /\t\[sent\]\t/
    rescue NotDone
      tries += 1
      nocache = :update

      Log.medium "Mutation Assessor not done, waiting:"
      sleep 30

      if tries < 10
        Log.medium "Retrying mutation assessor"
        retry
      else
        raise "Error processing Mutation Assessor response"
      end
    end

    if result.empty?
      tmp = TmpFile.tmp_file
      html = tmp + ".html"
      variants = tmp + ".list"
      Open.write(tmp, doc.content)
      Open.write(variants, post_data )
      raise "Result empty. Possible error. html in #{ html }, variants in #{variants}" 
    end

    result.sub! /^\t/, ''
    result.gsub! /\n\s*\d+\s*\t/s, "\n"

    if result.empty?
      TSV.setup({}, :header_hash => "", :type => :list)
    else
      TSV.open(StringIO.new(result), :header_hash => "", :type => :list)
    end
  end

  def self.chunked_predict(mutations, max = 1000)
    flattened_mutations = mutations.collect{|g,list| list = [list] unless Array === list; list.collect{|m| [g,m] } }.flatten(1)
    chunks = flattened_mutations.length.to_f / max
    chunks = chunks.ceil

    Log.debug("Mutation Assessor ran with #{chunks} chunks of #{ max } mutations") if chunks > 1
    Misc.divide(flattened_mutations, chunks).inject(nil) do |acc, list|
      unflattened_mutations = {}
      list.each{|g,m| next if g.nil?; unflattened_mutations[g] ||= []; unflattened_mutations[g] << m}
      if acc.nil?
        acc = predict(unflattened_mutations)
      else
        acc = TSV.setup(acc.merge(predict(unflattened_mutations)))
      end
      acc
    end
  end

  def self.add_predictions(tsv)
    raise "Input not TSV" unless TSV === tsv

    raise "Field 'UniProt/SwissProt ID' Not in TSV" unless tsv.all_fields.include? "UniProt/SwissProt ID" 

    raise "Field 'Protein Mutation' Not in TSV" unless tsv.fields.include? "Protein Mutation" 

    data = []
    if tsv.type == :double
      tsv.through :key, ["UniProt/SwissProt ID", "Protein Mutation"] do |key,values|
        uni_accs, mutations = values
        mutations = mutations.reject{|mutation| mutation =~ /Indel/ or mutation[0] == mutation[-1] or mutation[-1] == ASTERISK or mutation[0] == ASTERISK }
        next if uni_accs.nil? or uni_accs.compact.reject{|v| v.nil? or v.empty?}.empty? or mutations.empty?

        uni_accs.compact.uniq.each do |uni_acc|
          data << [uni_acc, mutations]
        end
      end
    else
      tsv.through :key, ["UniProt/SwissProt ID", "Protein Mutation"] do |key,values|
        uni_acc, mutation = values
        next if uni_acc.nil? or uni_acc.empty?
        next if mutation[0] == mutation[-1] or mutation[-1] == ASTERISK or mutation[0] == ASTERISK
        data << [uni_acc, mutation]
      end
    end

    data.sort!


    predictions = {}
    predict(data).each{|uni_acc, values| 
      protein, mutation = uni_acc.split(/\s+/)

      values = values.zip_fields
      values.each do |v|
        pred     = v["Func. Impact"]
        predictions[protein] ||= {}
        predictions[protein][mutation] = pred
      end
    }

    uni_acc_pos = tsv.identify_field "UniProt/SwissProt ID" 
    protein_field = tsv.identify_field "Protein Mutation" 
 
    if tsv.type == :double
      tsv.add_field "MutationAssessor:Prediction" do |key,values|
        uni_accs = if uni_acc_pos === :key
                    [key]
                  else
                    values[uni_acc_pos] || []
                  end

        next if uni_accs.compact.reject{|v| v.nil? or v.empty?}.empty?

        mutations = values[protein_field]

        uni_accs.zip(mutations).collect do |uni_acc,mutation|
          res = case
                when (mutation.nil? or mutation.empty?)
                  "No Prediction"
                when mutation[0] == mutation[-1]
                  "TOLERATED"
                when (uni_acc.nil? or uni_acc.empty?)
                  "No Prediction"
                else
                  list = []
                  list = predictions[uni_acc][mutation] if predictions.include? uni_acc
                  if list.nil?
                    "No Prediction"
                  else
                    list.first
                  end
                end
          res
        end
      end
    else
      tsv.add_field "MutationAssessor:Prediction" do |key,values|
        uni_acc = if uni_acc_pos === :key
                    key
                  else
                    values[uni_acc_pos]
                  end

        next if uni_acc.nil? or uni_acc.empty?

        mutation = values[protein_field]

        case
        when (mutation.nil? or mutation.empty?)
          "No Prediction"
        when mutation[0] == mutation[-1]
          "TOLERATED"
        when (uni_acc.nil? or uni_acc.empty?)
          "No Prediction"
        else
          list = []
          list = predictions[uni_acc][mutation] if predictions.include? uni_acc
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
