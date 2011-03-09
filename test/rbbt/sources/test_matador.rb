require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'test/unit'
require 'rbbt/sources/matador'

class TestMatador < Test::Unit::TestCase
 def test_matador
    assert_equal 'procainamide', Matador.protein_drug.tsv['ENSP00000343023']['Chemical'].first
  end
end

