module Intrigue
module Issue
class BinaryEdgeScore< BaseIssue

  def self.generate(instance_details={})
    to_return = {
      name: "binaryedge_score",
      pretty_name: "High Risk Asset in Binary Edge",
      status: "confirmed",
      category: "endpoint"
    }.merge!(instance_details)

  to_return
  end

end
end
end
