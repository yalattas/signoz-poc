import logging
from rest_framework.response import Response
from rest_framework.views import APIView

from opentelemetry import trace

tracer = trace.get_tracer(__name__)
logger = logging.getLogger(__name__)
otlp_logger = logging.getLogger("django.otlp")

class Zero(APIView):
  def get(self, request):
    print('--------------')
    print(request.__dict__)
    print('--------------')
    print(request.headers)
    print('--------------')
    print(request.data)
    result = 1 / 0
    return Response({"result": result})
class Key(APIView):
  def get(self, request):
    print('--------------')
    print(request.__dict__)
    print('--------------')
    print(request.headers)
    print('--------------')
    print(request.data)
    data = {}
    return Response({"value": data["non_existent_key"]})
class SampleSpan(APIView):
  def get(self, request):
    with tracer.start_as_current_span("sample_span"):
      # Simulate some processing
      print('--------------')
      print(request.__dict__)
      print('--------------')
      print(request.headers)
      print('--------------')
      print(request.data)
      total = sum(range(100))
    return Response({"total": total})
class SampleLog(APIView):
  def get(self, request):
    # Get current span (should be the Django HTTP span created by instrumentation)
    print('--------------')
    print(request.__dict__)
    print('--------------')
    print(request.headers)
    print('--------------')
    print(request.data)
    current_span = trace.get_current_span()

    with tracer.start_as_current_span("sample_log_processing") as span:
      span.set_attribute("user.id", str(getattr(request.user, 'id', 'anonymous')))
      span.set_attribute("request.ip", request.META.get('REMOTE_ADDR', 'unknown'))
      span.set_attribute("http.request.method", request.method)
      span.set_attribute("url.full", request.build_absolute_uri())
      span.set_attribute("http.route", request.resolver_match.route if request.resolver_match else request.path)
      span.set_attribute("url.scheme", request.scheme)
      span.set_attribute("server.address", request.get_host())
      span.set_attribute("url.path", request.get_full_path())
      span.set_attribute("user_agent.original", request.META.get('HTTP_USER_AGENT', ''))
      span.set_attribute("operation.name", "sample_log")
      # OTLP logger with structured data
      otlp_logger.debug("OTLP Debug: Starting log demo")
      otlp_logger.info(
        "OTLP: Sample log endpoint accessed",
        extra={
          "endpoint": "/sample-log",
          "user_id": getattr(request.user, 'id', None),
          "method": request.method,
          "ip_address": request.META.get('REMOTE_ADDR', 'unknown'),
          "user_agent": request.META.get('HTTP_USER_AGENT', 'unknown'),
          "request_id": f"{hash(request)}"
        }
      )
      
      response = Response({"message": "Log recorded and sent to OpenTelemetry via OTLP logger."})
      
      # Set response status code on both the current HTTP span and processing span
      span.set_attribute("http.response.status_code", response.status_code)
      if current_span and current_span.is_recording():
        current_span.set_attribute("http.response.status_code", response.status_code)
      
      return response
