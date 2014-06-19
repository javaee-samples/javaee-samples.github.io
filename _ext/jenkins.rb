module Awestruct::Extensions::Jenkins

  API_URL = "%s/api/json?pretty"
  TEST_RESULTS = "%s/lastCompletedBuild/testReport/api/json?pretty"
  
  class Jobs
    DURATION_1_DAY = 60 * 60 * 24

    def initialize(base_url)
      @base_url = base_url
    end

    def execute(site)

      site.results = OpenStruct.new
      site.results.extend(Locators)
      site.results.containers = []
      site.results.tests = {}

      jobs_overview_url = API_URL % [@base_url]
      jobs_overview = RestClient.get jobs_overview_url, :accept => 'application/json', :cache_expiry_age => DURATION_1_DAY
      jobs_overview['jobs'].select{|j|j['name'] =~ /.*Samples.on.*/i}.each do |job|
        
        container = nil
        if job['name'] =~ /.*Samples.on.([A-Za-z0-9 \.]+).*/i
          name = $1
          container = site.results.containers.find{|c|c.name.eql? name}
          if container.nil?
            container = OpenStruct.new
            container.name = $1
            site.results.containers << container
          end
        else 
          return #ignore unknown name pattern
        end

        result_url = TEST_RESULTS % [job['url']]
        result = nil
        begin
          result = RestClient.get result_url, :accept => 'application/json', :cache_expiry_age => DURATION_1_DAY
        rescue Exception => e
          puts "Could not download lastCompletedBuild for #{job['name']}"
          puts e.message
        end
        next if result.nil?

        result['suites'].each do |suite|
          suite['cases'].each do |c|

            class_name = c['className']
            test_name = c['name']

            test = site.results.tests[class_name]
            if test.nil?
              test = OpenStruct.new
              test.class_name = class_name
              test.children = {}
              site.results.tests[class_name] = test
            end

            method = test.children[test_name]
            if method.nil?
              method = OpenStruct.new
              method.name = test_name
              method.status = {}
              test.children[test_name] = method
            end

            method.status[container] = c['status']
          end
        end
      end

      #puts site.results
    end

    module Locators

      def summary_by_sample(sample)
        return {} if sample.tests.nil?
        a = sample.tests.map{
          |test|
          summary_by_testclass(test.qualified_name, test)
          }.inject{|a, b| a.merge(b) {|k, x, y| x and y}}
        return a
      end

      def summary_by_testclass(qualified_name, scenario)
        results = self.tests[qualified_name]
        return {} if results.nil?
        result = {}
        number_of_tests = scenario.children.select{|x| x.is_test}.size
        for value in results.children.each_value
          value.status.each{
            |k, v|
              result[k.name] ||= 0; result[k.name] +=1 if v.eql? "PASSED"
          }
        end
        result.each{|k, v| result[k] = v == number_of_tests ? true : false}
      end

    end
  end
end
