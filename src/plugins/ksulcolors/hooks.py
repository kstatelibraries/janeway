from django.conf import settings


from django.templatetags.static import static

def inject_css(context):
    return f'<link rel="stylesheet" href="{static("plugins/ksulcolors/css/ksul.css")}">'
