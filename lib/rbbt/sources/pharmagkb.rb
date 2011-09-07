require 'phgx'

module PharmaGKB
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/pharmagkb"

  PharmaGKB.claim PharmaGKB.root.find, :rake, Rbbt.share.install.PharmaGKB.Rakefile.find(:lib)
end
