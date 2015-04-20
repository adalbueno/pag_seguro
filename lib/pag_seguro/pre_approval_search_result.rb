# encoding: utf-8
require 'net/https'

module PagSeguro
  class PreApprovalSearchResult
    attr_accessor :data

    def self.pre_approvals_url
      PagSeguro::Url.api_url("/pre-approvals")
    end

    def initialize(pre_approval_xml)
      @data = pre_approvals_data(pre_approval_xml)
    end

    def preApprovals
      @data.css("preApprovals preApproval").map do |i|
        { 
          name: parse_pre_approval(i, "name"),
          code: parse_pre_approval(i, "code"),
          status: parse_pre_approval(i, "status"),
          reference: parse_pre_approval(i, "reference"),
          tracker: parse_pre_approval(i, "tracker"),
          charge: parse_pre_approval(i, "charge")
        }
      end
    end

    protected
      def pre_approvals_data(pre_approval_xml)
        pre_approval_xml.instance_of?(Nokogiri::XML::Element) ? pre_approval_xml : Nokogiri::XML(pre_approval_xml)
      end

      def parse_pre_approval(data, attribute)
        data.css(attribute).first.content
      end
  end
end
