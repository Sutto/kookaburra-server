# Use Kookaburra::Settings or configatron

Kookaburra::Settings.host_name      = Socket.gethostname.split(/\./).shift
Kookaburra::Settings.max_nick_tries = 5 # Up to 5 tries
Kookaburra::Settings.port           = 6667
Kookaburra::Settings.verbose        = false
Kookaburra::Settings.log_level      = :info