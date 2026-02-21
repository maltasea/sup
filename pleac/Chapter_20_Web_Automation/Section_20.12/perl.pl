
#-----------------------------
while (<LOGFILE>) {
  my ($client, $identuser, $authuser, $date, $time, $tz, $method,
      $url, $protocol, $status, $bytes) =
      /^(\S+) (\S+) (\S+) \[([^:]+):(\d+:\d+:\d+) ([^\]]+) "(\S+) (.*?) (\S+)" (\S+) (\S+)$/ or next;
  # ...
}
#-----------------------------

