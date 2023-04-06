#!/usr/bin/env bash

PRJ_DIR="$(dirname "$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE:-$0}")" && pwd)"

source "${SCRIPT_DIR}/libs/utils"

p "\n  ---------------------------------------------"
p "\n  deploy starting..."
p "\n  ---------------------------------------------\n\n"

: ==================================================
:  Validate .env
: ==================================================
if [ ! -e "${SCRIPT_DIR}/.env" ]; then
  p "    file(.env) does not exist.\n" "error"
  exit 1
else
  p "    check variables\n\n"
  error=0
  eval "$(cat "${SCRIPT_DIR}/.env" <(echo) <(declare -x))"
  if [ -z "${APPLICATION_NAME}" ]; then
    p "    [✖︎] APPLICATION_NAME\n" "error"
    error=1
  else
    p "    [✔︎] APPLICATION_NAME\n" "success"
  fi
  if [ -z "${SERVICE_NAME}" ]; then
    p "    [✖︎] SERVICE_NAME\n" "error"
    error=1
  else
    p "    [✔︎] SERVICE_NAME\n" "success"
  fi
  if [ -z "${S3_BUCKET_NAME}" ]; then
    p "    [✖︎] S3_BUCKET_NAME\n" "error"
    error=1
  else
    p "    [✔︎] S3_BUCKET_NAME\n" "success"
  fi
  if [ -z "${REPOSITORY_NAME}" ]; then
    p "    [✖︎] REPOSITORY_NAME\n" "error"
    error=1
  else
    p "    [✔︎] REPOSITORY_NAME\n" "success"
  fi
  if [ -z "${BRANCH_NAME}" ]; then
    p "    [✖︎] BRANCH_NAME\n" "error"
    error=1
  else
    p "    [✔︎] BRANCH_NAME\n" "success"
  fi
  [ ${error} == 1 ] && exit 1
fi

: ==================================================
:  Constants
: ==================================================
EXPIRE_DURATION=300
STACK_NAME="${APPLICATION_NAME}-${SERVICE_NAME}-CICD"
S3_PATH="s3://${S3_BUCKET_NAME}/${APPLICATION_NAME}/${SERVICE_NAME}"
TMPL_LIST="
root-cfnt.yml
artifact-repository-cfnt.yml
build-and-unit-test-project-cfnt.yml
build-and-push-container-image-project-cfnt.yml
pipeline-cfnt.yml
container-image-repository-cfnt.yml
"

: ==================================================
:  Functions
: ==================================================
function validate() {
  error_flag=false

  for template in $(cat)
  do
    set +e
    error=$(aws cloudformation validate-template --template-body file://${PRJ_DIR}/cfn-templates/${template} 2>&1 > /dev/null)
    if [ $? -eq 0 ]
    then
      echo -e "      ${template} ----- \u001b[32m✔︎\u001b[0m"
    else
      error_flag=true
      echo -e "      ${template} ----- \u001b[31m✖︎\u001b[0m"
      echo -e "\u001b[31m${error}\u001b[0m\n"
    fi
  done

  if ${error_flag}
  then
    exit 1
  fi
}

function generateSignedUrl() {
  for TMPL in $(cat)
  do
    echo $(aws s3 presign ${S3_PATH}/cfn-templates/${TMPL} --expires-in $EXPIRE_DURATION)
  done
}

: ==================================================
:  Main
: ==================================================
p "\n    validate cfn templates\n\n"
echo ${TMPL_LIST} | validate
[ $? -ne 0 ] && exit 1

p "\n    upload CFn template files.\n\n"
aws s3 sync ${PRJ_DIR}/ ${S3_PATH} --exclude "scripts/**/*" --exclude "buildspecs/**/*"

p "\n    generate signed urls.\n\n"
URLS=($(echo ${TMPL_LIST} | generateSignedUrl))

p "\n    deploy the CI/CD Pipeline stack.\n\n"
aws cloudformation deploy --stack-name "${STACK_NAME}" \
  --template-file "${PRJ_DIR}/cfn-templates/root-cfnt.yml" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ApplicationName="${APPLICATION_NAME}" \
                        ServiceName="${SERVICE_NAME}" \
                        ArtifactRepositoryTmplPath="${URLS[1]}" \
                        BuildAndUnitTestProjectTmplPath="${URLS[2]}" \
                        BuildAndPushContainerImageProjectStackTmplPath="${URLS[3]}" \
                        PipelineTmplPath="${URLS[4]}" \
                        ContainerImageRepositoryTmplPath="${URLS[5]}" \
                        RepositoryName="${REPOSITORY_NAME}" \
                        BranchName="${BRANCH_NAME}"
