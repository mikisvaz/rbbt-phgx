require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/polyphen'

class TestPolyphen2 < Test::Unit::TestCase
  def test_predict_disease
    accession = "A6NFZ4"
    mutation =  "Y34D"

    assert_equal "probably damaging", Polyphen2.predict(accession, mutation).first
  end

  def test_batch
    query =<<-EOF
A6NFZ4 Y34D
    EOF

    assert_equal "probably damaging", Polyphen2::Batch.predict(query)["A6NFZ4_Y34D"]["prediction"].first
  end
end

