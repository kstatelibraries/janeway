import os
import shutil
from utils import plugins
from django.conf import settings

PLUGIN_NAME = 'KsulColors Plugin'
DISPLAY_NAME = 'KsulColors'
DESCRIPTION = 'Overrides colors in OLH theme to match KSUL colors'
AUTHOR = 'Sawyer'
VERSION = '0.1'
SHORT_NAME = 'ksulcolors'
MANAGER_URL = 'ksulcolors_manager'
JANEWAY_VERSION = "1.7.0"

BASE_CSS_PATH = os.path.join(
    settings.MEDIA_ROOT,
    'ksulcolors',
)
KSULCOLORS_ASSETS = os.path.join(os.path.dirname(__file__), 'assets')
STATIC_CSS_PATH = os.path.join(
    settings.BASE_DIR,
    'static',
    'plugins',
    'ksulcolors',
    'css',
)


class KsulcolorsPlugin(plugins.Plugin):
    plugin_name = PLUGIN_NAME
    display_name = DISPLAY_NAME
    description = DESCRIPTION
    author = AUTHOR
    short_name = SHORT_NAME
    manager_url = MANAGER_URL

    version = VERSION
    janeway_version = JANEWAY_VERSION
    press_wide = True
    plugin_group_name = 'plugin:{plugin_name}'.format(plugin_name=SHORT_NAME)
    


def install():
    KsulcolorsPlugin.install()
    os.makedirs(BASE_CSS_PATH, exist_ok=True)
    shutil.copy(
        os.path.join(KSULCOLORS_ASSETS, 'ksul.css'),
        os.path.join(BASE_CSS_PATH, 'ksul.css')
    )

    os.makedirs(STATIC_CSS_PATH, exist_ok=True)
    shutil.copy(
        os.path.join(KSULCOLORS_ASSETS, 'ksul.css'),
        os.path.join(STATIC_CSS_PATH, 'ksul.css')
    )
    print('Installed ksulcolors')

def hook_registry():
    return {
        'base_head_css':
            {
                'module': 'plugins.ksulcolors.hooks',
                'function': 'inject_css'
            }
    }

def register_for_events():
    pass
