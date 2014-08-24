  include puppet
  network_config { 'eth1':
    ensure  => 'absent',
    family  => 'inet',
    method  => 'dhcp',
    onboot  => 'true',
    hotplug => 'true',
  }
  Exec {
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin']
  }
  package { 'curl':
  }
  class { '::java' : 
  }
  class { '::mysql::server':
    root_password    => 'pleasechange',
    override_options => { 
      'mysqld' => { 
	'max_connections' => '1024', 
        'bind_address'    => "${ipaddress_eth0}"
       } 
    }
  }
  class { '::mysql::client' :
    package_ensure => 'present'
  }
  include profiles::gitlab
  include profiles::jenkinsmaster
  include profiles::sonar
  Class['::java'] -> Class['::nexus']
  class{ '::nexus':
    version    => '2.8.1',
    revision   => '01',
    nexus_root => '/opt'
  }
  class { 'gradle':
    version => '1.12',
    require => Package['unzip']
  }
  class { 'apache' :
    default_vhost => false
  }
  apache::vhost { 'ci-master' :
    port	   => 1080,
    default_vhost  => true,
    docroot	   => '/var/www/default',
    proxy_pass     => [
      { 'path' => '/nexus', 'url' => 'http://localhost:8081/nexus' },
      { 'path' => '/sonar', 'url' => 'http://localhost:9000/sonar' },
      { 'path' => '/jenkins', 'url' => 'http://localhost:8080/jenkins' },
      { 'path' => '/gitlab', 'url' => 'http://127.0.0.1:10080/gitlab/' },
    ],
  }

