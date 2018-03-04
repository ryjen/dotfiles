
if [ test `hash docker-machine` ]; then

    if [ `docker-machine status` = "Running" ]; then
    
        eval $(docker-machine env)

    fi

fi

