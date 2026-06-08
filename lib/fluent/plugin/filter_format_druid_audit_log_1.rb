# frozen_string_literal: true

require 'fluent/plugin/filter'

module Fluent
  module Plugin
    class FormatDruidAuditLog1Filter < Fluent::Plugin::Filter
      NAME = 'format_druid_audit_log_1'
      Fluent::Plugin.register_filter(NAME, self)

      helpers :event_emitter, :timer

      DEFAULT_QUERY_KEY = 'query'

      desc 'Query key'
      config_param :query_key, :string, default: DEFAULT_QUERY_KEY

      def configure(conf)
        super

        return unless query_key.nil?

        raise Fluent::ConfigError, 'query_key should be specified'
      end

      def multi_workers_ready?
        true
      end

      def filter(_tag, _time, record)
        query_type = guess_query_type(record)

        new_record = record.except(query_key)
        new_record['query_type'] = query_type
        new_record["#{query_type}_query".downcase] = record[query_key]
        new_record
      end

      def guess_query_type(record)
        record.dig(query_key,
                   'queryType') || (record.dig('query_result',
                                               'sqlQuery/time') && 'sql') || (record.dig(query_key,
                                                                                         'query') && 'sql') || 'unknown'
      end
    end
  end
end
