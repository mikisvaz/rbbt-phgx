require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'test/unit'
require 'rbbt/util/tmpfile'
require 'rbbt/sources/cancer'

class TestCancer < Test::Unit::TestCase
  def test_anais_annotations
    assert TSV.new(Cancer.anais_annotations)['ENSG00000087460']['Tumor Type'].include? 'Adrenocortical'
  end
end

