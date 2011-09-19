require 'phgx'

module STITCH
  extend Resource
  self.pkgdir = "phgx"
  self.subdir = "share/stitch"

  STITCH.claim STITCH.root.find, :rake, Rbbt.share.install.STITCH.Rakefile.find(:lib)
end
