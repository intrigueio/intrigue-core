require 'spec_helper'

describe "Intrigue" do
  describe "Reporting" do
    it "should return true after generating a CSV" do
      task_result = Intrigue::Model::TaskResult.new("test","test")
      result = Intrigue::ReportFactory.create_by_type "csv", task_result
      expect result == true
    end
  end
end
