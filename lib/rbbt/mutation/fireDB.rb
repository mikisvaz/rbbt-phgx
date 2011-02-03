require 'phgx'
require 'rbbt/util/cmd'

module FireDB
#  PhGx.add_software "firePredText.pl" => ['FireDB', :binary]
  PhGx.add_software "FireDB" => ['', :directory]

  def self.predict(accession, sequence, mutation)
    CMD.cmd("perl " + File.join(PhGx.find_software("FireDB"), "firePredText.pl") + " " + [accession, accession, sequence, 10] * " ").read
  end

end
