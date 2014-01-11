# encoding: utf-8
require 'git'
require 'fileutils'
require 'rexml/document'
require_relative 'repository'

module Awestruct::Extensions::Repository::Visitors
  module Clone
    include Base

    def visit(repository, site)
      repos_dir = nil
      if site.repos_dir
        repos_dir = site.repos_dir
      else
        repos_dir = File.join(site.tmp_dir, 'repos')
      end
      if !File.directory? repos_dir
        FileUtils.mkdir_p(repos_dir)      
      end
      clone_dir = File.join(repos_dir, repository.path)
      rc = nil
      if !File.directory? clone_dir
        puts "Cloning repository #{repository.clone_url} -> #{clone_dir}"
        rc = Git.clone(repository.clone_url, clone_dir)
        if repository.master_branch.nil?
          rc.checkout(repository.master_branch)
        else
          repository.master_branch = rc.current_branch
        end
      else
        puts "Using cloned repository #{clone_dir}"
        rc = Git.open(clone_dir)
        master_branch = repository.master_branch
        if master_branch.nil?
          master_branch = rc.branches.find{|b| !b.remote and  !(b.name.include? 'detached' or b.name.include? 'no branch')}.name
          repository.master_branch = master_branch
        end
        rc.checkout(master_branch)
        begin
          # attempt a light pull
          rc.pull('origin')
        rescue
          # do hard reset to master branch, some forced change might have occured upstream
          rc.fetch('origin')
          rc.reset_hard("origin/#{master_branch}")
        end
      end
      repository.clone_dir = clone_dir
      repository.client = rc
    end
  end

  module RepositoryHelpers
    # Retrieves the contributors between the two commits, filtering
    # by the relative path, if present
    def self.resolve_contributors_between(site, repository, sha1, sha2, update_index = true)
      range_author_index = {}
      RepositoryHelpers.resolve_commits_between(repository, sha1, sha2).map {|c|
        # we'll use email as the key to finding their identity; the sha we just need temporarily
        # clear out bogus characters from email and downcase
        OpenStruct.new({:name => c.author.name, :email => c.author.email.downcase.gsub(/[^\w@\.\(\)]/, ''), :commits => 0, :sha => c.sha})
      }.each {|e|
        # This loop both grabs unique authors by email and counts their commits
        if !range_author_index.has_key? e.email
          range_author_index[e.email] = e
        end
        range_author_index[e.email].commits += 1
      }

      range_author_index.values.each {|e|
        # this loop registers author in global index if not present
        if repository.host.eql? 'github.com' and update_index
          site.git_author_index[e.email] ||= OpenStruct.new({
            :email => e.email,
            :name => e.name,
            :sample_commit_sha => e.sha,
            :sample_commit_url => RepositoryHelpers.build_commit_url(repository, e.sha, 'json'),
            :commits => 0,
            :repositories => []
          })
          site.git_author_index[e.email].commits += e.commits
          site.git_author_index[e.email].repositories |= [repository.html_url]
        end
        e.delete_field('sha')
      }.sort {|a, b| a.name <=> b.name}
    end

    # Retrieves the commits in the range, filtered on the relative
    # path in the repository, if present
    def self.resolve_commits_between(repository, sha1, sha2)
      rc = repository.client
      log = rc.log(10000).path(repository.relative_path)
      if sha1.nil?
        log = log.object(sha2)
      else
        log = log.between(sha1, sha2)
      end
    end

    def self.build_commit_url(repository, sha, ext)
      if !repository.commits_url.nil?
        url = repository.commits_url.gsub(/\{.*/, "/#{sha}")
      else
        url = repository.html_url + '/commit/' + sha + '.' + ext
      end
      return url
    end
  end

  module MavenHelpers

    # Traverse all modules recursivly in a repository from a given rev:root
    def self.traverse_modules(rev, repository)
      pomrev = repository.client.revparse("#{rev}pom.xml")
      pom = REXML::Document.new(repository.client.cat_file(pomrev))
      yield rev, pom

      unique_modules = Set.new
      pom.each_element('/project/modules/module') do |mod|
        unique_modules << mod.text()
      end
      pom.each_element('/project/profiles/profile/modules/module') do |mod|
        unique_modules << mod.text()
      end

      unique_modules.each do |submodule|
        MavenHelpers.traverse_modules("#{rev}#{submodule}/", repository) { |y, x| yield(y, x)}
      end
    end

    def self.to_relative_sub_path(rev, relative_repository_path)
      rev.gsub(/.*:/, '').gsub(relative_repository_path, '')
    end
  end

  # SEMI-HACK think about how best to curate & display info about these special repos
  # FIXME at least try to make GenericMavenComponent build on this one; perhaps a website component?
  module GenericComponent
    include Base
    def handles(repository)
      !File.exist? File.join(repository.clone_dir, repository.relative_path, 'pom.xml')
    end

    def visit(repository, site)
      rc = repository.client
      c = OpenStruct.new({
        :repository => repository,
        :basepath => repository.path.eql?(repository.owner) ? repository.path : repository.path.sub(/^#{repository.owner}-/, ''),
        :owner => repository.owner,
        :name => repository.name,
        :desc => repository.desc,
        :contributors => []
      })
      # FIXME not dry (from below)!
      RepositoryHelpers.resolve_contributors_between(site, repository, nil, rc.revparse('HEAD')).each do |contrib|
        i = c.contributors.index {|n| n.email == contrib.email}
        if i.nil?
          c.contributors << contrib
        else
          c.contributors[i].commits += contrib.commits
        end
      end
    end
  end

  module GenericMavenComponent
    include Base

    def initialize
      @root_head_pom = nil
    end

    def handles(repository)
      repository.path != 'arquillian-showcase' and
          repository.path != 'arquillian-container-reloaded' and
          File.exist? File.join(repository.clone_dir, repository.relative_path, 'pom.xml')
      #repository.path =~ /^arquillian-(core$|(testrunner|container|extension)-.+$)/ and
      #    repository.path != 'arquillian-testrunner-jbehave'
    end

    def visit(repository, site)
      @root_head_pom = nil
      rc = repository.client
      c = OpenStruct.new({
        :repository => repository,
        :basepath => repository.path.eql?(repository.owner) ? repository.path : repository.path.sub(/^#{repository.owner}-/, ''),
        :key => repository.path.split('-').last, # this is how components are matched in jira
        :owner => repository.owner,
        :html_url => repository.relative_path.empty? ? repository.html_url : "#{repository.html_url}/tree/#{repository.master_branch}/#{repository.relative_path.chomp('/')}",
        :external => !repository.owner.eql?('arquillian'),
        :name => resolve_name(repository),
        :desc => repository.desc,
        :groupId => resolve_group_id(repository),
        :parent => true,
        :lead => resolve_current_lead(repository, site.component_leads),
        # we should not assume the license for external modules (hardcoding is not ideal either)
        :license => ['jbossas', 'wildfly' 'jsfunit'].include?(repository.owner) ? 'LGPL-2.1' : 'Apache-2.0',
        :releases => [],
        :contributors => []
      })
      prev_sha = nil
      rc.tags.select {|t|
          # supports formats: 1.0.0.Alpha1
          #t.name =~ /^[1-9]\d*\.\d+\.\d+\.((Alpha|Beta|CR)[1-9]\d*|Final)$/
          # supports formats: 1.0.0.Alpha1 or 1.0.0-alpha-1 or with prefix- or 1.0.0 or 0.1
          t.name =~ /^([a-z]+-?)?[0-9]\d*\.\d+(\.\d+)?([\.-]((alpha|beta|cr)-?[1-9]\d*|final))?$/i
      }.sort_by{|t| rc.gcommit(t).author_date}.each do |t|
        # skip tag if arquillian has nothing to do with it
        next if repository.relative_path and rc.log(1).object(t.name).path(repository.relative_path).size.zero?
        # for some reason, we have to use ^0 to get to the actual commit, can't use t.sha
        sha = rc.revparse(t.name + '^0')
        commit = rc.gcommit(sha)
        committer = commit.committer
        release = OpenStruct.new({
          :tag => t.name,
          :version => t.name.gsub(/^([a-z]+-?)/, ''),
          :key => (c.key.eql?('core') ? '' : c.key + '_') + t.name, # jira release version key, should we add owner?
          #:license => 'track?',
          :sha => sha,
          :html_url => RepositoryHelpers.build_commit_url(repository, sha, 'html'),
          :json_url => RepositoryHelpers.build_commit_url(repository, sha, 'json'),
          :date => commit.author_date,
          :released_by => OpenStruct.new({
            :name => committer.name,
            :email => committer.email.downcase
          }),
          :contributors => RepositoryHelpers.resolve_contributors_between(site, repository, prev_sha, sha),
          :published_artifacts => []
        })
        if site.resolve_published_artifacts and repository.owner.eql? 'arquillian'
          resolve_published_artifacts(site.dir, repository, release)
        end
        # not assigning to release for now since it can be very space intensive
        #if site.release_notes_by_version.has_key? release.key
        #  release.issues = site.release_notes_by_version[release.key]
        #end
        depversions = resolve_dep_versions(repository, release.tag)
        release.compiledeps = []
        {
          'arquillian' => 'Arquillian Core',
          'arquillian_core' => 'Arquillian Core',
          'jboss_arquillian_core' => 'Arquillian Core',
          'org_jboss_arquillian' => 'Arquillian Core',
          'org_jboss_arquillian_core' => 'Arquillian Core',
          'arquillian_drone' => 'Arquillian Drone',
          'arquillian_warp' => 'Arquillian Warp',
          'arquillian_transaction' => 'Arquillian Transaction',
          'org_jboss_arquillian_graphene' => 'Arquillian Graphene',
          'shrinkwrap_shrinkwrap' => 'ShrinkWrap Core',
          'jboss_shrinkwrap' => 'ShrinkWrap Core',
          'shrinkwrap' => 'ShrinkWrap Core',
          'shrinkwrap_descriptors' => 'ShrinkWrap Descriptors',
          'shrinkwrap_descriptor' => 'ShrinkWrap Descriptors',
          'shrinkwrap_resolver' => 'ShrinkWrap Resolvers',
          'selenium' => 'Selenium',
          'junit_junit' => 'JUnit',
          'testng_testng' => 'TestNG',
          'spock' => 'Spock'
        }.each do |key, name|
          if depversions.has_key? key
            release.compiledeps << OpenStruct.new({:name => name, :key => key, :version => depversions[key]})
          end
        end
        c.releases << release
        prev_sha = sha
      end
      c.latest_version = (!c.releases.empty? ? c.releases.last.version : resolve_head_version(repository))
      c.latest_tag = (!c.releases.empty? ? c.releases.last.tag : 'HEAD')
      c.releases.each do |r|
        # FIXME not dry!
        r.contributors.each do |contrib|
          i = c.contributors.index {|n| n.email == contrib.email}
          if i.nil?
            c.contributors << contrib
          else
            c.contributors[i].commits += contrib.commits
          end
        end
      end
      # FIXME not dry!
      RepositoryHelpers.resolve_contributors_between(site, repository, prev_sha, rc.revparse('HEAD')).each do |contrib|
        i = c.contributors.index {|n| n.email == contrib.email}
        if i.nil?
          c.contributors << contrib
        else
          c.contributors[i].commits += contrib.commits
        end
      end

      # we can be pretty sure we'll have at least one commit, otherwise why the repository ;)
      last = rc.log(1).path(repository.relative_path).first
      c.last_commit = OpenStruct.new({
        :author => last.author,
        :date => last.date,
        :message => last.message,
        :sha => last.sha,
        :html_url => RepositoryHelpers.build_commit_url(repository, last.sha, 'html'),
        :json_url => RepositoryHelpers.build_commit_url(repository, last.sha, 'json')
      })
      c.unreleased_commits = RepositoryHelpers.resolve_commits_between(repository, prev_sha, rc.revparse('HEAD')).size

      c.modules = []
      site.components[repository.path] = c
    end

    def resolve_name(repository)
      pom = load_root_head_pom(repository)
      name = pom.root.text('name')
      # FIXME note misspelling of Aggregator in Drone extension
      name.nil? ? repository.path : name.gsub(/[ :]*(Aggregator|Agreggator|Parent|module)+/, '')
    end

    def resolve_group_id(repository)
      pom = load_root_head_pom(repository)
      pom.root.text('groupId') || pom.root.elements['parent'].text('groupId')
    end

    def resolve_head_version(repository)
      pom = load_root_head_pom(repository)
      pom.root.text('version')
    end

    # QUESTION should we track lead by release version? (for historical reasons)
    def resolve_current_lead(repository, component_leads)
      if !component_leads.nil? and component_leads.has_key? repository.path
        lead = component_leads[repository.path]
      else
        lead = nil
        pom = load_root_head_pom(repository)
        pom.each_element('/project/developers/developer') do |dev|
          # capture first developer as fallback lead
          if lead.nil? and !dev.text('email').nil?
            lead = OpenStruct.new({:name => dev.text('name'), :email => dev.text('email').downcase})
          end

          if !dev.elements['roles'].nil?
            if !dev.elements['roles'].elements.find { |role| role.name.eql? 'role' and role.text =~ / Lead/ }.nil?
              lead = OpenStruct.new({:name => dev.text('name'), :email => dev.text('email').downcase})
              break
            end
          end
        end
        if lead.nil?
          # FIXME parameterize (keep in mind the JIRA extension hits most of the leads)
          if repository.path.eql? 'jboss-as' or repository.path.eql? 'wildfly'
            lead = OpenStruct.new({
              :name => 'Jason T. Greene',
              :jboss_username => 'jason.greene'
            })
          elsif repository.path.eql? 'plugin-arquillian'
            lead = OpenStruct.new({
              :name => 'Paul Bakker',
              :jboss_username => 'pbakker'
            })
          elsif repository.path.eql? 'arquillian-graphene'
            lead = OpenStruct.new({
              :name => 'Lukáš Fryč',
              :jboss_username => 'lfryc'
            })
          elsif repository.owner.eql? 'arquillian'
            lead = OpenStruct.new({
              :name => 'Aslak Knutsen',
              :jboss_username => 'aslak'
            })
          elsif repository.path.eql? 'tomee'
            lead = OpenStruct.new({
              :name => 'David Blevins',
              :jboss_username => 'dblevins'
            })
          end
        end
        # update the global index (why not?)
        if !lead.nil?
          component_leads[repository.path] = lead
        end
      end
      lead
    end

    def resolve_dep_versions(repository, rev)
      rc = repository.client
      versions = {}
      # FIXME Android extension defines versions in android-bom/pom.xml
      ['pom.xml', 'build/pom.xml', 'android-bom/pom.xml', "#{repository.relative_path}pom.xml"].each do |path|
        # skip if path is not present in this revision
        next if rc.log(1).object(rev).path(path).size.zero?

        pom = REXML::Document.new(rc.cat_file(rc.revparse("#{rev}:#{path}")))
        pom.each_element('/project/properties/*') do |prop|
          if (prop.name.start_with? 'version.' or prop.name.end_with? '.version') and
              not prop.name =~ /[\._]plugin$/ and
              not prop.name =~ /\.maven[\._]/
            versions[prop.name.sub(/\.?version\.?/, '').gsub('.', '_')] = prop.text
          end
        end
      end
      versions
    end

    def resolve_published_artifacts(sitedir, repository, release)
      rc = repository.client
      rc.checkout(release.sha)
      if File.exist? File.join(repository.clone_dir, 'pom.xml')
        artifacts = `cd #{repository.clone_dir} && #{sitedir}/_bin/list-reactor-artifacts`.split("\n")
        release.published_artifacts = artifacts.map{|a| Artifact::Coordinates.parse a}.sort_by{|a| a.artifactId}
      end
      rc.checkout(repository.master_branch)
    end

    def load_root_head_pom(repository)
      @root_head_pom ||= REXML::Document.new(
        repository.client.cat_file(repository.client.revparse("HEAD:#{repository.relative_path}pom.xml"))
      )
    end
  end

end
