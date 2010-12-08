require 'rbbt-util'
require 'rbbt/util/pkg_config'
require 'rbbt/util/pkg_data'
require 'rbbt/util/open'
require 'rbbt/util/tmpfile'
require 'rbbt/util/filecache'

module PhGx
  extend PKGConfig
  extend PKGData

  self.load_cfg(%w(datadir), "datadir: #{File.join(ENV['HOME'], 'phgx', 'data')}\n")
end

