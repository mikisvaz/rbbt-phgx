require 'phgx'

module Pina
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/pina"

  Pina.claim Pina.root.find, :rake, Rbbt.share.install.Pina.Rakefile.find(:lib)
end



if defined? Entity and defined? Gene and Entity === Gene
  module Gene
    property :pina_interactors => :array2single do 
      Gene.setup(Pina.protein_protein.tsv(:persist => true, :fields => ["Interactor UniProt/SwissProt Accession"], :type => :flat, :merge => true, :unnamed => true).values_at(*self.uniprot), "UniProt/SwissProt Accession", organism)
    end
    persist :_ary_pina_interactors
  end
end

