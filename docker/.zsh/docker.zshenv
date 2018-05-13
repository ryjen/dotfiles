
type docker-machine > /dev/null

if [ $? = 0 ]; then

    if [ `docker-machine status` = "Running" ]; then
    
        eval $(docker-machine env)

    fi

fi

