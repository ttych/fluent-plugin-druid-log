# fluent-plugin-druid-log

[Fluentd](https://fluentd.org/) plugin for Apache Druid.

## plugins

### format-druid-audit-log-1 (filter)

Filter plugin to reformat Druid audit log.

Restructure by query_type :
- when query_type is sql, query content will be in sql_query key
- when query_type is scan, query content will be in scan_query key
- when query_type is groupBy, query content will be in groupby_query key
- ...

Example:

``` text
<source>
  @type tail
  path /.../log/audit.log
  pos_file /.../audit_log.pos
  read_from_head true
  tag druid_audit_log

  <parse>
    @type regexp
	expression /^(?<timestamp>[^\t]+)\t(?<remote_addr>[^\t]*)\t{1,2}(?<query_result>[^\t]+)\t(?<query>.*)$/
	time_key timestamp
	keep_time_key true
  </parse>
</source>

<filter druid_audit_log>
  @type format_druid_audit_log_1
</filter>

<match druid_audit_log>
  @type stdout
</match>
```


### format-druid-audit-log-2 (filter)

Filter plugin to reformat Druid audit log.

The query content is under the query key.

Some key are serialized to string to avoid type change problems :
- matchValue under filter is serialized to string
- granularity is serialized to string

Example:

``` text
<source>
  @type tail
  path /.../log/audit.log
  pos_file /.../audit_log.pos
  read_from_head true
  tag druid_audit_log

  <parse>
    @type regexp
	expression /^(?<timestamp>[^\t]+)\t(?<remote_addr>[^\t]*)\t{1,2}(?<query_result>[^\t]+)\t(?<query>.*)$/
	time_key timestamp
	keep_time_key true
  </parse>
</source>

<filter druid_audit_log>
  @type format_druid_audit_log_2
</filter>

<match druid_audit_log>
  @type stdout
</match>
```


## Installation

### RubyGems

```
$ gem install fluent-plugin-druid-log
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-druid-log"
```

And then execute:

```
$ bundle
```

## Copyright

* Copyright(c) 2026- Thomas Tych
