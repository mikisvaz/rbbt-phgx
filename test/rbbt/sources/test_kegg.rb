require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'test/unit'
require 'rbbt/util/tmpfile'
require 'rbbt/entity/gene'
require 'rbbt/sources/kegg'

class TestKEGG < Test::Unit::TestCase
  def test_kegg_gene
    organism = "Hsa"
    gene = Gene.setup "TP53", "Associated Gene Name", organism

    assert_equal gene.organism, gene.to_kegg.from_kegg.organism
    assert_equal "KEGG Gene ID", gene.to_kegg.format
    assert_equal organism, gene.to_kegg.organism
    assert_equal gene.ensembl, gene.to_kegg.ensembl
    assert_equal gene.name, gene.to_kegg.ensembl.name
    assert_equal gene.to_kegg.ensembl.name, gene.to_kegg.name
  end
end

