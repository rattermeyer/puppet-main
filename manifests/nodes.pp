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
  include profiles::jenkinsmaster
  include ssh::client
