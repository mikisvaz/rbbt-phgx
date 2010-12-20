require File.expand_path(File.dirname(__FILE__) + '/../../test_helper')
require 'test/unit'
require 'rbbt/util/tmpfile'

class TestSIFT < Test::Unit::TestCase
  def test_true
    assert true
  end
  def _test_sift
    require 'rbbt/sources/sift'
    assert File.exists? File.join(PhGx.opt_dir, 'sift')
  end
end

