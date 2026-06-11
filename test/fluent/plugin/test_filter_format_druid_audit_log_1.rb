# frozen_string_literal: true

require 'helper'
require 'json'
require 'fluent/plugin/filter_format_druid_audit_log_1'

class FormatDruidAuditLog1FilterTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  TEST_TIME = '2026-01-01T01:01:01.010Z'
  TEST_FLUENT_TIME = Fluent::EventTime.parse(TEST_TIME)

  BASE_CONF = %()

  sub_test_case 'conf' do
    test 'default conf' do
      driver = create_driver
      filter_instance = driver.instance

      assert filter_instance
      assert_equal 'query', filter_instance.query_key
      assert_equal 'query_result', filter_instance.query_result_key
    end
  end

  DRUID_QUERY_RESULT_1 = {
    'query/time' => 5,
    'success' => true,
    'identity' => 'druid-user'
  }.freeze

  DRUID_EVENT_BASE_1 = {
    'timestamp' => TEST_TIME,
    'remote_addr' => '11.12.13.14',
    'query_result' => DRUID_QUERY_RESULT_1
  }.freeze

  DRUID_SQL_QUERY_1 = {
    'query' => 'SELECT * FROM datasource',
    'context' => {
      'populateCache' => false,
      'sqlQueryId' => 'uuid-xxx',
      'useCache' => false,
      'queryId' => 'uuid-xxx'
    }
  }.freeze

  DRUID_GROUPBY_QUERY_1 = {
    'queryType' => 'groupBy',
    'dataSource' => {
      'type' => 'table',
      'name' => 'my_datasource'
    },
    'intervals' => {},
    'virtualColumns' => [],
    'granularity' => {},
    'dimensions' => [],
    'aggregations' => [],
    'limitSpec' => {}
  }.freeze

  DRUID_SCAN_QUERY_1 = {
    'queryType' => 'scan',
    'dataSource' => {
      'type' => 'table',
      'name' => 'my_datasource'
    },
    'intervals' => {},
    'resultFormat' => '',
    'filter' => {},
    'columns' => [],
    'context' => {
      'queryId' => 'uuid-xxx',
      'sqlQueryId' => 'uuid-xxx'
    },
    'columnTypes' => [],
    'granularity' => {},
    'legacy' => false
  }.freeze

  DRUID_TIMESERIES_QUERY_1 = {
    'queryType' => 'timeseries',
    'dataSource' => {
      'type' => 'table',
      'name' => 'my_datasource'
    },
    'intervals' => {},
    'filter' => {},
    'granularity' => 'TEN_MINUTE',
    'aggregations' => [],
    'context' => {
      'queryId' => 'uuid-xxx',
      'sqlQueryId' => 'uuid-xxx'
    }
  }.freeze

  DRUID_TIMESERIES_QUERY_2 = {
    'queryType' => 'timeseries',
    'dataSource' => {
      'type' => 'table',
      'name' => 'my_datasource'
    },
    'intervals' => {},
    'filter' => {},
    'granularity' => {
      'type' => 'all'
    },
    'aggregations' => [],
    'context' => {
      'queryId' => 'uuid-xxx',
      'sqlQueryId' => 'uuid-xxx'
    }
  }.freeze

  sub_test_case 'can handle query in json format' do
    test 'it receives query in json format' do
      druid_sql_audit_log_event = DRUID_EVENT_BASE_1.merge('query' => DRUID_SQL_QUERY_1.to_json)

      processed_events = filter(BASE_CONF, [druid_sql_audit_log_event])
      assert_equal 1, processed_events.size

      processed_event = processed_events[0]
      expected_event = {
        'timestamp' => TEST_TIME,
        'remote_addr' => '11.12.13.14',
        'query_result' => DRUID_QUERY_RESULT_1,
        'query_type' => 'sql',
        'sql_query' => DRUID_SQL_QUERY_1
      }

      assert_equal expected_event, processed_event
    end

    test 'it receives query result in json format' do
      druid_sql_audit_log_event = DRUID_EVENT_BASE_1.merge(
        'query' => DRUID_SQL_QUERY_1.dup,
        'query_result' => DRUID_QUERY_RESULT_1.to_json
      )

      processed_events = filter(BASE_CONF, [druid_sql_audit_log_event])
      assert_equal 1, processed_events.size

      processed_event = processed_events[0]
      expected_event = {
        'timestamp' => TEST_TIME,
        'remote_addr' => '11.12.13.14',
        'query_result' => DRUID_QUERY_RESULT_1,
        'query_type' => 'sql',
        'sql_query' => DRUID_SQL_QUERY_1
      }

      assert_equal expected_event, processed_event
    end
  end

  sub_test_case 'format audit log' do
    test 'it should format sql query audit log' do
      druid_sql_audit_log_event = DRUID_EVENT_BASE_1.merge('query' => DRUID_SQL_QUERY_1.dup)

      processed_events = filter(BASE_CONF, [druid_sql_audit_log_event])
      assert_equal 1, processed_events.size

      processed_event = processed_events[0]
      expected_event = {
        'timestamp' => TEST_TIME,
        'remote_addr' => '11.12.13.14',
        'query_result' => DRUID_QUERY_RESULT_1,
        'query_type' => 'sql',
        'sql_query' => DRUID_SQL_QUERY_1
      }

      assert_equal expected_event, processed_event
    end

    test 'it should format groupby query audit log' do
      druid_groupby_audit_log_event = DRUID_EVENT_BASE_1.merge('query' => DRUID_GROUPBY_QUERY_1.dup)

      processed_events = filter(BASE_CONF, [druid_groupby_audit_log_event])
      assert_equal 1, processed_events.size

      processed_event = processed_events[0]
      expected_groupby_query = DRUID_GROUPBY_QUERY_1.merge('granularity' => '{}')
      expected_event = {
        'timestamp' => TEST_TIME,
        'remote_addr' => '11.12.13.14',
        'query_result' => DRUID_QUERY_RESULT_1,
        'query_type' => 'groupBy',
        'groupby_query' => expected_groupby_query
      }

      assert_equal expected_event, processed_event
    end

    test 'it should format scan query audit log' do
      druid_scan_audit_log_event = DRUID_EVENT_BASE_1.merge('query' => DRUID_SCAN_QUERY_1.dup)

      processed_events = filter(BASE_CONF, [druid_scan_audit_log_event])
      assert_equal 1, processed_events.size

      processed_event = processed_events[0]
      expected_scan_query = DRUID_SCAN_QUERY_1.merge('granularity' => '{}')
      expected_event = {
        'timestamp' => TEST_TIME,
        'remote_addr' => '11.12.13.14',
        'query_result' => DRUID_QUERY_RESULT_1,
        'query_type' => 'scan',
        'scan_query' => expected_scan_query
      }

      assert_equal expected_event, processed_event
    end

    test 'it should format timeseries query audit log 1' do
      druid_timeseries_audit_log_event = DRUID_EVENT_BASE_1.merge('query' => DRUID_TIMESERIES_QUERY_1.dup)

      processed_events = filter(BASE_CONF, [druid_timeseries_audit_log_event])
      assert_equal 1, processed_events.size

      processed_event = processed_events[0]
      expected_event = {
        'timestamp' => TEST_TIME,
        'remote_addr' => '11.12.13.14',
        'query_result' => DRUID_QUERY_RESULT_1,
        'query_type' => 'timeseries',
        'timeseries_query' => DRUID_TIMESERIES_QUERY_1
      }

      assert_equal expected_event, processed_event
    end

    test 'it should format timeseries query audit log' do
      druid_timeseries_audit_log_event = DRUID_EVENT_BASE_1.merge('query' => DRUID_TIMESERIES_QUERY_2.dup)

      processed_events = filter(BASE_CONF, [druid_timeseries_audit_log_event])
      assert_equal 1, processed_events.size

      processed_event = processed_events[0]
      expected_timeseries_query = DRUID_TIMESERIES_QUERY_2.merge('granularity' => '{"type" => "all"}')
      expected_event = {
        'timestamp' => TEST_TIME,
        'remote_addr' => '11.12.13.14',
        'query_result' => DRUID_QUERY_RESULT_1,
        'query_type' => 'timeseries',
        'timeseries_query' => expected_timeseries_query
      }

      assert_equal expected_event, processed_event
    end
  end

  private

  def create_driver(conf = BASE_CONF)
    Fluent::Test::Driver::Filter.new(Fluent::Plugin::FormatDruidAuditLog1Filter).configure(conf)
  end

  def filter(conf, events)
    d = create_driver(conf)
    d.run(default_tag: 'test') do
      events.each do |event|
        d.feed(event)
      end
    end
    d.filtered_records
  end
end
