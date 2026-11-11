# Provisions the ${{ values.name }} VM.
package { ['curl', 'ca-certificates', 'git']:
  ensure => installed,
}
{%- if values.install_docker %}

exec { 'install-docker':
  command  => 'curl -fsSL https://get.docker.com | sh',
  creates  => '/usr/bin/docker',
  path     => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  provider => shell,
  require  => Package['curl'],
}

user { 'vagrant':
  groups     => ['docker'],
  membership => minimum,
  require    => Exec['install-docker'],
}
{%- endif %}
{%- if values.install_k3s %}

exec { 'install-k3s':
  command  => 'curl -sfL https://get.k3s.io | sh -',
  creates  => '/usr/local/bin/k3s',
  path     => ['/usr/local/sbin', '/usr/local/bin', '/usr/sbin', '/usr/bin', '/sbin', '/bin'],
  provider => shell,
  require  => Package['curl'],
}
{%- endif %}
