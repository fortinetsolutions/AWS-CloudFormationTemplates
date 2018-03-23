import boto3
import os
import sys
import json
import re
from base64 import b64decode
from fos_restapi import FortiOSREST
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

### set variables such as debug, fgt IP + creds, etc
addripPREFIX = os.environ['addripPREFIX']
addrfqdnPREFIX = os.environ['addrfqdnPREFIX']
addrgrpPREFIX = os.environ['addrgrpPREFIX']
placeholderNAME = os.environ['placeholderaddrNAME']
aggaddrgrpNAME = os.environ['aggaddrgrpNAME']
addrgrpBATCHcreate = os.environ['addrgrpBATCHcreate']
fgtLOGINinfo = os.environ['fgtLOGINinfo']
fgtTIMEOUT = os.environ['fgtapiTIMEOUT']
fgtDEBUG = os.environ['fgtapiDEBUG']
fgtLOGINlist = []
logininfoerrors = 0
fgt = ''

### map original AWS Guard Duty Finding Types to sanitized FortiOS address groups
gd2fgtTYPE = {
    'Backdoor:EC2/XORDDOS' : 'BackdoorEC2-XORDDOS',
    'Backdoor:EC2/Spambot' : 'BackdoorEC2-Spambot',
    'Backdoor:EC2/C&CActivity.B!DNS' : 'BackdoorEC2-CnCActivityBDNS',
    'Behavior:IAMUser/InstanceLaunchUnusual' : 'BehaviorIAMUser-InstanceLaunchUnusual',
    'Behavior:EC2/NetworkPortUnusual' : 'BehaviorEC2-NetworkPortUnusual',
    'Behavior:EC2/TrafficVolumeUnusual' : 'BehaviorEC2-TrafficVolumeUnusual',
    'CryptoCurrency:EC2/BitcoinTool.B!DNS' : 'CryptoCurrencyEC2-BitcoinToolBDNS',
    'PenTest:IAMUser/KaliLinux' : 'PenTestIAMUser-KaliLinux',
    'Persistence:IAMUser/NetworkPermissions' : 'PersistenceIAMUser-NetworkPermissions',
    'Persistence:IAMUser/ResourcePermissions' : 'PersistenceIAMUser-ResourcePermissions',
    'Persistence:IAMUser/UserPermissions' : 'PersistenceIAMUser-UserPermissions',
    'Recon:EC2/PortProbeUnprotectedPort' : 'ReconEC2-PortProbeUnprotectedPort',
    'Recon:IAMUser/TorIPCaller' : 'ReconIAMUser-TorIPCaller',
    'Recon:IAMUser/MaliciousIPCaller.Custom' : 'ReconIAMUser-MaliciousIPCallerCustom',
    'Recon:IAMUser/MaliciousIPCaller' : 'ReconIAMUser-MaliciousIPCaller',
    'Recon:EC2/Portscan' : 'ReconEC2-Portscan',
    'Recon:IAMUser/NetworkPermissions' : 'ReconIAMUser-NetworkPermissions',
    'Recon:IAMUser/ResourcePermissions' : 'ReconIAMUser-ResourcePermissions',
    'Recon:IAMUser/UserPermissions' : 'ReconIAMUser-UserPermissions',
    'ResourceConsumption:IAMUser/ComputeResources' : 'ResourceConsumptionIAMUser-ComputeResources',
    'Stealth:IAMUser/PasswordPolicyChange' : 'StealthIAMUser-PasswordPolicyChange',
    'Stealth:IAMUser/CloudTrailLoggingDisabled' : 'StealthIAMUser-CloudTrailLoggingDisabled',
    'Stealth:IAMUser/LoggingConfigurationModified' : 'StealthIAMUser-LoggingConfigurationModified',
    'Trojan:EC2/BlackholeTraffic' : 'TrojanEC2-BlackholeTraffic',
    'Trojan:EC2/DropPoint' : 'TrojanEC2-DropPoint',
    'Trojan:EC2/BlackholeTraffic!DNS' : 'TrojanEC2-BlackholeTrafficDNS',
    'Trojan:EC2/DriveBySourceTraffic!DNS' : 'TrojanEC2-DriveBySourceTrafficDNS',
    'Trojan:EC2/DropPoint!DNS' : 'TrojanEC2-DropPointDNS',
    'Trojan:EC2/DGADomainRequest.B' : 'TrojanEC2-DGADomainRequestB',
    'Trojan:EC2/DGADomainRequest.C!DNS' : 'TrojanEC2-DGADomainRequestCDNS',
    'Trojan:EC2/DNSDataExfiltration' : 'TrojanEC2-DNSDataExfiltration',
    'Trojan:EC2/PhishingDomainRequest!DNS' : 'TrojanEC2-PhishingDomainRequestDNS',
    'UnauthorizedAccess:IAMUser/TorIPCaller' : 'UnauthorizedAccessIAMUser-TorIPCaller',
    'UnauthorizedAccess:IAMUser/MaliciousIPCaller.Custom' : 'UnauthorizedAccessIAMUser-MaliciousIPCallerCustom',
    'UnauthorizedAccess:IAMUser/ConsoleLoginSuccess.B' : 'UnauthorizedAccessIAMUser-ConsoleLoginSuccessB',
    'UnauthorizedAccess:IAMUser/MaliciousIPCaller' : 'UnauthorizedAccessIAMUser-MaliciousIPCaller',
    'UnauthorizedAccess:IAMUser/UnusualASNCaller' : 'UnauthorizedAccessIAMUser-UnusualASNCaller',
    'UnauthorizedAccess:EC2/TorIPCaller' : 'UnauthorizedAccessEC2-TorIPCaller',
    'UnauthorizedAccess:EC2/MaliciousIPCaller.Custom' : 'UnauthorizedAccessEC2-MaliciousIPCallerCustom',
    'UnauthorizedAccess:EC2/SSHBruteForce' : 'UnauthorizedAccessEC2-SSHBruteForce',
    'UnauthorizedAccess:EC2/RDPBruteForce' : 'UnauthorizedAccessEC2-RDPBruteForce',
    'UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration' : 'UnauthorizedAccessIAMUser-InstanceCredentialExfiltration',
    'UnauthorizedAccess:IAMUser/ConsoleLogin' : 'UnauthorizedAccessIAMUser-ConsoleLogin'
    }

class search_obj(object):
    def __init__(self, searchSTRING, objTYPE, objNAME):
        self.searchSTRING = searchSTRING
        self.objTYPE = objTYPE
        self.objNAME = objNAME
        self.hit = False
        self.json_resp = json.loads( fgt.get('cmdb', 'firewall', self.searchSTRING) )

    def function(self):
        if (self.objTYPE == 'placeholder'): pass
        elif (self.objTYPE == 'aggaddrgrp'): pass
        elif (self.objTYPE == 'aggaddrgrpmember'): pass
        elif (self.objTYPE == 'address'): print ('--> searching for duplicate address: %s' % self.objNAME)
        elif (self.objTYPE == 'addrgrp'): print ('--> searching for existing addrgrp: %s' % self.objNAME)
        elif (self.objTYPE == 'addrgrpmember'): print ('--> searching for existing addrgrp member: %s' % self.objNAME)

        if (self.json_resp['http_status'] == 200): 
            self.hit = True
            if (self.objTYPE == 'placeholder'): pass
            elif (self.objTYPE == 'aggaddrgrp'): pass
            elif (self.objTYPE == 'aggaddrgrpmember'): pass
            elif (self.objTYPE == 'address'): print ('<-- duplicate address found')
            elif (self.objTYPE == 'addrgrp'): print ('<-- existing addrgrp found')
            elif (self.objTYPE == 'addrgrpmember'): print ('<-- duplicate addrgrp member found')

class create_obj(object):
    def __init__(self, objTYPE, objNAME, objVAL1, objVAL2):
        self.objTYPE = objTYPE
        self.objNAME = objNAME
        self.objVAL1 = objVAL1
        self.objVAL2 = objVAL2

    def function(self):
        if (self.objTYPE == 'ipv4'):
            print('--> creating IPv4 address: %s' % self.objNAME)
            self.json_resp = json.loads( fgt.post('cmdb', 'firewall', 'address', data={'name':self.objNAME, 'type':'ipmask', 'subnet':self.objVAL1, 'comment':self.objVAL2}) )
        elif (self.objTYPE == 'fqdn'):
            print('--> creating FQDN address: %s' % self.objNAME)
            self.json_resp = json.loads( fgt.post('cmdb', 'firewall', 'address', data={'name':self.objNAME, 'type':'fqdn', 'fqdn':self.objVAL1, 'comment':self.objVAL2}) )
        elif (self.objTYPE == 'addrgrp'):
            print('--> creating addrgrp: %s' % self.objNAME)
            self.json_resp = json.loads( fgt.post('cmdb', 'firewall', 'addrgrp', data={'name':self.objNAME, 'member':[{'name':self.objVAL1}]}) )
        elif (self.objTYPE == 'addrgrpmember'):
            print('--> appending address: %s to addrgrp: %s' % (self.objVAL1, self.objVAL2))
            self.json_resp = json.loads( fgt.post('cmdb', 'firewall', self.objNAME, data={'name':self.objVAL1}) )
        elif (self.objTYPE == 'aggaddrgrp'):
            print('--> creating aggregate addrgrp: %s' % self.objNAME)
            self.json_resp = json.loads( fgt.post('cmdb', 'firewall', 'addrgrp', data={'name':self.objNAME, 'member':[{'name':self.objVAL1}]}) )
        elif (self.objTYPE == 'aggaddrgrpmember'):
            print('--> appending addrgrp: %s to aggregate addrgrp: %s' % (self.objVAL1, self.objVAL2))
            self.json_resp = json.loads( fgt.post('cmdb', 'firewall', self.objNAME, data={'name':self.objVAL1}) )

        if (self.json_resp['http_status'] == 200): print('<-- http_status: %s' % self.json_resp['http_status'])
        else:
            if (self.objTYPE == 'ipv4'): print('<--!! failed to create IPv4 address, dumping response: %s' % json.dumps(self.json_resp))
            elif (self.objTYPE == 'fqdn'): print('<--!! failed to create FQDN address, dumping response: %s' % json.dumps(self.json_resp))
            elif (self.objTYPE == 'addrgrp'): print('<--!! failed to create addrgrp, dumping response: %s' % json.dumps(self.json_resp))
            elif (self.objTYPE == 'addrgrpmember'): print('<--!! failed to append address to addrgrp, dumping response: %s' % json.dumps(self.json_resp))
            elif (self.objTYPE == 'aggaddrgrp'): print('<--!! failed to create aggregate addrgrp, dumping response: %s' % json.dumps(self.json_resp))
            elif (self.objTYPE == 'aggaddrgrpmember'): print('<--!! failed to append addrgrp to aggregate addrgrp, dumping response: %s' % json.dumps(self.json_resp))

def logininfo_check():
    global fgtLOGINinfo
    global fgtLOGINlist
    global logininfoerrors
    ### check if fgtLOGINinfo is an encrypted value or not by searching for commas
    cleartext=(bool(re.match('.*,.*', fgtLOGINinfo)))
    if cleartext is False:
        ### decrypt the encrypted environment variable in transit with the KMS key used to encrypt it
        print('>> decrypting fgtLOGINinfo environment variable with KMS key')
        try:
            fgtLOGINinfo = boto3.client('kms').decrypt(CiphertextBlob=b64decode(os.environ['fgtLOGINinfo']))['Plaintext'].decode('utf-8')
        except TypeError as malformedERROR: print('<--!! encyrpted string is truncated or malformed: %s' % malformedERROR)
        except Exception as generalERROR: print('<--!! general error: %s' % generalERROR)
    ### split the single string of fgt login information into each fgt's entry
    fgtLOGINlist=fgtLOGINinfo.split('|')
    ### for each entry, count the total number of attributes and divide by 1
    for entry in fgtLOGINlist:
        fgtLOGINattributes=entry.split(',')
        fgtLOGINtuples=(len(fgtLOGINattributes)/1)
        ### if the result is 3, then assume the entries are the fgt ip, admin, and password
        if (fgtLOGINtuples == 3):
            fgtIP,fgtADMIN,fgtPASS=entry.split(',')
        ###  if the result is not 3, then print that we are missing a login attribute for this fgt
        else:
            print('<--!! missing a login attribute for one of the FGT entries')
            logininfoerrors+=1

def addrgrp_batch_check():
    global fgt
    for entry in fgtLOGINlist:
        print ('-=-' * 20)
        fgtIP,fgtADMIN,fgtPASS=entry.split(',')
        try:
            print('--> logging into fgtIP %s with user %s' % (fgtIP, fgtADMIN))
            fgt = FortiOSREST()
            fgt.debug(fgtDEBUG)
            fgt.login(fgtIP, fgtADMIN, fgtPASS)
            ### check if the placeholder address exists already, if not create it
            addrSEARCH = 'address/'+placeholderNAME+'?format=name'
            search1 = search_obj(addrSEARCH, 'placeholder', placeholderNAME)
            search1.function()
            if search1.hit is False:
            	create1 = create_obj('ipv4', placeholderNAME, '0.0.0.0/32', 'placeholder object for creation of dynamic address groups')
            	create1.function()
            ### check if the aggregate addrgrp exists already, if not create it
            aggaddrgrpSEARCH = 'addrgrp/'+aggaddrgrpNAME+'?format=name'
            search2 = search_obj(aggaddrgrpSEARCH, 'aggaddrgrp', aggaddrgrpNAME)
            search2.function()
            if search2.hit is False:
	            create2 = create_obj('aggaddrgrp', aggaddrgrpNAME, placeholderNAME, None)
	            create2.function()
            ### check if each target addrgrp exists already, if not create it and append to the aggregate addrgrp
            print('>> checking if each target addrgrp exists')
            for key, value in gd2fgtTYPE.iteritems():
                addrgrpSEARCH = 'addrgrp/'+addrgrpPREFIX+value+'?format=name'
                addrgrpNAME = addrgrpPREFIX+value
                aggaddrgrpPATH = 'addrgrp/'+aggaddrgrpNAME+'/member'
                search3 = search_obj(addrgrpSEARCH, 'addrgrp', addrgrpNAME)
                search3.function()
                if search3.hit is False:
                    create3 = create_obj('addrgrp', addrgrpNAME, placeholderNAME, None)
                    create3.function()
                    create4 = create_obj('aggaddrgrpmember', aggaddrgrpPATH, addrgrpNAME, aggaddrgrpNAME)
                    create4.function()
            print('--> logging out of fgtIP: %s' % fgtIP)
            fgt.logout()
        except Exception as generalERROR:
            print('<--!! general error: %s' % generalERROR)

def process_event(event, context):
    global fgt
    ### if the event is not null, parse general event values 
    if (event is not None):
        print('-=-' * 20)
        print('>> parsing GD event details')
        print('Id: %s' % event['detail']['id'])
        print('Title: %s' % event['detail']['title'])
        print('Type: %s' % event['detail']['type'])
        ### use regex to remove special characters from the event type field for use as an addrgrp name
        origTYPE = event['detail']['type']
        sanitizedTYPE = re.sub(r':|\.|!|', '', origTYPE)
        sanitizedTYPE = re.sub(r'\/', '-', sanitizedTYPE)
        sanitizedTYPE = re.sub(r'&', 'n', sanitizedTYPE)
        grpNAME = addrgrpPREFIX+sanitizedTYPE
        print('Sanitized Type: %s' % sanitizedTYPE)
        print('Target Addrgrp: %s' % grpNAME)
        ### each address object will have the finding id and title of the related event in the comments of the object
        addrCOMMENT = 'FindingId-'+event['detail']['id']+'.  '+event['detail']['title']
        ### based on the action type, different fields will be parsed as the event format is different
        print('ActionType: %s' % event['detail']['service']['action']['actionType'])
        try:
            if (event['detail']['service']['action']['actionType'] == 'AWS_API_CALL'):
                addrIPv4 = event['detail']['service']['action']['awsApiCallAction']['remoteIpDetails']['ipAddressV4']
                print('IPv4: %s' % addrIPv4)
            elif (event['detail']['service']['action']['actionType'] == 'NETWORK_CONNECTION'):
                resourceIPv4 = event['detail']['resource']['instanceDetails']['networkInterfaces'][0]['privateIpAddress']
                remoteIPv4 = event['detail']['service']['action']['networkConnectionAction']['remoteIpDetails']['ipAddressV4']
                if (event['detail']['service']['resourceRole'] == 'ACTOR'):
                    addrIPv4 = resourceIPv4
                else:
                    addrIPv4 = remoteIPv4
                print('ResourceRole: %s' % event['detail']['service']['resourceRole'])
                print('Resource IPv4: %s' % resourceIPv4)
                print('Remote IPv4: %s' % remoteIPv4)
            elif (event['detail']['service']['action']['actionType'] == 'DNS_REQUEST'):
                addrFQDN = event['detail']['service']['action']['dnsRequestAction']['domain']
                addrIPv4 = ''
                print('domain: %s' % addrFQDN)
            elif (event['detail']['service']['action']['actionType'] == 'PORT_PROBE'):
                resourceIPv4 = event['detail']['resource']['instanceDetails']['networkInterfaces'][0]['privateIpAddress']
                remoteIPv4 = event['detail']['service']['action']['portProbeAction']['portProbeDetails'][0]['remoteIpDetails']['ipAddressV4']
                if (event['detail']['service']['resourceRole'] == 'ACTOR'):
                    addrIPv4 = resourceIPv4
                else:
                    addrIPv4 = remoteIPv4
                print('ResourceRole: %s' % event['detail']['service']['resourceRole'])
                print('Resource IPv4: %s' % resourceIPv4)
                print('Remote IPv4: %s' % remoteIPv4)
            else:
                print('<--!! unknown event action type: %s' % event['detail']['service']['action']['actionType'])
                print('<--!! exiting now')
                sys.exit()
        except KeyError: pass

        ### login to each FGT and push the address object to it based on the event parsing above
        print('>> preparing GD address based on event details.')
        for entry in fgtLOGINlist:
            fgtIP,fgtADMIN,fgtPASS=entry.split(',')
            print('--' * 20)
            try:
                print('--> logging into fgtIP %s with user %s' % (fgtIP, fgtADMIN))
                fgt = FortiOSREST()
                fgt.debug(fgtDEBUG)
                fgt.login(fgtIP, fgtADMIN, fgtPASS)
                ### if there is an IPv4 value, set the variables for the object name and search value
                if (addrIPv4 != ''):
                    addrIPv4host = addrIPv4+'/32'
                    addrNAME = addripPREFIX+addrIPv4
                    addrSEARCH = 'address/'+addrNAME+'?format=name'
                    search1 = search_obj(addrSEARCH, 'address', addrNAME)
                    search1.function()
                    if search1.hit is False:
                        create1 = create_obj('ipv4', addrNAME, addrIPv4host, addrCOMMENT)
                        create1.function()
                ### if there is an FQDN value, set the variables for the object name and search value
                elif (addrFQDN != ''):
                    addrNAME = addrfqdnPREFIX+addrFQDN
                    addrSEARCH = 'address/'+addrNAME+'?format=name'
                    search1 = search_obj(addrSEARCH, 'address', addrNAME)
                    search1.function()
                    if search1.hit is False:
                        create1 = create_obj('fqdn', addrNAME, addrFQDN, addrCOMMENT)
                        create1.function()
                ### skip creating an address object if both the IPv4 and FQDN values are empty
                else:
                    print('<--!! Skipping address, missing either a valid IPv4 or FQDN value to use!')
                    print('--> logging out of fgtIP: %s' % fgtIP)
                    fgt.logout()
                    continue
                ### if the addrgrpBATCHcreate is turned off, verify the target addrgrp exists, if it does not exist then create it
                if (addrgrpBATCHcreate == 'off'):
                    addrgrpSEARCH = 'addrgrp/'+grpNAME+'?format=name'
                    search2 = search_obj(addrgrpSEARCH, 'addrgrp', grpNAME)
                    search2.function()
                    if search2.hit is False:
                        create2 = create_obj('addrgrp', grpNAME, placeholderNAME, None)
                        create2.function()
                ### append address object to the target addrgrp
                addrgrpmemberSEARCH = 'addrgrp/'+grpNAME+'/member/'+addrNAME+'?format=name'
                search3 = search_obj(addrgrpmemberSEARCH, 'addrgrpmember', addrNAME)
                search3.function()
                if search3.hit is False:
                    grpPATH = 'addrgrp/'+grpNAME+'/member'
                    create3 = create_obj('addrgrpmember', grpPATH, addrNAME, grpNAME)
                    create3.function()
                print('--> logging out of fgtIP: %s' % fgtIP)
                fgt.logout()
            except Exception as generalERROR:
                print('<--!! general error: %s' % generalERROR)
    print('-=-' * 20)

def lambda_handler(event, context):
    print('-=-' * 20)
    print('>> Function triggered!')
    print('>> addripPREFIX: %s' % addripPREFIX)
    print('>> addrfqdnPREFIX: %s' % addrfqdnPREFIX)
    print('>> addrgrpPREFIX: %s' % addrgrpPREFIX)
    print('>> placeholderaddrNAME: %s' % placeholderNAME)
    print('>> aggaddrgrpNAME: %s' % aggaddrgrpNAME)
    print('>> addrgrpBATCHcreate: %s' % addrgrpBATCHcreate)
    print('>> fgtapiTIMOUET: %s' % fgtTIMEOUT)
    print('>> fgtapiDEBUG: %s' % fgtDEBUG)
    print('>> raw guard duty event: %s' % json.dumps(event))
    logininfo_check()
    if (logininfoerrors != 0):
        print('<--!! correct the errors in the fgt login info for the function to run successfully')
        print('-=-' * 20)
    elif (addrgrpBATCHcreate != 'on') and (addrgrpBATCHcreate != 'off'):
        print('<--!! set the addrgrpBATCHcreate environment variable to either on or off for the function to run successfully')
        print('-=-' * 20)
    elif (fgtDEBUG != 'on') and (fgtDEBUG != 'off'):
        print('<--!! set the fgtapiDEBUG environment variable to either on or off for the function to run successfully')
        print('-=-' * 20)
    elif (addrgrpBATCHcreate == 'on'):
        addrgrp_batch_check()
        process_event(event, context)
    elif (addrgrpBATCHcreate == 'off'):
        process_event(event, context)
#
# end of script
#