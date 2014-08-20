require 'rubygems'
require 'git'
require 'ostruct'
require 'rexml/document'

require_relative 'javadoc'
require_relative 'javaeesamples'

require File.join File.dirname(__FILE__), 'tweakruby'

# Monkey-Pacth the JavaDoc DocletAPI to Expose the underlying parsed Java Source
ProgramElementDocImpl = com.sun.tools.javadoc.ProgramElementDocImpl
class ProgramElementDocImpl
    field_accessor :tree
end

class SampleExtension

    def execute(site)
        site.showcases = []
        site.showcases.extend(Locators)

        site.modules["sample"].each do |val|
            next if val.name =~ /.*(parent|aggregator).*/i

            page = site.engine.load_site_page('sample/_sample.html.slim')
            page.output_path = "/sample/#{val.module_name}.html"
            page.title = val.name.nil? ? val.module_name : val.name
            puts "Created Showcase #{val.module_path} #{val.name}"
            page.showcase = val

            site.showcases << page
        end

        site.pages.concat(site.showcases)
    end

    module Locators

        def usage_by_category_id(id)
            self.select{ |v|
                !v.showcase.api_usage.nil? and !v.showcase.api_usage[id].nil?
            }.sort { |v|
                v.showcase.api_usage[id]
            }
        end
        def by_category_id(id)
            self.select{ |v|
                !v.showcase.category.nil? and v.showcase.category.id.eql? id
            }
        end
    end
end



module SampleComponent
    include Awestruct::Extensions::Repository::Visitors::Base

    JAVA_SRC_DIR = "src/main/java"
    JAVA_SRC_RESOURCE_DIR = "src/main/resources"
    JAVA_TEST_DIR = "src/test/java"
    JAVA_TEST_RESOURCE_DIR = "src/test/resources"

    def handles(repository)
      repository.path.eql? "javaee7-samples"
    end

    def visit(repository, site)
        
        rc = repository.client
        c = site.components[repository.path]
        c.type = "sample"
        c.type_name = c.type.humanize.titleize
        if site.modules[c.type].nil?
            site.modules[c.type] = []
        end

        showcase_mods = {}


        rev = "HEAD:"
        Awestruct::Extensions::Repository::Visitors::MavenHelpers.traverse_modules(rev, repository) {
            |path, pom|

            next if path.eql? rev
            next if is_module_pom(pom)

            module_path = path.gsub(/.*:/, '')
            module_name = module_path.gsub("/", "-").chop # chop of last / converted to -

            showcase_mods[module_name] = OpenStruct.new if showcase_mods[module_name].nil?
            mod = showcase_mods[module_name]
            mod.repository = repository
            #next unless module_name.eql? "websocket-whiteboard"
            puts "#{module_name} => #{module_path}"
            mod.module_name = module_name
            mod.module_path = module_path if mod.module_path.nil?
            mod.category = locate_category(site.categories, module_path)

            mod.changes = []
            rc.log(10).path(module_path).each do |c|
                mod.changes << OpenStruct.new({
                    "author" => c.author.name,
                    "date" => c.author.date,
                    "message" => c.message.split(/\n/)[0].chomp('.').capitalize
                })
            end

            mod.contributors = []

            # TMP Hack to resolve sub path
            orig_path = repository.relative_path
            repository.relative_path = "#{repository.relative_path}#{mod.module_path}"
            # Keep in mind we don't want to recount these commits
            Awestruct::Extensions::Repository::Visitors::RepositoryHelpers.resolve_contributors_between(
                site, repository, nil, rc.revparse('HEAD'), false).each {
                |contributor|
                    mod.contributors << contributor
            }

            repository.relative_path = orig_path

            parse_pom(mod, pom) 
            mod.name = generate_name(module_path) if mod.name.nil?

            mod.tests ||= []
            mod.sources ||= []
            
            src_dir = "#{repository.clone_dir}/#{module_path}/#{JAVA_SRC_DIR}"
            src_resource_dir = "#{repository.clone_dir}/#{module_path}/#{JAVA_SRC_RESOURCE_DIR}"
            test_dir = "#{repository.clone_dir}/#{module_path}/#{JAVA_TEST_DIR}"
            test_resource_dir = "#{repository.clone_dir}/#{module_path}/#{JAVA_TEST_RESOURCE_DIR}"

            extract_source = Proc.new{ |file|
                next if file =~ /$\.java/
                next unless File.file? file

                source = OpenStruct.new
                source.name = File.basename(file)
                source.content = File.read(file).gsub(/<!--.*?-->/m, '').strip
                source.path = file.gsub("#{repository.clone_dir}/#{module_path}/", '')
                mod.sources << source
            }

            Dir.glob("#{src_resource_dir}/**/*").each &extract_source
            Dir.glob("#{test_resource_dir}/**/*").each &extract_source

            Java::Doc.parse src_dir do |root| 
                root.classes.each do |c|

                    next if c.is_abstract?
                    source = OpenStruct.new
                    source.name = c.name
                    source.qualified_name = c.qualifiedTypeName
                    source.description = c.commentText.split("\n").collect{|x|x.lstrip}.join("\n")

                    # TODO: this will reformat the code.
                    # Look for better option to strip down to pure code
                    source.content = c.tree.to_s

                    source.children ||= []

                    if c.position.file.path =~ Regexp.new(".*" + Regexp.escape("#{repository.path}") + "/(.*)")
                        source.path = $1
                    end
                    #file_content = rc.cat_file("#{rev}#{source.path}")
                    file_content = File.read("#{c.position.file.path}")
                    parse_imports(site.categories, mod, file_content)

                    c.methods.each do |m|
                        source.children << extract_method(m, file_content, true)
                    end

                    mod.sources << source
                end
            end

            Java::Doc.parse test_dir do |root| 
                root.classes.each do |c|
                    next unless c.name =~ /(TestCase|Test)$/
                    
                    test = OpenStruct.new
                    test.name = c.name
                    test.qualified_name = c.qualifiedTypeName
                    test.description = c.commentText.split("\n").collect{|x|x.lstrip}.join("\n")

                    test.children ||= []

                    if c.position.file.path =~ Regexp.new(".*" + Regexp.escape("#{repository.path}") + "/(.*)")
                        test.path = $1
                    end
                    #file_content = rc.cat_file("#{rev}#{test.path}")
                    file_content = File.read("#{c.position.file.path}")
                    parse_imports(site.categories, mod, file_content)

                    c.methods.each do |m|

                        is_deployment = !m.annotations.find{
                                |x| 
                                x.annotationType.qualifiedTypeName.eql? 'Deployment'
                            }.nil?

                        is_test = !m.annotations.find{
                                |x| 
                                x.annotationType.qualifiedTypeName.eql? 'Test'
                            }.nil?

                        method = extract_method(m, file_content, true)
                        method.is_deployment = is_deployment
                        method.is_test = is_test

                        test.children << method
                    end
                
                    mod.tests << test

                end
            end

        }

        c.modules << showcase_mods.values
        site.modules[c.type].concat showcase_mods.values
    end

    def extract_method(m, file_content, with_content = false)
        method = OpenStruct.new
        method.name = m.name
        method.description = m.commentText.split("\n").collect{|x|x.lstrip}.join("\n")
        if with_content
            method.start_pos = m.tree.start_position
            method.end_pos = calculate_block_end_pos(method.start_pos, method.name, file_content)
            method.content = reposition_content(file_content[method.start_pos, method.end_pos - method.start_pos])
        end
        return method
    end

    def calculate_block_end_pos(start, method_name, file_content)
        #puts "Start #{start} #{method_name} #{file_content.size}: #{file_content[start, 2]}"
        if start >= file_content.size
            return start # JavaDoc running wild,  bad formatting.. abort
        end
        scanner = StringScanner.new file_content
        scanner.pos = start
        scanner.scan_until Regexp.new(Regexp.escape(method_name))

        block_pos = scanner.pos
        inside_comment = 0
        inside = false
        level = 0
        curr = 0
        while true
            curr += 1
            curr_char = file_content[block_pos + curr, 1]
            inside_comment += 1 if curr_char.eql? "/"
            if(curr_char.eql? "\n")
                inside_comment = 0
            end
            unless inside_comment >= 2
                inside = true if curr_char.eql? "{"
                level += 1 if curr_char.eql? "{"
                level -= 1 if curr_char.eql? "}"
            end
            #puts "#{level} #{curr} #{curr_char}"
            break if level == 0 and inside
            #raise "Out of level, level #{level} - curr #{curr} - char #{curr_char}\n #{file_content[start, block_pos+curr]}" if level < 0
            break if level < 0
        end

        block_pos+curr+1
    end

    # Remove white space in beginning of line to align all lines
    # 1. line is already at 0
    def reposition_content(content)
        return "" if content.nil?
        lines = content.split("\n")
        # Align method against the last line, probably } in source code
        padding = lines.last.index(/\S/)
        lines.collect.with_index{
            |line, i|
                x = line
                if i > 0
                    # only remove the padding if it's empty. Code formatting issues
                    padd = x[0..padding-1].strip
                    x = x[padding..-1] if padd.empty?
                end
                #puts "#{i} #{padding} #{x}"
                x
            }.join("\n")
    end

    def is_module_pom(pom)
        modules = pom.elements["/project/modules/module"]
        !modules.nil? and !modules.has_elements?
    end

    def locate_category(categories, module_path)
        cat_id = $1 if module_path =~ /([a-z]+)\/.*/
        categories.find{|v| v.id.downcase.eql? cat_id}
    end

    def generate_name(module_path)
        name = module_path
        name = $2 if name =~ /([a-z]+)\/(.*)/

        name.gsub(/\/|\-/, ' ').capitalize.strip
    end
    
    def parse_pom(mod, pom)
        mod.name = pom.root.text('name')
        mod.name = nil if mod.name =~ /^\$/ 
        mod.name.gsub!(/Arquillian Showcase.\s?/, "") unless mod.name.nil?
        mod.name.gsub!(":", " -") unless mod.name.nil?
        mod.description = pom.root.text('description')

        pom.root.each_element("profiles/profile/id") { |id|
            mod.profiles = [] if mod.profiles.nil?
            mod.profiles << id.text
        }
        mod.profiles.sort if !mod.profiles.nil?
    end

    def parse_imports(categories, mod, content)
        mod.api_usage = Hash.new if mod.api_usage.nil?
        
        content.scan(/^import (static )?(.+?);/) do |match|
            stmt = match[1]
            categories.each do |category| 
                category.packages.each do |package|
                    if stmt =~ Regexp.new("^" + Regexp.quote(package))
                        mod.api_usage[category.id] ||= 0
                        mod.api_usage[category.id] += 1
                        break
                    end

                end
            end
            #puts stmt unless known_apis.include? stmt
        end
    end

    def parse_testcase(mod, path, content)
        mod.tests = [] if mod.tests.nil?

        test = OpenStruct.new
        test.path = path
        test.name = path.match(/.*\/([A-Z][A-Za-z]+)\.java/)[1]
        test.content = content.match(/.*(package .*)/m)[1]
        test.content = content.gsub(/\/\*(?!\*).*Licensed.+?\*\//m, '') #remove /* xxx */ license headers
        if test.content =~/\/\*(.+?)\*\//m
            test.description = $1
            test.description.gsub!(/.?\*.?/, '')
        end
        test.content.gsub!(/\/\*.+?\*\//m, '') #remove /* comments */ license headers
        
        mod.tests << test
    end

    def initialize()
        @apis = {
            'Arquillian JUnit' => /^org.jboss.arquillian.junit/,
            'Arquillian TestNG' => /^org.jboss.arquillian.testng/,
            #'Arquillian Test' => /^org.jboss.arquillian.test/,
            #'Arquillian Container Test' => /^org.jboss.arquillian.container.test/,
            #'Arquillian Core' => /^org.jboss.arquillian.core/,
            #'Arquillian Config' => /^org.jboss.arquillian.config/,
            'Arquillian Ajocado' => /^org.jboss.arquillian.ajocado/,
            'Arquillian Graphene' => /^org.jboss.arquillian.graphene/,
            'Arquillian Drone' => /^org.jboss.arquillian.drone/,
            'Arquillian Persistence' => /^org.jboss.arquillian.persistence/,
            'Arquillian Spring' => /^org.jboss.arquillian.spring/,
            'Arquillian Extension' => /^org.jboss.arquillian.*(spi)/,
            'ShrinkWrap' => /^org.jboss.shrinkwrap.api/,
            'ShrinkWrap Resovler' => /^org.jboss.shrinkwrap.resolver/,
            'ShrinkWrap Descriptor' => /^org.jboss.shrinkwrap.descriptor/,
            'JSFUnit' => /^org.jboss.jsfunit/,
            'Infinispan' => /^org.infinispan/,
            'RestEasy' => /^org.jboss.resteasy/,
            'JUnit' => /^org.junit/,
            'TestNG' => /^org.testng/,
            'Fest' => /^org.fest/,
            'Selenium' => /^org.openqa.selenium/,
            'Spring JDBC' => /^org.springframework.jdbc/,
            'Spring JMS' => /^org.springframework.jms/,
            'Spring' => /^org.springframework.beans/,

            # Specs
            'AtInject' => /^javax.inject/,
            'CDI' => /^javax.enterprise/,
            'Servlet' => /^javax.servlet/,
            'Persistence' => /^javax.persistence/,
            'JSF' => /^javax.faces/,
            'OSGi' => /^org.osgi/,
            'EJB' => /^javax.ejb/,
            'JMS' => /^javax.jms/,
            'WebService' => /^javax.jws/,
            'Jsr250' => /^javax.annotation/,
            'JaxRS' => /^javax.ws.rs/,
            'Transaction' => /^javax.transaction/,
            'Validation' => /^javax.validation/,
            'Security' => /^java.security/
        }
    end
end