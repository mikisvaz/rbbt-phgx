require 'phgx'

module Biogrid
  extend Resource
  data_module PhGx

  ["Hsa", "Rno", "Sce"].each do |organism|
    module_eval "#{ organism } = with_key '#{organism}'"
  end

end
