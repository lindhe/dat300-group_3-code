#!/usr/bin/python3.5
# -*- coding: utf-8 -*-
#
# License: MIT
# Author: Andreas Lindhé

import sys
import time
import psutil
from datetime import datetime as dt


log = []

def main(filepath="/tmp/sysinfo.log", log_interval=10, write_interval=600):
  global log
  while True:
    for i in range(write_interval//log_interval):
      log.append( get_log_data() )
      time.sleep( log_interval )
    write_to_file(filepath)
    log = []


def get_log_data():
  now = "{:%Y-%m-%d %H:%M:%S};".format( dt.now() )
  cpu = psutil.cpu_percent(percpu=True, interval=1)
  cpufmt = len(cpu) * ' {:>5}'
  cores = cpufmt.format(*cpu) + ';'
  ram = str( psutil.virtual_memory().percent )+';'
  boot_time = "{:%Y-%m-%d %H:%M:%S};".format( dt.fromtimestamp(psutil.boot_time()) )
  return " ".join([now, cores, ram, boot_time])


def write_to_file(filepath="/tmp/asdf.log"):
  try:
    with open(filepath, 'a') as f:
      for line in log:
        f.write(line + '\n')
  except OSError as e:
    print("Error reading file {}: {}".format(filepath, e), file=sys.stderr)

if __name__ == '__main__':
  program = sys.argv[0]
  if len(sys.argv) == 2:
    filepath = sys.argv[1]
    log_interval = 10
    write_interval = 60
  elif len(sys.argv) == 4:
    filepath = sys.argv[1]
    log_interval = int(sys.argv[2])
    write_interval = int(sys.argv[3])
  else:
    print("Usage: {} /path/to/file [log_interval] [write_interval]")
    print("log_interval is the time in seconds between each log line")
    print("write_interval is the time in seconds between each write")
    sys.exit(1)

  try:
    main(filepath, log_interval, write_interval)
  except KeyboardInterrupt:
    sys.stderr.write("Interrupted\n")
    sys.exit(0)
