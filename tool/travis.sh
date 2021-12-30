#!/bin/bash
# Created with package:mono_repo v3.0.0

# Support built in commands on windows out of the box.
function pub() {
  if [[ $TRAVIS_OS_NAME == "windows" ]]; then
    command pub.bat "$@"
  else
    command pub "$@"
  fi
}
function dartfmt() {
  if [[ $TRAVIS_OS_NAME == "windows" ]]; then
    command dartfmt.bat "$@"
  else
    command dartfmt "$@"
  fi
}
function dartanalyzer() {
  if [[ $TRAVIS_OS_NAME == "windows" ]]; then
    command dartanalyzer.bat "$@"
  else
    command dartanalyzer "$@"
  fi
}

if [[ -z ${PKGS} ]]; then
  echo -e '\033[31mPKGS environment variable must be set! - TERMINATING JOB\033[0m'
  exit 64
fi

if [[ "$#" == "0" ]]; then
  echo -e '\033[31mAt least one task argument must be provided! - TERMINATING JOB\033[0m'
  exit 64
fi

SUCCESS_COUNT=0
declare -a FAILURES

for PKG in ${PKGS}; do
  echo -e "\033[1mPKG: ${PKG}\033[22m"
  EXIT_CODE=0
  pushd "${PKG}" >/dev/null || EXIT_CODE=$?

  if [[ ${EXIT_CODE} -ne 0 ]]; then
    echo -e "\033[31mPKG: '${PKG}' does not exist - TERMINATING JOB\033[0m"
    exit 64
  fi

  pub upgrade --no-precompile || EXIT_CODE=$?

  if [[ ${EXIT_CODE} -ne 0 ]]; then
    echo -e "\033[31mPKG: ${PKG}; 'pub upgrade' - FAILED  (${EXIT_CODE})\033[0m"
    FAILURES+=("${PKG}; 'pub upgrade'")
  else
    for TASK in "$@"; do
      EXIT_CODE=0
      echo
      echo -e "\033[1mPKG: ${PKG}; TASK: ${TASK}\033[22m"
      case ${TASK} in
      command_0)
        echo 'dartanalyzer --fatal-infos .'
        dartanalyzer --fatal-infos . || EXIT_CODE=$?
        ;;
      command_1)
        echo 'dartfmt --dry-run --set-exit-if-changed .'
        dartfmt --dry-run --set-exit-if-changed . || EXIT_CODE=$?
        ;;
      command_2)
        echo 'pub run test test/all_test.dart --platform vm'
        pub run test test/all_test.dart --platform vm || EXIT_CODE=$?
        ;;
      command_3)
        echo 'pub run test test/all_test.dart --platform chrome'
        pub run test test/all_test.dart --platform chrome || EXIT_CODE=$?
        ;;
      command_4)
        echo 'pub global activate dart_coveralls && dart_coveralls report test/all_test.dart'
        pub global activate dart_coveralls && dart_coveralls report test/all_test.dart || EXIT_CODE=$?
        ;;
      command_5)
        echo 'pub run test --platform vm'
        pub run test --platform vm || EXIT_CODE=$?
        ;;
      command_6)
        echo 'pub run test --platform chrome'
        pub run test --platform chrome || EXIT_CODE=$?
        ;;
      *)
        echo -e "\033[31mUnknown TASK '${TASK}' - TERMINATING JOB\033[0m"
        exit 64
        ;;
      esac

      if [[ ${EXIT_CODE} -ne 0 ]]; then
        echo -e "\033[31mPKG: ${PKG}; TASK: ${TASK} - FAILED (${EXIT_CODE})\033[0m"
        FAILURES+=("${PKG}; TASK: ${TASK}")
      else
        echo -e "\033[32mPKG: ${PKG}; TASK: ${TASK} - SUCCEEDED\033[0m"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
      fi

    done
  fi

  echo
  echo -e "\033[32mSUCCESS COUNT: ${SUCCESS_COUNT}\033[0m"

  if [ ${#FAILURES[@]} -ne 0 ]; then
    echo -e "\033[31mFAILURES: ${#FAILURES[@]}\033[0m"
    for i in "${FAILURES[@]}"; do
      echo -e "\033[31m  $i\033[0m"
    done
  fi

  popd >/dev/null || exit 70
  echo
done

if [ ${#FAILURES[@]} -ne 0 ]; then
  exit 1
fi
