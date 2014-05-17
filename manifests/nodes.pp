node 'ci-master' {
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
    "mail-ext" : ;
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
