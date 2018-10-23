
type docker-machine > /dev/null

if [ $? = 0 ]; then

    result=$(docker-machine status)
    if [[ "$result" == "Running" ]]; then
    
        eval $(docker-machine env)

    fi

fi

