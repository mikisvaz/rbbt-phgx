require 'rbbt'
require 'rbbt/resource'

module KEGG
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/kegg"

  KEGG.claim KEGG.root.find, :rake, Rbbt.share.install.KEGG.Rakefile.find(:lib)
end
