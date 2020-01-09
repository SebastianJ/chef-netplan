require "yaml"

default_action :create

property :interface,            String,   name_attribute: true
property :renderer,             String,   default: 'networkd'
property :version,              Integer,  default: 2
property :addresses,            Array,    default: []

property :config_file,          String,   default: '/etc/netplan/60-static-ips.yaml'
property :template_cookbook,    String,   default: 'netplan'
property :template_source,      String,   default: '60-static-ips.yaml.erb'

action :create do
  if new_resource.addresses && new_resource.addresses.any?
    config = {
      network: {
        version: new_resource.version,
        renderer: new_resource.renderer,
        ethernets: {
          new_resource.interface.to_sym => {
            addresses: new_resource.addresses
          }
        }
      }
    }
  
    template new_resource.config_file do
      source    new_resource.template_source
      cookbook  new_resource.template_cookbook
      owner     'root'
      group     'root'
      mode      0755

      variables yaml: YAML.dump(config)
    end
  
    execute "apply netplan configuration" do
      command "netplan apply"
      user    "root"
    end
  end
end

action :delete do
  file new_resource.config_file do
    action :delete
    only_if { ::File.exists?(new_resource.config_file) }
  end
end