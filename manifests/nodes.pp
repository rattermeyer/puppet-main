node 'ci-master' {
  include puppet
  network_config { 'eth1':
    ensure  => 'absent',
    family  => 'inet',
    method  => 'dhcp',
    onboot  => 'true',
    hotplug => 'true',
  }
  package { 'curl':
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
  mysql::db { 'sonar':
      user     => 'sonar',
      password => 'sonar',
      host     => '%.%.%.%',
      grant    => ['ALL'],
  }
  mysql::db { 'gitlabhq_production':
      user     => 'gitlab',
      password => 'password',
      host     => '%.%.%.%',
      grant    => ['ALL'],
      charset  => 'utf8',
      collate  => 'utf8_unicode_ci'
  }
  mysql_grant { 'gitlab@%.%.%.%': 
    ensure => 'present',
    privileges => ['ALL'],
    table      => 'gitlab.*',
    user       => 'gitlab@%.%.%.%',
  }
  mysql_grant { 'sonar@%.%.%.%': 
    ensure => 'present',
    privileges => ['ALL'],
    table      => 'sonar.*',
    user       => 'sonar@%.%.%.%',
  }
  file { ['/opt/gitlab', '/opt/gitlab/data'] :
    ensure  => 'directory',
  }->
  exec { 'docker-gitlab-firstrun' :
    require => File['/opt/gitlab'],
    command => "docker run --name=gitlab -i -t --rm -e \"DB_HOST=${ipaddress_eth0}\" -e \"DB_NAME=gitlabhq_production\" -e \"DB_USER=gitlab\" -e \"DB_PASS=password\" -v /opt/gitlab/data:/home/git/data sameersbn/gitlab:7.0.0 app:rake gitlab:setup force=yes",
    onlyif => "test -z `docker ps -a | grep gitlab`",
    timeout => 0
  }->
  exec { 'docker-normal-run' :
    onlyif => "test -n `docker ps -a | grep gitlab`",
    command => "docker run --name=gitlab -d -e \"DB_HOST=${ipaddress_eth0}\" -e \"DB_NAME=gitlabhq_production\" -e \"DB_USER=gitlab\" -e \"DB_PASS=password\" -e \"GITLAB_PORT=10080\" -e \"GITLAB_SSH_PORT=10022\" -e \"GITLAB_RELATIVE_URL_ROOT=/gitlab\" -p 127.0.0.1:10022:22 -p 127.0.0.1:10080:80 -v /opt/gitlab/data:/home/git/data sameersbn/gitlab:7.0.0",
    timeout => 0
  }
  class { '::java' : 
  }
  include profiles::jenkinsmaster
  Exec {
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin']
  }
  class{ '::nexus':
    version    => '2.8.0',
    revision   => '05',
    nexus_root => '/opt'
  }
  include profiles::sonar
#  sonarqube::plugin { 'sonar-build-breaker-plugin' :
#    groupid    => 'org.codehaus.sonar-plugins',
#    artifactid => 'sonar-build-breaker-plugin',
#    version    => '1.1',
#    require  => Class['maven::maven'],
#  }
#  sonarqube::plugin { 'sonar-build-stability-plugin' :
#    groupid    => 'org.codehaus.sonar-plugins',
#    artifactid => 'sonar-build-stability-plugin',
#    version    => '1.2',
#    require  => Class['maven::maven'],
#  }
#  sonarqube::plugin { 'sonar-groovy-plugin' :
#    groupid    => 'org.codehaus.sonar-plugins',
#    artifactid => 'sonar-groovy-plugin',
#    version    => '1.0.1',
#    require  => Class['maven::maven'],
#  }
#  sonarqube::plugin { 'sonar-javascript-plugin' :
#    groupid    => 'org.codehaus.sonar-plugins.javascript',
#    artifactid => 'sonar-javascript-plugin',
#    version    => '1.6',
#    require  => Class['maven::maven'],
#  }
#  sonarqube::plugin { 'sonar-branding-plugin' :
#    groupid    => 'org.codehaus.sonar-plugins',
#    artifactid => 'sonar-branding-plugin',
#    version    => '0.4',
#    require  => Class['maven::maven'],
#  }
  class { 'gradle':
    version => '1.12',
    require => Package['unzip']
  }
  Class['::java'] -> Class['::nexus']
  class { 'apache' :
    default_vhost => false
  }
  apache::vhost { 'ci-master' :
    port	   => 80,
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
  include 'docker'
  include devtools::core
  class { 'devtools::desktop' :
	desktop => 'ubuntu-desktop'
  }
  include javatools
  include javatools::apache_tomcat
  include javatools::jboss_wildfly
  include javatools::sts
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
