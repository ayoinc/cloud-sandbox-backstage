#
# Cookbook:: environment
# Recipe:: default
#
# Provisions the ${{ values.name }} VM.

package %w(curl ca-certificates git)
{%- if values.install_docker %}

execute 'install-docker' do
  command 'curl -fsSL https://get.docker.com | sh'
  creates '/usr/bin/docker'
end

group 'docker' do
  members ['vagrant']
  append true
  action :modify
end
{%- endif %}
{%- if values.install_k3s %}

execute 'install-k3s' do
  command 'curl -sfL https://get.k3s.io | sh -'
  creates '/usr/local/bin/k3s'
end
{%- endif %}
