  include puppet
  Exec {
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin']
  }
  package { 'curl':
  }
  class { '::java' : 
  }
  include profiles::jenkinsmaster
  include ssh::client
