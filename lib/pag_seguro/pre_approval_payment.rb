module PagSeguro
  class PreApprovalPayment
    include ActiveModel::Validations
    extend PagSeguro::ConvertFieldToDigit

    attr_accessor :id, :email, :token, :items, :response, :preApprovalCode
    alias :reference  :id
    alias :reference= :id=

    validates_presence_of :email, :token

    def initialize(email = nil, token = nil, options = {})
      @email           = email unless email.nil?
      @token           = token unless token.nil?
      @id              = options[:id] || options[:reference]
      @items           = options[:items] || []
      @preApprovalCode = options[:preApprovalCode]
    end

    def self.payment_url
      PagSeguro::Url.api_url("/pre-approvals/payment/")
    end

    def pre_approval_payment_xml
      xml_content = File.open( File.dirname(__FILE__) + "/pre_approval_payment.xml.haml" ).read
      haml_engine = Haml::Engine.new(xml_content)

      haml_engine.render Object.new,
                         items: @items,
                         payment: self
    end

    def payment_url
      self.class.payment_url
    end

    def code
      response || parse_payment_response
      parse_code
    end

    def date
      response || parse_payment_response
      parse_date
    end

    def reset!
      @response = nil
    end

    def send_payment
      params = { email: @email, token: @token, ssl_version: :SSLv3 }

      RestClient.post(payment_url, pre_approval_payment_xml,
        params: params,
        content_type: "application/xml"){|resp, request, result| resp }
    end

    protected
      def valid_items
        if items.blank? || !items.all?(&:valid?)
          errors.add(:items, " must be all valid")
        end
      end

      def parse_payment_response
        res = send_payment
        raise Errors::Unauthorized if res.code == 401
        raise Errors::InvalidData.new(res.body) if res.code == 400
        raise Errors::UnknownError.new(res) if res.code != 200
        @response = res.body
      end

      def parse_date
        DateTime.iso8601(Nokogiri::XML(response.body).css("result date").first.content)
      end

      def parse_code
        Nokogiri::XML(response.body).css("result transactionCode").first.content
      end
  end
end
