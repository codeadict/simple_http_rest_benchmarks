from django.http import HttpResponse


def index(request):
    output = 'Hello, world!'
    return HttpResponse(output)
