 require_relative "version"

require_relative "helpers"

# must be brought in first, system should be skipped as a directive
require_relative "routes/system"

require_relative "routes/analysis"
require_relative "routes/entities"
require_relative "routes/issues"
require_relative "routes/project"
require_relative "routes/results"


require_relative "models/mixins/handleable"
require_relative "models/mixins/path_traversal"

require_relative "models/alias_group"
require_relative "models/entity"
require_relative "models/issue"
require_relative "models/logger"
require_relative "models/global_entity"
require_relative "models/project"
require_relative "models/task_result"
require_relative "models/scan_result"

require_relative "workers/generate_graph_worker"
require_relative "workers/generate_meta_graph_worker"
