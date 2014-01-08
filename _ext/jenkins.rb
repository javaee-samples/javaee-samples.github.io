module Awestruct::Extensions::Jenkins

  API_URL = "%s/api/json?pretty"
  TEST_RESULTS = "%s/lastCompletedBuild/testReport/api/json?pretty"
  
  class Jobs
    DURATION_1_DAY = 60 * 60 * 24

    def initialize(base_url)
      @base_url = base_url
    end

    def execute(site)

      site.results = []

      jobs_overview_url = API_URL % [@base_url]
      jobs_overview = RestClient.get jobs_overview_url, :accept => 'application/json', :cache_expiry_age => DURATION_1_DAY
      jobs_overview['jobs'].select{|j|j['name'] =~ /.*Samples on.*/}.each do |job| 
        
        container = OpenStruct.new
        site.results << container
        if job['name'] =~ /.*Samples on (.+)\-cb.*/
          container.name = $1 
        else 
          return #ignore unknown name pattern
        end

        container.tests = []

        result_url = TEST_RESULTS % [job['url']]
        result = RestClient.get result_url, :accept => 'application/json', :cache_expiry_age => DURATION_1_DAY

        result['suites'].each do |suite|
          suite['cases'].each do |c|
            
            #puts "#{c['className']}-#{c['name']}"

            test = OpenStruct.new
            test.name = c['name']
            test.status = c['status']
            container.tests << test

          end
        end
      end

      #puts site.results
    end

  end
end
