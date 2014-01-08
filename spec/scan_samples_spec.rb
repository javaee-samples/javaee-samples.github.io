require 'ostruct'
require 'awestruct/util/inflector'

require_relative '../_ext/samples.rb'

describe SampleComponent do

  class Cloner 
    include Awestruct::Extensions::Repository::Visitors::Clone
  end

  class SampleVisitor 
    include SampleComponent
  end

  before :each do
    @visitor = SampleVisitor.new
    @site = OpenStruct.new
    @site.tmp_dir = '_tmp/'
    @site.repos_dir = '_tmp/repos'
    @site.modules = {}
    @site.component_leads = {}
    @site.git_author_index = {}
    @site.categories = []
    @repository = OpenStruct.new(
      :path => 'javaee7-samples',
      :desc => nil,
      :relative_path => './',
      :owner => 'javaee-samples',
      :host => 'github.com',
      :type => 'git',
      :html_url => 'https://github.com/javaee-samples/javaee7-samples',
      :clone_url => 'git://github.com/javaee-samples/javaee7-samples.git'
    )
  end

  def link_components_modules
    path = $1 if @repository.clone_url =~/.*\/(.*)\.git/
    @site.components = {
      path => OpenStruct.new(
        :modules => []
      )
    }
    @repository.path = path
  end

  it "should dicover sample modules" do
    link_components_modules
    Cloner.new().visit(@repository, @site)

    @visitor.visit(@repository, @site)
    #puts @site
  end

end