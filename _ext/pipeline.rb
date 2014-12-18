require 'slim'
require 'zurb-foundation'
require './_ext/tweakruby.rb'
require './_ext/restclient_extensions_enabler.rb'
require './_ext/identities.rb'
require './_ext/repository.rb'
require './_ext/javaeesamples.rb'
require './_ext/jenkins.rb'
require './_ext/samples.rb'
require './_ext/asciidocify.rb'

Awestruct::Extensions::Pipeline.new do

  # GitHub API calls should be wrapped with credentials to up limit
  github_auth = Identities::GitHub::Auth.new('.github-auth')
  github_collector = Identities::GitHub::Collector.new(:teams =>
    []
  )

  extension Awestruct::Extensions::RestClientExtensions::EnableAuth.new([github_auth])
  extension Awestruct::Extensions::RestClientExtensions::EnableGetCache.new
  extension Awestruct::Extensions::RestClientExtensions::EnableJsonConverter.new

  extension Awestruct::Extensions::Identities::Storage.new

  extension Awestruct::Extensions::Repository::Collector.new(:observers => [github_collector])
  extension Awestruct::Extensions::Identities::Collect.new(github_collector)
  extension Awestruct::Extensions::Identities::Crawl.new(
    Identities::GitHub::Crawler.new,
    Identities::Gravatar::Crawler.new
  )

  extension SampleExtension.new

  # Indexifier moves HTML files to their own directory to achieve "pretty" URLs (e.g., features.html -> /features/index.html)
  extension Awestruct::Extensions::Indexifier.new
  extension Awestruct::Extensions::Sitemap.new

  extension Awestruct::Extensions::Jenkins::Jobs.new('https://javaee-support.ci.cloudbees.com/')

  # Must be after all other extensions that might populate identities
  extension Awestruct::Extensions::Identities::Cache.new

  # Transformers
  transformer Awestruct::Extensions::Minify.new([:js])

  helper Awestruct::Extensions::GoogleAnalytics
  helper AsciiDoc
end
