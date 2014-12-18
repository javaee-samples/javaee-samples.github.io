# This is a bundler configuration file (http://gembundler.com).
#
# Bundler makes it easy to make sure that your application has the dependencies
# it needs to start up and run without errors. It locates and installs the gems
# and their dependencies listed in this file, Gemfile.
#
# After installing any needed gems to your system, bundler writes a snapshot of
# all of the gems and versions that it installed to Gemfile.lock.
#
# Gemfile.lock makes your application a single package of both your own code
# and the third-party code so it remains stable in a known working state.
#
# To get started, first make sure you've installed bundler using gem install
# (or jgem install for JRuby):
#
# gem install bundler
#
# Then, use bundler to fetch the remaining libraries you'll need:
#
# bundle install
#
# Now, you're ready to start developing!
#
# awestruct -s
#
# Though if you want to be strict, you should execute in a bundle sandbox:
#
# bundle exec awestruct -s

source "https://rubygems.org"

ruby '1.9.3', :engine => 'jruby', :engine_version => '1.7.17'

gem "awestruct", "0.5.5"

gem "slim"
gem "kramdown"
gem "asciidoctor"
gem "uglifier"
gem "htmlcompressor"
gem "coffee-script"

gem "rest-client"
gem "hpricot"
gem "git"

gem "bouncy-castle-java", :platforms => :jruby
gem "therubyrhino", :platforms => :jruby
gem "therubyracer", "0.10.1", :platforms => :ruby
gem "jruby-openssl", :platforms => :jruby
gem "rb-inotify", :platforms => [:ruby, :jruby]

gem "puma"
gem "rspec", ">= 2.9"
