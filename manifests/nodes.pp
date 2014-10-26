  include puppet
  Exec {
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin']
  }
  package { 'curl':
  }
  class { '::java' : 
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
