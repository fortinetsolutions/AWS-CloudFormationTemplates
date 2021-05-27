#!/usr/bin/env python
import os
import sys
sys.path.append('..')
import optparse
import base64
import json
from autoscale.fos_api import FortiOSAPI
__author__ = 'mwooten'


#
#
#
def main():
    #
    # parse the options
    #
    port = None

    parser = optparse.OptionParser(version='%prog version 1.0')
    parser.add_option('-i', '--ip', help='ip address')
    parser.add_option('-u', '--user', help='user')
    parser.add_option('-U', '--URL', help='callback URL')
    parser.add_option('-p', '--password', help='password')
    parser.add_option('-g', '--group_name', help='group name')
    parser.add_option('-P', '--admin_port', help='Override default admin port')

    (opts, args) = parser.parse_args()
    ip = opts.ip
    user = opts.user
    password = opts.password
    port = opts.admin_port
    url = opts.URL
    group = opts.group_name
    if port is None:
        port = 443
    api = FortiOSAPI(port)
    status = api.login(ip, user, password)
    print("After api.login status = %s" % status)
    if status == -1:
        return -2
    callback_url = url + "/" + "callback/" + group
    data = {
          "status": "enable",
          "role": "master",
          "sync-interface": "port1",
          "psksecret": group,
          "callback-url": callback_url
    }
    content = api.put(api='cmdb', path='system', name='auto-scale', data=data)
    response = json.loads(content)
    print("api.put(add member to autoscale): status = %s, http status = %s" %
          (response['status'], response['http_status']))
    return 0


if __name__ == "__main__":
    sys.exit(main())
