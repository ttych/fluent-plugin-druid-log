# frozen_string_literal: true

require 'fluent/plugin/filter'

module Fluent
  module Plugin
    class FormatDruidAuditLog2Filter < Fluent::Plugin::Filter
      NAME = 'format_druid_audit_log_2'
      Fluent::Plugin.register_filter(NAME, self)

      helpers :event_emitter, :timer

      DEFAULT_QUERY_KEY = 'query'
      DEFAULT_QUERY_RESULT_KEY = 'query_result'

      desc 'Query key'
      config_param :query_key, :string, default: DEFAULT_QUERY_KEY
      desc 'Query result key'
      config_param :query_result_key, :string, default: DEFAULT_QUERY_RESULT_KEY

      def configure(conf)
        super

        return unless query_key.nil? && query_result.nil?

        raise Fluent::ConfigError, 'query_key should be specified'
      end

      def multi_workers_ready?
        true
      end

      def filter(_tag, _time, record)
        new_record = format_record(record.dup)
        fix_record(new_record)
        new_record
      end

      def format_record(record)
        [query_key, query_result_key].each do |key|
          if record[key].is_a? String
            record[key] = record[key].size.positive? ? JSON.parse(record[key]) : {}
          end
        end

        query_type = guess_query_type(record)
        record['query_type'] = query_type

        record
      end

      def guess_query_type(record)
        record.dig(query_key,
                   'queryType') || (record.dig('query_result',
                                               'sqlQuery/time') && 'sql') || (record.dig(query_key,
                                                                                         'query') && 'sql') || 'unknown'
      end

      def fix_record(record)
        fix_record_query_granularity(record)
      end

      def fix_record_query_granularity(record)
        update_all_key_value(record['query'], 'granularity') do |value|
          value&.to_s
        end
      end

      def fix_record_query_match_value(record)
        update_all_key_value(record.dig('query', 'filter'), 'matchValue') do |value|
          value&.to_s
        end
      end

      def fix_record_query_datasource_rows(record)
        update_all_key_value(record.dig('query', 'dataSource'), 'rows') do |value|
          value&.to_s
        end
      end

      def update_all_key_value(record, key, &block)
        case record
        when Hash
          record.each do |rkey, rvalue|
            if rkey.to_s == key
              record[rkey] = yield(rvalue) if block_given?
              next
            end

            update_all_key_value(rvalue, key, &block)
          end
        when Array
          record.each do |item|
            update_all_key_value(item, key, &block)
          end
        end
      end
    end
  end
end
