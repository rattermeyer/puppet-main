node 'ci-master' {
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

}
node 'ubuntu-trusty' {
  include puppet
  include sudo
  include timezone
  sudo::conf { 'dev':
    content => '%dev ALL=NOPASSWD:ALL'
  }
  include devtools::core
  class { 'devtools::desktop' :
	desktop => 'xubuntu-desktop'
  }
  include javatools
  include javatools::apache_tomcat
  include javatools::jboss_wildfly
#  include javatools::sts
  include javatools::squirrel
  include intellij
  intellij::plugin { 'AngularJS' :
	name => 'AngularJS'
  }
  intellij::plugin { 'sonar-intellij-plugin' :
	name => 'sonar-intellij-plugin',
	url	=> 'http://plugins.jetbrains.com/plugin/download?pr=idea\&updateId=15763'
  }
  intellij::plugin { 'lombok-plugin' :
	name => 'lombok-plugin',
	url	=> 'http://plugins.jetbrains.com/plugin/download?pr=idea\&updateId=15697'
  }
  include jstools
  include jstools::yeoman
  include nodejs
  include user::virtual
  include user::developers
  class { 'gvm' :   
    owner => 'dev',
    require => Class['user::developers'],
  }
  gvm::package { 'grails':
    version    => '2.3.7',
    is_default => true,
    ensure     => present, #default
    require    => Class['gvm'],
    timeout    => 600
  }
  gvm::package { 'groovy':
    version    => '2.2.2',
    is_default => true,
    ensure     => present, #default
    require    => Class['gvm'],
    timeout    => 600
  }
  file_line { 'maven_path' :
    path  => '/home/dev/.bashrc',
    line  => 'export PATH=${PATH}:/opt/apache-maven/current/bin'
  }	 
}
