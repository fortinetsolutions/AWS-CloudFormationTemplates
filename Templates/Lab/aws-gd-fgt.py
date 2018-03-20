import boto3
import os
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
addrgrpBATCHcreate = os.environ['addrgrpBATCHcreate']
fgtLOGINinfo = os.environ['fgtLOGINinfo']
fgtTIMEOUT = os.environ['fgtapiTIMEOUT']
fgtDEBUG = os.environ['fgtapiDEBUG']
jsonDEBUG = os.environ['jsoneventDEBUG']
logininfoerrors = 0

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

def logininfo_check():
    ### decrypt the encrypted environment variable in transit with the KMS key used to encrypt it
    global logininfoerrors
    global fgtLOGINinfo
    logininfoerrors=0
    fgtLOGINinfo = boto3.client('kms').decrypt(CiphertextBlob=b64decode(os.environ['fgtLOGINinfo']))['Plaintext'].decode('utf-8')
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
            print('!!--> Missing a login attribute for one of the FGT entries')
            logininfoerrors+=1

def addrgrp_batch_check():
    split1=fgtLOGINinfo.split('|')
    for info in split1:
        print ('-=-' * 20)
        fgtIP,fgtADMIN,fgtPASS=info.split(',')
        try:
            print('--> logging into fgtIP %s with user %s' % (fgtIP, fgtADMIN))
            fgt = FortiOSREST()
            fgt.debug(fgtDEBUG)
            fgt.login(fgtIP, fgtADMIN, fgtPASS)
            print('--> checking if target addrgrps exist.')
            ### check if each target addrgrp object exists already
            for key, value in gd2fgtTYPE.iteritems():
                addrgrpSEARCH = 'addrgrp/'+addrgrpPREFIX+value
                addrgrpNAME = addrgrpPREFIX+value
                json_resp = json.loads( fgt.get('cmdb', 'firewall', addrgrpSEARCH) )
                if (json_resp['http_status'] == 200) and (json_resp['results'] is not None):
                    print('--> existing addrgrp match: %s' % addrgrpNAME)
                else:
                    ### check if placeholder address object exists, if so just create the target addrgrp
                    json_resp = json.loads( fgt.get('cmdb', 'firewall', 'address/empty-placeholder') )
                    if (json_resp['http_status'] == 200) and (json_resp['results'] is not None):
                        print('--> creating addrgrp: %s' % addrgrpNAME)
                        fgt.post('cmdb', 'firewall', 'addrgrp', data={'name': addrgrpNAME, 'member':[{'name':'empty-placeholder'}]})
                    else:
                        ### if not create the placeholder address object and the target addrgrp
                        print('--> creating placeholder address: empty-placeholder')
                        fgt.post('cmdb', 'firewall', 'address', data={'name':'empty-placeholder', 'type':'ipmask', 'subnet':'0.0.0.0/32'})
                        print('--> creating addrgrp: %s' % addrgrpNAME)
                        fgt.post('cmdb', 'firewall', 'addrgrp', data={'name':addrgrpNAME, 'member':[{'name':'empty-placeholder'}]})
            print('--> logging out of fgtIP: %s' % fgtIP)
            fgt.logout()
        except Exception as generalERROR:
            print('!!--> general error: %s' % generalERROR)

def process_event(event, context):
    ### if the event is not null, parse general event values 
    if (event is not None):
        print ('-=-' * 20)
        print('--> parsing GD event details.')
        print ('id: %s' % event['detail']['id'])
        print ('title: %s' % event['detail']['title'])
        print ('type: %s' % event['detail']['type'])
        ### use regex to remove special characters from the event type field for use as an addrgrp name
        origTYPE = event['detail']['type']
        newTYPE = re.sub(r':|\.|!|', '', origTYPE)
        newTYPE = re.sub(r'\/', '-', newTYPE)
        newTYPE = re.sub(r'&', 'n', newTYPE)
        grpNAME = addrgrpPREFIX+newTYPE
        ### each address object will have the finding id and title of the related event in the comments of the object
        addrCOMMENT = 'FindingId-'+event['detail']['id']+' '+event['detail']['title']
        print ('regex type: %s' % newTYPE)
        try:
            for key, value in gd2fgtTYPE.iteritems():
                if (event['detail']['type'] == key):
                    #testing out regex
                    #grpNAME = addrgrpPREFIX+value
                    continue
        except: pass
        ### based on the action type, different fields will be parsed as the event format is different
        print ('actionType: %s' % event['detail']['service']['action']['actionType'])
        try:
            if (event['detail']['service']['action']['actionType'] == 'AWS_API_CALL'):
                addrIPv4 = event['detail']['service']['action']['awsApiCallAction']['remoteIpDetails']['ipAddressV4']
                print ('IPv4: %s' % addrIPv4)
            elif (event['detail']['service']['action']['actionType'] == 'NETWORK_CONNECTION'):
                resourceIPv4 = event['detail']['resource']['instanceDetails']['networkInterfaces'][0]['privateIpAddress']
                remoteIPv4 = event['detail']['service']['action']['networkConnectionAction']['remoteIpDetails']['ipAddressV4']
                if (event['detail']['service']['resourceRole'] == 'ACTOR'):
                    addrIPv4 = resourceIPv4
                else:
                    addrIPv4 = remoteIPv4
                print ('ResourceRole: %s' % event['detail']['service']['resourceRole'])
                print ('Resource IPv4: %s' % resourceIPv4)
                print ('Remote IPv4: %s' % remoteIPv4)
            elif (event['detail']['service']['action']['actionType'] == 'DNS_REQUEST'):
                addrFQDN = event['detail']['service']['action']['dnsRequestAction']['domain']
                addrIPv4 = ''
                print ('domain: %s' % addrFQDN)
            elif (event['detail']['service']['action']['actionType'] == 'PORT_PROBE'):
                resourceIPv4 = event['detail']['resource']['instanceDetails']['networkInterfaces'][0]['privateIpAddress']
                remoteIPv4 = event['detail']['service']['action']['portProbeAction']['portProbeDetails'][0]['remoteIpDetails']['ipAddressV4']
                if (event['detail']['service']['resourceRole'] == 'ACTOR'):
                    addrIPv4 = resourceIPv4
                else:
                    addrIPv4 = remoteIPv4
                print ('ResourceRole: %s' % event['detail']['service']['resourceRole'])
                print ('Resource IPv4: %s' % resourceIPv4)
                print ('Remote IPv4: %s' % remoteIPv4)
        except KeyError: pass

        ### login to each FGT and push the address object to it based on the event parsing above
        split1=fgtLOGINinfo.split('|')
        for info in split1:
            fgtIP,fgtADMIN,fgtPASS=info.split(',')
            try:
                print('--> logging into fgtIP %s with user %s' % (fgtIP, fgtADMIN))
                fgt = FortiOSREST()
                fgt.debug(fgtDEBUG)
                fgt.login(fgtIP, fgtADMIN, fgtPASS)
                print('--> creating GD address based on event details.')
                ### if there is an IPv4 value, create the object and add it to the correct addrgrp
                if (addrIPv4 != ''):
                    addrIPv4host = addrIPv4+'/32'
                    addrNAME = addripPREFIX+addrIPv4host
                    grpPATH = 'addrgrp/'+grpNAME+'/member'
                    print('--> creating IPv4 address: %s' % addrNAME)
                    fgt.post('cmdb', 'firewall', 'address', data={'name':addrNAME, 'type':'ipmask', 'subnet':addrIPv4host, 'comment':addrCOMMENT})
                    if (addrgrpBATCHcreate == 'off'):
                        addrgrpSEARCH = 'addrgrp/'+grpNAME
                        json_resp = json.loads( fgt.get('cmdb', 'firewall', addrgrpSEARCH) )
                        if (json_resp['http_status'] == 200) and (json_resp['results'] is not None):
                            pass
                        else:
                            print('--> no existing addrgrp found, creating addrgrp: %s' % grpNAME)
                            fgt.post('cmdb', 'firewall', 'addrgrp', data={'name': grpNAME, 'member':[{'name':'empty-placeholder'}]})
                    else:
                        pass
                    print('--> appending to addrgrp: %s' % grpNAME)
                    fgt.post('cmdb', 'firewall', grpPATH, data={'name':addrNAME})
                ### if there is an FQDN value, create the object and add it to the correct addrgrp
                elif (addrFQDN != ''):
                    addrNAME = addrfqdnPREFIX+addrFQDN
                    grpPATH = 'addrgrp/'+grpNAME+'/member'
                    print('--> creating FQDN address: %s' % addrNAME)
                    fgt.post('cmdb', 'firewall', 'address', data={'name':addrNAME, 'type':'fqdn', 'fqdn':addrFQDN, 'comment':addrCOMMENT})
                    if (addrgrpBATCHcreate == 'off'):
                        addrgrpSEARCH = 'addrgrp/'+grpNAME
                        json_resp = json.loads( fgt.get('cmdb', 'firewall', addrgrpSEARCH) )
                        if (json_resp['http_status'] == 200) and (json_resp['results'] is not None):
                            pass
                        else:
                            print('--> no existing addrgrp found, creating addrgrp: %s' % grpNAME)
                            fgt.post('cmdb', 'firewall', 'addrgrp', data={'name': grpNAME, 'member':[{'name':'empty-placeholder'}]})
                    else:
                        pass
                    print('--> appending to addrgrp: %s' % grpNAME)
                    fgt.post('cmdb', 'firewall', grpPATH, data={'name':addrNAME})
                ### skip creating an address object if both the IPv4 and FQDN values are null
                else:
                    print ('!!--> Skipping address object, missing either a valid IPv4 or FQDN value to use!')
                print('--> logging out of fgtIP: %s' % fgtIP)
                fgt.logout()
            except Exception as generalERROR:
                print('!!--> general error: %s' % generalERROR)
    print ('-=-' * 20)

def lambda_handler(event, context):
    print ('-=-' * 20)
    print ('>> Function triggered!')
    print ('>> addripPREFIX: %s' % addripPREFIX)
    print ('>> addrfqdnPREFIX: %s' % addrfqdnPREFIX)
    print ('>> addrgrpPREFIX: %s' % addrgrpPREFIX)
    print ('>> addrgrpBATCHcreate: %s' % addrgrpBATCHcreate)
    print ('>> fgtapiTIMOUET: %s' % fgtTIMEOUT)
    print ('>> fgtapiDEBUG: %s' % fgtDEBUG)
    print ('>> jsoneventDEBUG: %s' % jsonDEBUG)
    if (jsonDEBUG == 'on'):
        print('>>>> DEBUG GD Event: %s' % json.dumps(event))
    logininfo_check()
    if (logininfoerrors == 0) and (addrgrpBATCHcreate == 'on'):
        print('>> Running batch address group object check')
        addrgrp_batch_check()
        process_event(event, context)
    elif (logininfoerrors == 0) and (addrgrpBATCHcreate == 'off'):
        process_event(event, context)
    elif (addrgrpBATCHcreate != 'on') and (addrgrpBATCHcreate != 'off'):
        print('!!--> set the addrgrpBATCHcreate variable to either on or off for the function to run successfully')
        print ('-=-' * 20)        
    else:
        print('!!--> Correct the errors in the fgt login info for the function to run successfully')
        print ('-=-' * 20)
#
# end of script
#