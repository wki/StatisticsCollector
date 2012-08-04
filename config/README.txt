Configuration files
-------------------

all config files may exist in several variations:
 - main config file
 - overridden settings for a special usage
   (dev, staging, live, test or a developer)
 - overridden settings for a given host name
 - combination of hostname and usage

hostname configs are resolved during deployment to a given host name
and will get copied to the same filename without the host name



statisticscollector.pl              main config file for catalyst
statisticscollector_xxx.pl          overrides config directives


server/                             nginx, starman etc.
  nginx.tpl                         Template for a nginx site
  init.d_starman.tpl                Template for an init.d script
  server.pl                         main config file for generating init.d
  server_xxx.pl                     overrides config directives

