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
end
