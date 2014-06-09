node 'ci-master' {
  include puppet
  package { 'curl':
  }
  class { '::mysql::server':
    root_password    => 'pleasechange',
    override_options => { 
      'mysqld' => { 
	'max_connections' => '1024', 
	'bind-address' => "${ipaddress_eth0}",
       } 
    }
  }
  class { '::mysql::client' :
    package_ensure => 'present'
  }
  mysql::db { 'sonar':
      user     => 'sonar',
      password => 'sonar',
      host     => 'localhost',
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

  class { 'jenkins' :
    lts => true
  }
  jenkins::plugin {
    "git" : ;
  }  
  jenkins::plugin {
    "gitlab-hook" : ;
  }  
  jenkins::plugin {
    "delivery-pipeline-plugin" : ;
  } 
  jenkins::plugin {
    "maven-plugin" : ;
  } 
  jenkins::plugin {
    "gradle" : ;
  } 
  jenkins::plugin {
    "view-job-filters" : ;
  } 
  jenkins::plugin {
    "email-ext" : ;
  } 
  jenkins::plugin {
    "greenballs" : ;
  } 
  jenkins::plugin {
    "chucknorris" : ;
  } 
  jenkins::plugin {
    "jobConfigHistory" : ;
  } 
  jenkins::plugin {
    "shelve-project-plugin" : ;
  } 
  jenkins::plugin {
    "docker-plugin" : ;
  } 
  jenkins::plugin {
    "build-pipeline-plugin" : ;
  } 
  jenkins::plugin {
    "xvfb" : ;
  } 
  Exec {
    path => ['/bin', '/sbin', '/usr/bin', '/usr/sbin']
  }
  exec { 'jenkins-prefix' : 
    command => 'sed -i -e \'s/JENKINS_ARGS="\(.*\)"/JENKINS_ARGS="\1 --prefix=$PREFIX"/g\' /etc/default/jenkins',
    onlyif => 'test -z `grep "JENKINS_ARGS" /etc/default/jenkins | grep  "\-\-prefix"`'
  }
#  class { 'gerrit' :
#  }
  class{ '::nexus':
    version    => '2.8.0',
    revision   => '05',
    nexus_root => '/opt'
  }
  $sonar_jdbc = {
    url               => 'jdbc:mysql://127.0.0.1:3306/sonar',
    username          => 'sonar',
    password          => 'sonar',
  }
  class { 'sonarqube' :
    version      => '4.3',
    user         => 'sonar',
    group        => 'sonar',
    service      => 'sonar',
    installroot  => '/usr/local',
    home         => '/var/local/sonar',
    download_url => 'http://dist.sonar.codehaus.org',
    jdbc         => $sonar_jdbc,
    log_folder   => '/var/local/sonar/logs',
    updatecenter => true,
    context_path => '/sonar',
    require  => Class['maven'],
  }
  sonarqube::plugin { 'sonar-java-plugin' :
    groupid    => 'org.codehaus.sonar-plugins.java',
    artifactid => 'sonar-java-plugin',
    version    => '2.2.1',
    notify     => Service['sonar'],
    require  => Class['maven'],
  }
  sonarqube::plugin { 'sonar-motion-chart-plugin' :
    groupid    => 'org.codehaus.sonar-plugins',
    artifactid => 'sonar-motion-chart-plugin',
    version    => '1.6',
    notify     => Service['sonar'],
    require  => Class['maven'],
  }
  sonarqube::plugin { 'sonar-build-breaker-plugin' :
    groupid    => 'org.codehaus.sonar-plugins',
    artifactid => 'sonar-build-breaker-plugin',
    version    => '1.1',
    notify     => Service['sonar'],
    require  => Class['maven'],
  }
  sonarqube::plugin { 'sonar-build-stability-plugin' :
    groupid    => 'org.codehaus.sonar-plugins',
    artifactid => 'sonar-build-stability-plugin',
    version    => '1.2',
    notify     => Service['sonar'],
    require  => Class['maven'],
  }
  sonarqube::plugin { 'sonar-groovy-plugin' :
    groupid    => 'org.codehaus.sonar-plugins',
    artifactid => 'sonar-groovy-plugin',
    version    => '1.0.1',
    notify     => Service['sonar'],
    require  => Class['maven'],
  }
  sonarqube::plugin { 'sonar-javascript-plugin' :
    groupid    => 'org.codehaus.sonar-plugins.javascript',
    artifactid => 'sonar-javascript-plugin',
    version    => '1.6',
    notify     => Service['sonar'],
    require  => Class['maven'],
  }
  sonarqube::plugin { 'sonar-branding-plugin' :
    groupid    => 'org.codehaus.sonar-plugins',
    artifactid => 'sonar-branding-plugin',
    version    => '0.4',
    notify     => Service['sonar'],
    require  => Class['maven'],
  }
  class { 'gradle':
    version => '1.12',
  }
  Class['::java'] -> Class['::nexus']
  class { 'docker':
    use_upstream_package_source => false,
    manage_kernel => false
  }
  docker::image { 'sameersbn/gitlab': 
    image_tag => '6.9.2'
  }
  file { ['/opt/gitlab', '/opt/gitlab/data'] :
    ensure  => 'directory',
  }
  exec { 'docker-gitlab-firstrun' :
    require => [File['/opt/gitlab'], Docker::Image['sameersbn/gitlab']],
    command => "puppet:///docker-gitlab-firstrun.sh ${ipaddress_eth} gitlabhq_production gitlab password",
    creates => '/etc/docker-gitlab-firstrun.log'
  }
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
      { 'path' => '/gitlab', 'url' => 'http://127.0.0.1:10080/gitlab' },
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
  include javatools::apache_maven
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
