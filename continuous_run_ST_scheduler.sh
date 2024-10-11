#!/bin/sh
check_new_version () {
  python3 check_new_worker.py
}

check_celery_and_execute () {
    if [ "$MODEL_MODE" = "LT" ]
    then
        SERVICE="worker_long_term"
    elif [ "$MODEL_MODE" = "ST_SOLVER" ]
    then
        SERVICE="worker_short_term_solver"
    elif [ "$MODEL_MODE" = "ST_SCHEDULER" ]
    then
        SERVICE="worker_short_term_scheduler"
    fi
    if pgrep -f "$SERVICE" >/dev/null
    then
        echo "$SERVICE is running"
    else
        echo "$SERVICE is stopped, relaunching it"
        if [ "$MODEL_MODE" = "LT" ]
        then
            python3 -m pip install -r $LT_INSTALL_PATH/requirements.txt > /dev/null
            cd src 
            nohup celery -A worker_long_term.app worker -Q long_term --concurrency=10 -P prefork -n long_term_worker@%h --loglevel=debug > celery_LT.out 2>&1 &
        elif [ "$MODEL_MODE" = "ST_SOLVER" ]
        then
            python3 -m pip install -r $ST_INSTALL_PATH/requirements.txt > /dev/null
            (export PYTHONPATH="$ST_INSTALL_PATH/src/:$PYYTHONPATH" && nohup env $(cat $ST_INSTALL_PATH/.env | xargs) celery -A worker_short_term_solver.app worker -Q short_term_solver --concurrency=10 -P prefork -n short_term_solver_worker@%h --loglevel=debug > solver.out 2>&1 &)
        elif [ "$MODEL_MODE" = "ST_SCHEDULER" ]
        then
            python3 -m pip install -r $ST_INSTALL_PATH/requirements.txt > /dev/null
            (export PYTHONPATH="$ST_INSTALL_PATH/src/:$PYYTHONPATH" && nohup env $(cat $ST_INSTALL_PATH/.env | xargs) celery -A worker_short_term_scheduler.app worker -Q short_term_scheduler --concurrency=10 -P prefork -n short_term_scheduler_worker@%h --loglevel=debug > scheduler.out 2>&1 &)
        fi
    fi
}

while true
do
  export $(grep -v '^#' .env_scheduler | sed 's/~/$HOME/' | envsubst | xargs -0)
  echo "Checking for new version"
  check_new_version
  echo "Check if celery is running"
  check_celery_and_execute
  echo "Waiting 2 minutes for a new check"
  sleep 120
done
