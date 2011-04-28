require 'rbbt/util/log'
require 'rbbt/util/open'
module SNPSandGO
  URL="http://snps-and-go.biocomp.unibo.it/cgi-bin/snps-and-go/runpred.cgi?uniprot=#ACCESSION#&position=#POSITION#&wild-type=#REFERENCE#&substituting=#SUBSTITUTION#"

  def self.parse_mutation(mutation)
    mutation.match(/([A-Z])(\d+)([A-Z])/i).values_at 1,2,3
  end

  def self.predict(accession, mutation)
    reference, pos, substitution = parse_mutation(mutation)

    url = URL.sub(/#ACCESSION#/,accession).sub(/#POSITION#/, pos).sub(/#REFERENCE#/,reference).sub(/#SUBSTITUTION#/,substitution)

    res = Open.read(url)

    raise "Error in prediction" unless res =~ /RESULTS/

    res.match(/Position\s+WT\s+NEW\s+Effect\s+RI\n\s+\d+\s+[A-Z]\s+[A-Z]\s+(\w+)\s+(\d+)/).values_at 1,2
  end

  def self.add_predictions(tsv)
    raise "Input not TSV" unless TSV === tsv

    uniprot_field = tsv.identify_field "UniProt/SwissProt Accession" 
    raise "Field 'UniProt/SwissProt Accession' Not in TSV" if uniprot_field.nil?

    protein_field = tsv.identify_field "Protein Mutation" 
    raise "Field 'Protein Mutation' Not in TSV" if protein_field.nil?


    tsv.add_field "SNPs&GO:Prediction" do |key,values|
      uniprots = if uniprot_field === :key
                   [key]
                 else
                   values[uniprot_field] || []
                 end

      mutations = values[protein_field]

      uniprots.zip(mutations).collect{|uniprot,mutation| 
        case
        when mutation.nil?
          "No Prediction" 
        when mutation[0] == mutation[-1]
            "Neutral"
        when (uniprot.nil? or uniprot.empty?)
          "No Prediction" 
        else
          begin
            SNPSandGO.predict(uniprot, mutation).first
          rescue
            "No Prediction"
          end
        end
      }
    end

    tsv
  end
end
