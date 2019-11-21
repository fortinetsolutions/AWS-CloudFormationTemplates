from .fos_restapi import FortiOSREST


class FortiOSAPI(FortiOSREST):

    def __init__(self, admin_sport):
        FortiOSREST.__init__(self, admin_sport)
        return

    def run_command(self):
        return
