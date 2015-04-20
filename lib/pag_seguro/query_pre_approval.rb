module PagSeguro
  class QueryPreApproval < PreApprovalSearchResult

    def initialize(email, token, pre_approval_code)
      raise "Needs a pre approval code" if pre_approval_code.blank?
      raise "Needs an email" if email.blank?
      raise "Needs a token" if token.blank?
      @data = pre_approval_data(email, token, pre_approval_code)
    end

    def self.find(email, token, options={})
      url = PreApprovalSearchResult.pre_approvals_url

      pre_approvals_data = Nokogiri::XML(RestClient.get url, params: search_params(email, token, options))
      pre_approvals_data.css("preApprovalSearchResult").map do |pre_approval_xml|
        PreApprovalSearchResult.new(pre_approval_xml)
      end
    end

    def self.search_params(email, token, options={})
      params = {email: email, token: token}
      params[:initialDate], params[:finalDate] = parse_dates(options)
      params[:page] = options[:page] if options[:page]
      params[:maxPageResults] = options[:max_page_results] if options[:max_page_results]
      params
    end

    def self.parse_dates(options={})
      initial_date = (options[:initial_date] || Time.now - 1.day).to_time
      final_date   = (options[:final_date] || initial_date + 1.day).to_time

      raise "Invalid initial date. Must be bigger than 6 months ago" if initial_date < 6.months.ago
      raise "Invalid end date. Must be less than today" if final_date > Date.today.end_of_day
      raise "Invalid end date. Must be bigger than initial date" if final_date < initial_date
      raise "Invalid end date. Must not differ from initial date in more than 30 days" if (final_date.to_date - initial_date.to_date) > 30

      return initial_date.to_time.iso8601, final_date.to_time.iso8601
    end

    private
      def pre_approval_data(email, token, pre_approval_code)
        pre_approvals_url = "#{PreApprovalSearchResult.pre_approvals_url}/#{pre_approval_code}"
        super RestClient.get pre_approvals_url, params: {email: email, token: token}
      end
  end
end
