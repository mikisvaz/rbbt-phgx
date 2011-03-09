require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'test/unit'
require 'rbbt/util/tmpfile'
require 'rbbt/sources/pharmagkb'

class TestPhGKB < Test::Unit::TestCase
  def test_phgkb
    assert PharmaGKB.variants.tsv['rs25487']['Associated Gene Name'].include? 'XRCC1'
  end
end

