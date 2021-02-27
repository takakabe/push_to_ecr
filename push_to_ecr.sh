#!/bin/bash

usage() {
  echo 'usage: ./push_to_ecr.sh --image LocalDockerImage --repository ECRName --profile AWSProfile'
}

if [ ${#} -eq 0 ]; then
  usage
  exit 1
fi

while getopts n:i:p-: opt; do
  optarg="${OPTARG}"
  if [[ "${opt}" = "-" ]]; then
    opt="-${OPTARG%%=*}"
    optarg="${OPTARG/${OPTARG%%=*}/}"
    optarg="${optarg#=}"
    if [[ -z "${optarg}" ]] && [[ ! "${!OPTIND}" = "-*" ]]; then
        optarg="${!OPTIND}"
        shift
    fi
  fi
  case "-${opt}" in
    -n|--repository)
      repository="${optarg}"
      ;;
    -i|--image)
      image="${optarg}"
      ;;
    --profile)
      profile="${optarg}"
      ;;
    --)
      break
      ;;
    -\?)
      usage
      exit 1
      ;;
    --*)
      echo "${0}: illegal option -- ${opt##-}" >&2
      usage
      exit 1
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [[ -z "${repository}" || -z "${image}" ]]; then
  usage
  exit 1
fi

account_id=`aws sts get-caller-identity --profile "${profile:-default}" | jq .Account | awk -F"\"" '{print $2}'`

docker_password=`aws ecr get-login-password --profile "${profile:-default}" --region ap-northeast-1`
docker login -u AWS -p ${docker_password} https://${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com
docker tag ${image} ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${repository}
docker push ${account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/${repository}

exit 0
