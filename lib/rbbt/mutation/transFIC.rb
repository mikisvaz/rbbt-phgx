require 'rbbt-util'
require 'rbbt/util/open'
require 'rbbt/tsv'
require 'nokogiri'
require 'digest/md5'
require 'rest_client'
require 'rbbt/sources/organism'

module TransFIC

  class NotDone < StandardError; end

  URL="http://bg.upf.edu/transfic/taskService"
  ASTERISK = "*"[0]

  # mutations is a hash of genes in Uniprot protein accession pointing to lists
  # of aminoacid substitutions
  def self.predict(mutations)
    options = {}
    ensp2uni = Organism.identifiers("Hsa").index :target => "UniProt/SwissProt ID", :fields => "Ensembl Protein ID", :persist => true
    searchText = mutations.collect{|mutation| protein, change = mutation.split(":"); next if ensp2uni[protein].nil?; [ensp2uni[protein], change] * "\t"}.compact.uniq * "\n"

    Log.debug "Querying TransFIC for: #{mutations.length} mutations"

    TmpFile.with_file(searchText) do |file|
      test_url = CMD.cmd("curl -X PUT -T '#{ file }' '#{ URL }'").read

      result = nil

      begin
        Misc.insist(5) do
          result = CMD.cmd("curl -X GET '#{ test_url }'").read

          raise result.split("\n").select{|line| line =~ /Error/}.first if result =~ /Error/

          while result =~ /executing/
            sleep 10
            result = CMD.cmd("curl -X GET '#{ test_url }'").read
          end

          raise result.split("\n").select{|line| line =~ /Error/}.first if result =~ /Error/
        end
      rescue
        if $!.message =~ /validating/
          Log.debug(Open.read(file))
        end
        raise $!
      end

      Log.medium("TransFIC DONE")
      
      tsv = TSV.setup({}, :key_field => "Protein Mutation", :fields => %w(siftTransfic siftTransficLabel pph2Transfic pph2TransficLabel maTransfic maTransficLabel), :type => :list)
      result.split("\n").each do |line|
        next if line[0] == "#"[0]

        id, hgnc, hgncdesc, transcript, ensp, sw, protein_position, amino_acids, sift, polyphen, mass, 
          siftTransfic, siftTransficLabel, pph2Transfic, pph2TransficLabel, maTransfic, maTransficLabel = line.split("\t")

        change = [amino_acids.split("/").first, protein_position, amino_acids.split("/").last] * ""
        mutation = [ensp,change] * ":"

        tsv[mutation] = [siftTransfic, siftTransficLabel, pph2Transfic, pph2TransficLabel, maTransfic, maTransficLabel]
      end

      tsv.select(mutations)
    end
  end

  def self.chunked_predict(mutations, max = 1000)
    chunks = mutations.length.to_f / max
    chunks = chunks.ceil

    Log.debug("TransFIC ran with #{chunks} chunks of #{ max } mutations") if chunks > 1
    num = 1
    Misc.divide(mutations, chunks).inject(nil) do |acc, list|
      Log.debug("TransFIC ran with #{chunks} chunks: chunk #{num}") if chunks > 1
      begin
        result = predict(list)
      rescue
        if list.length > 2
          Log.debug("Error predicting in transFIC. Divinding list of size #{list.length}")
          result = chunked_predict(list, list.length / 2)
        else
          Log.debug("Error predicting in transFIC. Single error detected")
          next
        end
      end
      if acc.nil?
        acc = result
      else
        acc = TSV.setup(acc.merge(result))
      end
      num += 1
      acc
    end
  end
end
