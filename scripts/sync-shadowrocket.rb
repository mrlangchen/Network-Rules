# frozen_string_literal: true
# Run with Ruby from any directory: ruby scripts/sync-shadowrocket.rb
require 'yaml'
require 'uri'

ROOT = File.expand_path('..', __dir__)
RAW = 'https://raw.githubusercontent.com/mrlangchen/Network-Rules/main'
AIRPORTS = { 'AIRPORT' => 'WgetCloud' }.freeze
ISP_GROUP = '🔗 ISP 链式代理'
ISP_NODE = '🏠 ISP 出口'
NATIVE_RULES = %w[DOMAIN DOMAIN-SUFFIX DOMAIN-KEYWORD DOMAIN-WILDCARD IP-CIDR IP-CIDR6 GEOIP].freeze
PROCESS_TYPES = %w[PROCESS-NAME PROCESS-PATH PROCESS-NAME-REGEX PROCESS-PATH-REGEX].freeze

def general
  via = '#proxy=' + URI::DEFAULT_PARSER.escape(ISP_NODE, /[^A-Za-z0-9_.~-]/)
  primary = "https://1.1.1.1/dns-query#{via}"
  secondary = "https://8.8.8.8/dns-query#{via}"
  <<~CONF
    # Network-Rules · iOS / Shadowrocket
    # 分流来源为同仓库 mihomo.yaml 与 rules/。修改源文件可重新生成本文件。
    # 首次设置：在首页将机场订阅备注设为 WgetCloud，添加本地 SOCKS5 节点「#{ISP_NODE}」。
    # 在 ISP 节点详情的「代理通过」中指定机场入口，并在首页选中 ISP 节点。
    # 首次启动若机场入口的域名解析依赖代理自身，请使用机场提供的入口 IP，并保留原 TLS/SNI 设置。
    [General]
    update-url = #{RAW}/Shadowrocket.conf
    bypass-system = false
    skip-proxy = localhost,127.0.0.1
    tun-excluded-routes = 127.0.0.0/8
    ipv6 = false
    prefer-ipv6 = false
    dns-server = #{primary},#{secondary}
    direct-dns-server = #{primary},#{secondary}
    fallback-dns-server = #{secondary}
    proxy-dns-server = #{primary},#{secondary}
    dns-direct-system = false
    dns-fallback-system = false
    dns-direct-fallback-proxy = false
    hijack-dns = 8.8.8.8:53,8.8.4.4:53,1.1.1.1:53,1.0.0.1:53,9.9.9.9:53,208.67.222.222:53,208.67.220.220:53,223.5.5.5:53,223.6.6.6:53,119.29.29.29:53,114.114.114.114:53
    private-ip-answer = true
    udp-policy-not-supported-behaviour = REJECT
    close-if-proxy-chain-missing = true

    [Proxy]
    # 节点认证资料保存在手机首页。

    [Proxy Group]
  CONF
end

def group_line(group)
  name, type = group.fetch('name'), group.fetch('type')
  members = group.fetch('proxies', []).dup
  providers = group.fetch('use', [])
  options =
    case type
    when 'select'
      if name == ISP_GROUP
        raise 'Review public ISP binding' unless members == ['REJECT'] && providers.empty?
        members = [ISP_NODE, 'REJECT']
      end
      members + providers
    when 'url-test'
      raise "Review provider membership: #{name}" unless members == ['REJECT'] && providers.size == 1
      [AIRPORTS.fetch(providers.first), 'use=true', "policy-regex-filter=#{group.fetch('filter')}",
       "url=#{group.fetch('url')}", "interval=#{group.fetch('interval')}", "tolerance=#{group.fetch('tolerance')}"]
    else
      raise "Unsupported group type: #{type}"
    end
  "#{name} = #{([type] + options).join(',')}"
end

def render_list(id, provider, policy)
  unless provider.values_at('type', 'behavior', 'format') == %w[http classical text]
    raise "Review rule provider format: #{id}"
  end
  url = provider.fetch('url')
  prefix = "#{RAW}/rules/"
  raise "Review rule provider URL: #{url}" unless url.start_with?(prefix)
  name = url.delete_prefix(prefix)
  raise "Invalid ruleset filename: #{name}" unless name.match?(/\A[\w.-]+\.list\z/)
  rows = File.readlines(File.join(ROOT, 'rules', name), chomp: true).map(&:strip)
             .reject { |s| s.empty? || s.start_with?('#') }

  return ["RULE-SET,#{url},#{policy}"] if rows.any? && rows.all? { |r| NATIVE_RULES.include?(r.split(',', 2).first) }

  # Mixed lists are inlined at their original position, so unsupported Mac rules
  # cannot invalidate an otherwise usable iOS ruleset.
  converted = rows.map do |row|
    kind, payload = row.split(',', 2)
    if NATIVE_RULES.include?(kind)
      value, option = payload.split(',', 2)
      raise "Unexpected rule option: #{row}" if option && option != 'no-resolve'
      [kind, value, policy, option].compact.join(',')
    elsif PROCESS_TYPES.include?(kind) || row.match?(/\AAND,\(\(PROCESS-NAME,[^(),]+\),\(DOMAIN,[^(),]+\)\)\z/)
      nil # A process-only rule, or an AND with an unobservable process, cannot match on iOS.
    elsif kind == 'DOMAIN-REGEX'
      # Only hostname-safe anchored patterns can be placed into a URL authority.
      unless payload.match?(/\A\^[a-z0-9\[\].+\\-]+\$\z/) && !payload.include?('\\')
        raise "Review hostname regex for iOS: #{payload}"
      end
      host = payload[1...-1]
      "URL-REGEX,^(?i:https?|wss?)://(?i:#{host})(?::[0-9]+)?(?:[/?#]|$),#{policy}"
    else
      raise "Unsupported rule in #{name}: #{row}"
    end
  end.compact
  ["# rules/#{name} → #{policy}"] + (converted.empty? ? ['# 本规则集当前只有进程条件，iOS 无可匹配项。'] : converted)
end

config = YAML.safe_load(File.read(File.join(ROOT, 'mihomo.yaml')), aliases: true)
groups = config.fetch('proxy-groups')
names = groups.map { |g| g.fetch('name') }
providers = groups.flat_map { |g| g.fetch('use', []) }.uniq
raise 'Duplicate group/provider name' unless (names + providers).uniq.size == names.size + providers.size
raise 'Missing local ISP group' unless names.include?(ISP_GROUP)

lines = [general.rstrip] + groups.map { |g| group_line(g) }
# One adapter represents the provider whose individual nodes Mihomo expands in the main selector.
providers.each { |id| lines << "#{id} = select,#{AIRPORTS.fetch(id)},use=true" }
lines.concat(['', '[Rule]'])
rules = config.fetch('rules')
rules.each_with_index do |rule, index|
  kind, id, policy, extra = rule.split(',')
  if kind == 'MATCH' && index == rules.size - 1 && policy.nil?
    raise "Unknown final policy: #{id}" unless (names + %w[DIRECT REJECT]).include?(id)
    lines << "FINAL,#{id}"
  elsif kind == 'RULE-SET' && !extra
    raise "Unknown rule policy: #{policy}" unless (names + %w[DIRECT REJECT]).include?(policy)
    lines.concat(render_list(id, config.fetch('rule-providers').fetch(id), policy))
  else
    raise "Review routing rule: #{rule}"
  end
end
raise 'Missing final rule' unless lines.last.start_with?('FINAL,')
lines.concat(['', '[Host]', 'localhost = 127.0.0.1'])
File.write(File.join(ROOT, 'Shadowrocket.conf'), lines.join("\n") + "\n")
