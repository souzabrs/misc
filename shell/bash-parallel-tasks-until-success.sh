#!/bin/bash

# run tasks in parallel and return the failed ones
# syntax: run_tasks task1 task2 task3
run_tasks() {

  failed=""
  tasks=($@)
  PIDS=()

  for task in $@
  do
    # run the task silently in the background
    $task >/dev/null 2>&1 &

    # get its PID
    PIDS+=($!)
  done

  for i in `seq 0 ${#PIDS[@]}`
  do
    PID=${PIDS[$i]}

    # wait for the task to complete
    if ! wait $PID
    then
      # if it fail, grab its name
      failed+=${tasks[$i]}" "
    fi
  done

  echo $failed

}

# run tasks in parallel until each one succeeds
# syntax: run_tasks_until_success task1 task2 task3
run_tasks_until_success() {

  tasks=$@

  while [ -n "$tasks" ]
  do
    # run tasks and get the failed ones
    tasks=`run_tasks $tasks`
    if [ -n "$tasks" ]
    then
      echo task\(s\) $tasks failed, retrying
    fi
  done

}

# usage example:

# this task will run successfully once
my_task_one() {

  # check if file .task_one exists
  if [[ -f ".task_one" ]]
  then
    # read it, and set $exit_status with its content
    exit_status=`cat .task_one`
  else
    exit_status=0
  fi

  # take a little nap
  sleep 1

  # decrement $exit_status by one and put the result in file .task_one
  echo $(($exit_status - 1)) > .task_one

  return $exit_status

}

# this task will fail in the first time and succeed in the second
my_task_two() {

  # check if file .task_two exists
  if [[ -f ".task_two" ]]
  then
    # read it, and set $exit_status with its content
    exit_status=`cat .task_two`
  else
    exit_status=1
  fi

  # take a little nap
  sleep 2

  # decrement $exit_status by one and put the result in file .task_two
  echo $(($exit_status - 1)) > .task_two

  return $exit_status
}

# this task will fail two times and then succeed
my_task_three() {

  # check if file .task_three exists
  if [[ -f ".task_three" ]]
  then
    # read it, and set $exit_status with its content
    exit_status=`cat .task_three`
  else
    exit_status=2
  fi

  # take a little nap
  sleep 3

  # decrement $exit_status by one and put the result in file .task_three
  echo $(($exit_status - 1)) > .task_three

  return $exit_status

}

run_tasks_until_success 'my_task_one my_task_two my_task_three'

# clear files
rm .task_*

# expected output:
# task(s) my_task_two my_task_three failed, retrying
# task(s) my_task_three failed, retrying
