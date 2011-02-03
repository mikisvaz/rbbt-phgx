require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/sift'

class TestSIFT < Test::Unit::TestCase
  def _test_predict_aminoacid_mutation
    accession = "NP_001008502"
    mutation =  "Q554P"

    assert_equal "DAMAGING *Warning! Low confidence.", SIFT.predict_aminoacid_mutation(accession, mutation)[3]
  end

  def _test_parse_mutation
    mutation = "2:43881517:1:A/T"

    assert_equal %w(2 43881517 1 A T), SIFT.parse_genomic_mutation(mutation)
  end

  def test_predict_aminoacid_mutation
    mutation = "2:43881517:1:A/T"
    puts SIFT.predict_genomic_mutation(mutation)
  end


end

