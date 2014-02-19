# murano.sh - DevStack extras script to install Murano

if is_service_enabled murano; then
    if [[ "$1" == "source" ]]; then
        # Initial source
        source $TOP_DIR/lib/murano
        source $TOP_DIR/lib/murano-dashboard
    elif [[ "$1" == "stack" && "$2" == "install" ]]; then
        echo_summary "Installing Murano"
        install_murano
        if is_service_enabled horizon; then
            install_murano_dashboard
        fi
        if is_service_enabled murano-dsl; then
            install_murano_dsl
        fi
    elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        echo_summary "Configuring Murano"
        configure_murano
        #create_murano_accounts
        if is_service_enabled horizon; then
            configure_murano_dashboard
        fi
        if is_service_enabled murano-dsl; then
            configure_murano_dsl
        fi
    elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
        echo_summary "Initializing Murano"
        init_murano
        if is_service_enabled horizon; then
            init_murano_dashboard
        fi
        if is_service_enabled murano-dsl; then
            init_murano_dsl
        fi
        start_murano
        if is_service_enabled murano-dsl; then
            start_murano_dsl
        fi
    fi

    if [[ "$1" == "unstack" ]]; then
        stop_murano
        if is_service_enabled horizon; then
            cleanup_murano_dashboard
        fi
        if is_service_enabled murano-dsl; then
            stop_murano_dsl
            cleanup_murano_dsl
        fi
    fi
fi
