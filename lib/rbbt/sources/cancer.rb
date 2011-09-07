require 'phgx'

module Cancer
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = self["share/Cancer"].find :lib
end
