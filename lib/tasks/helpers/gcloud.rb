module Intrigue
  module Task
    module GCloud # conflicts with official AWS module so this is named AWS Helper


      # extract the name of a google cloud bucket from a string
      # this works with HTML and plain URIs
      def extract_gcp_bucket_name_from_string(str)
        str.scan(/(?:https:\/\/)?storage\.googleapis\.com\/([\w\.\-]+)/i).flatten.first
      end


    end
  end
end