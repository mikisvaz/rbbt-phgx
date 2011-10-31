require 'rbbt'
require 'rbbt/resource'

module KEGG
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/kegg"

  KEGG.claim KEGG.root.find, :rake, Rbbt.share.install.KEGG.Rakefile.find(:lib)

  def self.names
    @@names ||= KEGG.pathways.tsv :fields => ["Pathway Name"], :persist => true, :type => :single
  end

  def self.descriptions
    @@descriptions ||= KEGG.pathways.tsv :fields => ["Pathway Description"], :persist => true, :type => :single
  end


  def self.index2genes
    @@index2genes ||= KEGG.gene_pathway.tsv :key_field => "KEGG Pathway ID", :fields => ["KEGG Gene ID"], :persist => true, :type => :flat, :merge => true
  end

  def self.index2ens
    @@index2ens ||= KEGG.identifiers.index :persist => true
  end

  def self.index2kegg
    @@index2kegg ||= KEGG.identifiers.index :target => "KEGG Gene ID", :persist => true
  end

  def self.id2name(id)
    names[id]
  end

  def self.description(id)
    descriptions[id]
  end
end

module Gene

  def to_kegg
    if Array === self
      Gene.setup(KEGG.index2kegg.values_at(*to("Ensembl Gene ID")), "KEGG Gene ID", organism)
    else
      Gene.setup(KEGG.index2kegg[to("Ensembl Gene ID")], "KEGG Gene ID", organism)
    end
  end

  def from_kegg
    if Array === self
      Gene.setup(KEGG.index2ens.values_at(*self), "Ensembl Gene ID", organism)
    else
      Gene.setup(KEGG.index2ens[self], "Ensembl Gene ID", organism)
    end
  end
end
