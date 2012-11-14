require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/polyphen'

class TestPolyphen2 < Test::Unit::TestCase
  def _test_predict_disease
    accession = "A6NFZ4"
    mutation =  "Y34D"

    assert_equal "probably damaging", Polyphen2.predict(accession, mutation).first
  end

  def test_batch
    query =<<-EOF
A6NFZ4 34 Y D
    EOF

    ddd Polyphen2::Batch.predict(query)["A6NFZ4:Y34D"]
    assert_equal "probably damaging", Polyphen2::Batch.predict(query)["A6NFZ4:Y34D"]["prediction"]
    assert_equal "probably damaging", Polyphen2::Batch.chunked_predict(query)["A6NFZ4:Y34D"]["prediction"]
  end
end

