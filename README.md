# StatisticsCollector #

a simple catalyst app for recording measures

We have sensors named like 'domain/location/sensor' that deliver values in
regular intervals. To keep the amount of data clean, every measure within ohe
hour will get aggregated into one record. This record holds the number of
measures, the minimum, maximum and sum of values.

Based on this (minimal) information, easy statistics are generated.

Also, some alarm conditions can be entered in order to allow notification in
case of unwanted values or lack of measures.

## TODO ##

* find a way to condense measurements into bigger time slices eg. 1 day, 1 week, ...
  add the necessary things into the model

* create filters in dashboard pages to shrink down all data presented

* DB Schema:

  $sensor->latest_measure->xxx_value
  $sensor->latest_measure->xxx_alarm
  $sensor->latest_measure->has_alarm

* alternative display to dashboard for mobile device

  +-----------------------------------+
  | [ erlangen v ]  [ temperature v ] |
  | +-------------------------------+ |
  | | 18:51      Aussen          15 | |
  | | 18:51      Waschkueche     10 | |
  ...

## Ideas for URIs ##

### REST-like thing for delivering/querying measures ###

* GET /sensor/ `<domain/location/sensor>`
  get latest value and timestamp for this sensor

* POST /sensor/ `<domain/location/sensor>`
  add a value (creating the sensor if not yet present)


### User interface ###

* GET /
  redirects to /dashboard

* GET /dashboard
  list all sensors with their values

* GET /admin
  simple admin dashboard offering a menu

* GET /admin/sensors
  list all sensors allow their creation and editing

* GET /admin/alarmconditions
  list all alarm conditions allow their creation and editing

