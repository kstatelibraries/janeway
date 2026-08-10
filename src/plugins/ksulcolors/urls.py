from django.urls import re_path

from plugins.ksulcolors import views


urlpatterns = [
    re_path(r'^manager/$', views.manager, name='ksulcolors_manager'),
]
