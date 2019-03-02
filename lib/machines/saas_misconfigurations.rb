module Intrigue
module Machine
  class SaasMisconfigurations < Intrigue::Machine::Base

    def self.metadata
      {
        :name => "saas_misconfigurations",
        :pretty_name => "Check SaaS Misconfigurations",
        :passive => true,
        :user_selectable => true,
        :authors => ["jcran"],
        :description => "This machine checks for common misconfigurations in hosted services. Start with a Domain."
      }
    end

    def self.recurse(entity, task_result)
      if entity.type_string == "Domain"

        return unless entity.scoped

        shortname = entity.name.split(".").first
        start_recursive_task(task_result,"aws_s3_brute",entity,[
          {"name" => "additional_buckets","value" => "#{shortname}"}])

        start_recursive_task(task_result,"saas_google_groups_check",entity)
        start_recursive_task(task_result,"saas_google_calendar_check",entity)
        start_recursive_task(task_result,"saas_trello_check",entity)
        start_recursive_task(task_result,"saas_jira_check",entity)
        start_recursive_task(task_result,"email_brute_gmail_glxu",entity)


      elsif entity.type_string == "EmailAddress"
        
        start_recursive_task(task_result,"search_have_i_been_pwned",entity)

      end
    end

end
end
end
