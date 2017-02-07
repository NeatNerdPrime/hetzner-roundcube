class roundcube::roundcubeweb (
  $apt_mirror                = $roundcube::params::apt_mirror,
  $confdir                   = $roundcube::params::confdir,
  $database_host             = $roundcube::params::database_host,
  $database_name             = $roundcube::params::database_name,
  $database_password         = $roundcube::params::database_password,
  $database_port             = $roundcube::params::database_port,
  $database_ssl              = $roundcube::params::database_ssl,
  $database_username         = $roundcube::params::database_username,
  $force_https               = $roundcube::params::force_https,
  $listen_addresses          = $roundcube::params::postgres_listen_address,
  $main_inc_php_erb          = $roundcube::params::main_inc_php_erb,
  $plugins                   = $roundcube::params::plugins,
  $reconfigure_command       = $roundcube::params::reconfigure_command,
  $roundcube_backend         = $roundcube::params::roundcube_backend,
  $roundcube_webserver       = $roundcube::params::roundcube_webserver,
  $spellcheck_engine         = $roundcube::params::spellcheck_engine,
  $spellcheck_languages      = $roundcube::params::spellcheck_languages
  ) inherits roundcube::params {

  $packagelist = ['roundcube', 'roundcube-core', 'roundcube-plugins']

  if $spellcheck_engine == 'aspell' {
    class { '::roundcube::spellchecker::aspell':
      languagelist => $spellcheck_languages
    }
  }

  apt::source { 'wheezy-backports':
    location => $apt_mirror,
    repos    => 'main',
  }

  apt::pin { 'roundcube':
    packages => 'roundcube*',
    priority => 1001,
    release  => 'wheezy-backports',
  }

  package { "roundcube-${roundcube_backend}":
    ensure  => installed,
  }

  package { $packagelist:
    ensure  => installed,
    require => Package["roundcube-${roundcube_backend}"],
  }

  #Set the defaults
  Ini_setting {
    path    => '/etc/dbconfig-common/roundcube.conf',
    ensure  => present,
    section => '',
    notify  => Exec['reconfigure_roundcube'],
    require => Package['roundcube-core'],
  }

  # TODO: figure out some way to make sure that the ini_file module is installed,
  #  because otherwise these will silently fail to do anything.

  ini_setting {'dbtype':
    setting => 'dbc_dbtype',
    value   => "'${roundcube_backend}'",
  }

  ini_setting {'dbuser':
    setting => 'dbc_dbuser',
    value   => "'${database_username}'",
  }

  ini_setting {'dbpass':
    setting => 'dbc_dbpass',
    value   => "'${database_password}';",
  }

  ini_setting {'dbname':
    setting => 'dbc_dbname',
    value   => "'${database_name}';",
  }

  ini_setting {'dbserver':
    setting => 'dbc_dbserver',
    value   => "'${database_host}';",
  }

  ini_setting {'dbport':
    setting => 'dbc_dbport',
    value   => "'${database_port}';",
  }

  ini_setting {'dbssl':
    setting => 'dbc_ssl',
    value   => "'${database_ssl}';",
  }

  exec { 'reconfigure_roundcube':
    refreshonly => true,
    command     => "${reconfigure_command} roundcube-core",
  }

  file { "${confdir}/main.inc.php":
    owner   => root,
    group   => www-data,
    mode    => '0640',
    content => template($main_inc_php_erb),
  }

}
