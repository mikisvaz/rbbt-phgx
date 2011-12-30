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

if defined? Entity 

  module KeggPathway
    extend Entity
    self.format = "KEGG Pathway ID"

    self.annotation :organism

    def self.filter(query, field = nil, options = nil, entity = nil)
      return true if query == entity

      return true if KeggPathway.setup(entity.dup, options.merge(:format => field)).name.index query

      false
    end

    property :name => :single2array do
      return nil if self.nil?
      name = KEGG.id2name(self)
      name.sub(/ - Homo.*/,'') unless name.nil?
    end

    property :description => :single2array do
      KEGG.description(self)
    end

    property :genes => :array2single do |organism|
      organism ||= self.organism
      @genes ||= KEGG.index2genes.values_at(*self).
        each{|pth| pth.organism = organism if pth.respond_to? :organism }
    end
  end

  if defined? Gene and Entity === Gene
    module Gene
      self.format = "KEGG Gene ID"

      def to_kegg
        return self if format == "KEGG Gene ID"
        if Array === self
          Gene.setup(KEGG.index2kegg.values_at(*to("Ensembl Gene ID")), "KEGG Gene ID", organism)
        else
          Gene.setup(KEGG.index2kegg[to("Ensembl Gene ID")], "KEGG Gene ID", organism)
        end
      end

      def from_kegg
        return to("Ensembl Gene ID") unless format == "KEGG Gene ID"
        if Array === self
          Gene.setup(KEGG.index2ens.values_at(*self), "Ensembl Gene ID", organism)
        else
          Gene.setup(KEGG.index2ens[self], "Ensembl Gene ID", organism)
        end
      end

      property :to! => :array2single do |new_format|
        return self if format == new_format
        list = self.from_kegg
        Gene.setup(Translation.job(:tsv_translate, "", :organism => organism, :genes => list, :format => new_format).exec.values_at(*list), new_format, organism)
      end

      property :kegg_pathways => :array2single do
        @kegg_pathways ||= KEGG.gene_pathway.tsv(:persist => true, :key_field => "KEGG Gene ID", :fields => ["KEGG Pathway ID"], :type => :flat, :merge => true).values_at(*self.to_kegg).
          each{|pth| pth.organism = organism if pth.respond_to? :organism }.tap{|o| KeggPathway.setup(o, organism)}
      end
    end
  end
end
