require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/snps_and_go'

class TestSNPSandGO < Test::Unit::TestCase
  def test_parse_mutation
    assert_equal ['Y','233','W'], SNPSandGO.parse_mutation('Y233W')
  end

  def test_predict_disease
    accession = "Q9UGJ1"
    mutation =  "G1556E"

    assert_raise Exception do SNPSandGO.predict(accession, mutation) end
  end

  def test_predict_disease
    accession = "A6NFZ4"
    mutation =  "Y34D"

    assert_equal ["Disease", "2"], SNPSandGO.predict(accession, mutation)
  end

  def test_predict_neutral
    accession = "A6NGY1"
    mutation =  "G155R"

    assert_equal ["Neutral", "9"], SNPSandGO.predict(accession, mutation)
  end


end

