"""Signals from the django_bouncy app"""
# pylint: disable=invalid-name
from django.dispatch import Signal

# Any notification received
notification = Signal(providing_args=["notification", "request"])

# New SubscriptionConfirmation received
subscription = Signal(providing_args=["result", "notification"])

# New bounce or complaint received
feedback = Signal(providing_args=["instance", "message", "notification"])
