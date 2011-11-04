require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/sift'

class TestSIFT < Test::Unit::TestCase

  def test_predict_aminoacid_mutation
    accession = "NP_001008502"
    mutation =  "Q554P"

    assert_equal "TOLERATED", SIFT.predict_aminoacid_mutation(accession, mutation)[3]
  end

  def test_predict_aminoacid_mutation_batch
    accession = "NP_001008502"
    mutation =  "Q554P"

    assert_equal "TOLERATED", SIFT.predict_aminoacid_mutation_batch( [[accession, mutation]]).first[3]
  end

  def test_predict
    ensp = "ENSP00000224605"
    mutation = "A63T"
    assert_equal "TOLERATED", SIFT.predict( [[ensp, mutation] * ":"]).values.first["Prediction"]
  end

end
