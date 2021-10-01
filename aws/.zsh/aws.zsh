
function aws-search-policies() {
   if [ $# -eq 0 ]; then 
     echo "Search what policy name?"
     return 1
   fi
   aws iam list-policies | jq '.[] | .[] | .PolicyName'|grep $@
}

