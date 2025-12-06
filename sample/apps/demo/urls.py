from django.urls import path
from . import views


urlpatterns = [
  path('error/zero', views.Zero.as_view(), name='zero'),
  path('error/key', views.Key.as_view(), name='key'),
  path('span/sample', views.SampleSpan.as_view(), name='span_sample'),
  path('log/sample', views.SampleLog.as_view(), name='sample'),
]