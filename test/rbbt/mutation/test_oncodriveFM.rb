require File.join(File.expand_path(File.dirname(__FILE__)), '../..', 'test_helper.rb')
require 'rbbt/mutation/oncodriveFM'

class TestOncodriveFM < Test::Unit::TestCase

  def test_CLL
    require 'rbbt/workflow'
    Workflow.require_workflow "StudyExplorer"
    s = Study.setup("CLL")
    puts OncodriveFM.process_cohort(s.cohort).select("p-value"){|v| not v.empty? and v.to_f < 0.05}
  end
end

