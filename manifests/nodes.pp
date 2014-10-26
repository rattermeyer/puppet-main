  include puppet
  Exec {
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin']
  }
  package { 'curl':
  }
  class { '::java' : 
  }
  class { 'docker' :
    extra_parameters => '--bip=172.17.42.1/16',
    dns => '172.17.42.1'
  }
  class { 'resolvconf':
    nameservers => ['172.17.42.1'],
    override_dhcp => true
  }
  crontab::job { 'heartbeat-skydns' :
    command => '/usr/local/bin/heartbeat.sh'
  }
  include profiles::jenkinsmaster
  include ssh::client
