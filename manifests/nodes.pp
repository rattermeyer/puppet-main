node 'ci-master' {
  include puppet
  package { 'curl':
  }

  class { '::mysql::server':
    root_password    => 'pleasechange',
    override_options => { 'mysqld' => { 'max_connections' => '1024' } }
  }
  mysql_database { 'sonar':
    ensure  => 'present',
    charset => 'utf8',
    collate => 'utf8_unicode_ci',
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
#  class { 'gerrit' :
#  }
  class{ '::nexus':
    version    => '2.8.0',
    revision   => '05',
    nexus_root => '/opt'
  }
  $sonar_jdbc = {
    url               => 'jdbc:mysql://localhost:3306/sonar',
    username          => 'sonar',
    password          => 'sonar',
  }
  class { 'maven::maven' : } ~>
  class { 'sonarqube' :
    version      => '3.7.4',
    user         => 'sonar',
    group        => 'sonar',
    service      => 'sonar',
    installroot  => '/usr/local',
    home         => '/var/local/sonar',
    download_url => 'http://dist.sonar.codehaus.org',
    jdbc         => $sonar_jdbc,
    log_folder   => '/var/local/sonar/logs',
    updatecenter => true,
  }
  class { 'gradle':
    version => '1.12',
  }
  Class['::java'] -> Class['::nexus']
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
