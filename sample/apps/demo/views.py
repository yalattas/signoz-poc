import logging
from rest_framework.response import Response
from rest_framework.views import APIView

from opentelemetry import trace

tracer = trace.get_tracer(__name__)
logger = logging.getLogger(__name__)

class Zero(APIView):
  def get(self, request):
    result = 1 / 0
    return Response({"result": result})
class Key(APIView):
  def get(self, request):
    data = {}
    return Response({"value": data["non_existent_key"]})
class SampleLog(APIView):
  def get(self, request):
    with tracer.start_as_current_span("sample_log"):
      logger.info("This is a sample log message from SampleLog view.", extra={"endpoint": "/sample-log", "user_id": getattr(request.user, 'id', None)})
      logger.debug("Debug log: Processing sample log request")
      logger.warning("Warning log: This is a warning message for testing")
      logger.error("Error log: This is an error message for testing")
    return Response({"message": "Log recorded and sent to OpenTelemetry."})