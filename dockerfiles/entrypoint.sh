#!/bin/bash
set -e

install_plugins() {
    local plugin
    for plugin in ${JANEWAY_PLUGINS:-customstyling imports typesetting}; do
        python /janeway/src/manage.py install_plugins "$plugin"
    done
}

ensure_plugins() {
    local customstyling_dir="/janeway/src/plugins/customstyling"
    local imports_plugin_dir="/janeway/src/plugins/imports"
    local bepress_dir="/janeway/src/plugins/typesetting"

    if [ -d "$customstyling_dir" ] && [ -d "$imports_plugin_dir" ] && [ -d "$bepress_dir" ]; then
        return
    fi

    if [ ! -d "$customstyling_dir" ]; then
        git clone "${CUSTOMSTYLING_REPO:-https://github.com/openlibhums/customstyling.git}" \
            --branch "${CUSTOMSTYLING_REF:-v1.1.1}" \
            "$customstyling_dir"
    fi
    
    if [ ! -d "$imports_plugin_dir" ]; then
        git clone "${IMPORTS_REPO:-https://github.com/openlibhums/imports.git}" \
            --branch "${IMPORTS_REF:-main}" \
            "$imports_plugin_dir"
        # Install the required pip dependency too
    fi

    if [ ! -d "$bepress_dir" ]; then
        git clone "${BEPRESS_REPO:-https://github.com/openlibhums/bepress.git}" \
            --branch "${BEPRESS_REF:-master}" \
            "$bepress_dir"
    fi


    pip install python-wordpress-xmlrpc==2.3
}

# Check if APP_BUILT is set to a truthy value (e.g., 1, true, yes) to determine if the app is already built with janeway installed
# if the app is not built with janeway installed, we skip plugin etc installation until janeway is installed
app_built_enabled() {
    case "${APP_BUILT:-false}" in
        1|true|TRUE|yes|YES)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Allow running other commands (e.g., bash for debugging)
if [ $# -eq 0 ] || [ "${1:0:1}" = '-' ] || [ "$1" = 'gunicorn' ] || [ -z "${1##*:*}" ]; then
    if ! app_built_enabled; then
        exec "$@"
    fi

    if [ "$1" = 'gunicorn' ]; then
        shift
    fi

    # Build bind address from GUNICORN_HOST and GUNICORN_PORT, or use GUNICORN_BIND
    PORT="${GUNICORN_PORT:-8000}"
    BIND="${GUNICORN_BIND:-${GUNICORN_HOST:-0.0.0.0}:${PORT}}"

    if [ $# -eq 0 ]; then
        set -- core.wsgi:application --chdir /janeway/src
    fi

    # Add bind if not specified in args or GUNICORN_ARGS
    if [[ ! " $* $GUNICORN_ARGS " =~ " --bind " ]] && [[ ! " $* $GUNICORN_ARGS " =~ " -b " ]] && [[ ! "$* $GUNICORN_ARGS" =~ --bind= ]] && [[ ! "$* $GUNICORN_ARGS" =~ -b= ]]; then
        set -- --bind "$BIND" "$@"
    fi

    # Add workers if not specified - default to (2 * CPU_COUNT) + 1
    if [[ ! " $* $GUNICORN_ARGS " =~ " --workers " ]] && [[ ! " $* $GUNICORN_ARGS " =~ " -w " ]] && [[ ! "$* $GUNICORN_ARGS" =~ --workers= ]] && [[ ! "$* $GUNICORN_ARGS" =~ -w= ]]; then
        WORKERS="${GUNICORN_WORKERS:-$(( 2 * $(nproc) + 1 ))}"
        set -- --workers "$WORKERS" "$@"
    fi

    echo "Preparing Janeway assets..."
    ensure_plugins
    python /janeway/src/manage.py build_assets
    install_plugins
    python /janeway/src/manage.py collectstatic --noinput
    python /janeway/src/manage.py migrate --noinput
    exec gunicorn $GUNICORN_ARGS "$@"
fi

# Otherwise, run the command as-is (e.g., bash, sh, python)
exec "$@"
