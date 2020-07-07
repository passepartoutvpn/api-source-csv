require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)
load("util.rb")

###

servers = File.read("../template/servers.json")
ca = File.read("../static/ca.crt")
client = File.read("../static/cert.crt")
client_key = File.read("../static/cert.key")
tls_wrap = read_tls_wrap("auth", 1, "../static/ta.key", 3, 19)

cfg = {
    ca: ca,
    cipher: "AES-128-GCM",
    auth: "SHA256",
    client: client,
    key: client_key,
    wrap: tls_wrap,
    frame: 1,
    eku: true
}

external = {
    hostname: "${id}.childsafevpn.com"
}

recommended_cfg = cfg.dup
recommended_cfg["ep"] = [
    "UDP:1194"
]
recommended = {
    id: "default",
    name: "Default",
    comment: "128-bit encryption",
    cfg: recommended_cfg,
    external: external
}

presets = [
    recommended
]

defaults = {
    :username => "UK123456",
    :pool => "GB",
    :preset => "recommended"
}

###

pools = []

json = JSON.parse(servers)
json["countries"].each { |country|
    code = country["code"].upcase

    country["cities"].each { |city|
        area = city["name"]

        city["relays"].each { |relay|
            id = relay["hostname"]
            hostname = "#{id.downcase}.childsafevpn.com"

            addresses = [relay["ipv4_addr_in"]]
            addresses.map! { |a|
                IPAddr.new(a).to_i
            }

            pool = {
                :id => id,
                :country => code,
                :hostname => hostname,
                :addrs => addresses
            }
            pool[:area] = area if !area.empty?
            pools << pool
        }
    }
}

###

infra = {
    :pools => pools,
    :presets => presets,
    :defaults => defaults
}

puts infra.to_json
puts
