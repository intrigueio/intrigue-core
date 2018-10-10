module Intrigue
module Enrich
class BaseTask

  extend Intrigue::Task::Generic
  extend Intrigue::Task::Browser
  extend Intrigue::Task::Data
  extend Intrigue::Task::Dns
  extend Intrigue::Task::Helper
  extend Intrigue::Task::Parse
  extend Intrigue::Task::Product
  extend Intrigue::Task::Regex
  extend Intrigue::Task::Scanner
  extend Intrigue::Task::Web
  extend Intrigue::Task::Whois

end
end
end
