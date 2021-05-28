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
    parser.add_option('-p', '--password', help='password')
    parser.add_option('-P', '--admin_port', help='Override default admin port')
    parser.add_option('-l', '--license', help='Override default license file (./fgt1-license.lic')
    (opts, args) = parser.parse_args()
    ip = opts.ip
    user = opts.user
    password = opts.password
    port = opts.admin_port
    if port is None:
        port = 443
    b64lic = base64.b64encode(open("/tmp/fgt1-license.lic").read().encode()).decode()
    api = FortiOSAPI(port)
    status = api.login(ip, user, password)
    print("After api.login status = %s" % status)
    if status == -1:
        return -2
    status = api.get(api='monitor', path='license', name='status')
    print("After api.get status = %s" % status)
    valid_api_get = True
    try:
        data = json.loads(status)
    except json.decoder.JSONDecodeError:
        license_valid = False
        valid_api_get = False
    if valid_api_get is True:
        if 'results' not in data or 'vm' not in data['results'] or 'valid' not in data['results']['vm']:
            return -2
        license_valid = data['results']['vm']['valid']
    if license_valid is False:
        print("This instance needs a license")
        b64lic = base64.b64encode(open("/tmp/fgt1-license.lic").read().encode()).decode()
        status = api.post(api='monitor', path='system', name='vmlicense', action='upload', data={"file_content": b64lic})
        if status == -1:
            return -2
    else:
        print("This instance does not need a license")
    return 0


if __name__ == "__main__":
    sys.exit(main())
