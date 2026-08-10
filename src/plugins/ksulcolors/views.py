from django.shortcuts import render

from plugins.ksulcolors import forms


def manager(request):
    form = forms.DummyManagerForm()

    template = 'ksulcolors/manager.html'
    context = {
        'form': form,
    }

    return render(request, template, context)
