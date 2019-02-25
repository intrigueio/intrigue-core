require_relative "version"

require_relative "helpers"

require_relative "routes/analysis"
require_relative "routes/engine"
require_relative "routes/entities"
require_relative "routes/global"
require_relative "routes/issues"
require_relative "routes/project"
require_relative "routes/results"

require_relative "models/mixins/calculate_provider"
require_relative "models/mixins/handleable"
require_relative "models/mixins/match_exceptions"

require_relative "models/alias_group"
require_relative "models/entity"
require_relative "models/issue"
require_relative "models/logger"
require_relative "models/project"
require_relative "models/task_result"
require_relative "models/scan_result"

require_relative "workers/generate_graph_worker"
require_relative "workers/generate_meta_graph_worker"
