
#!/bin/bash

# Standard ArgoCD Build Environment variables 
# https://argo-cd.readthedocs.io/en/stable/user-guide/build-environment/
ARGOCD_APP_NAME=my-guestbook
ARGOCD_APP_NAMESPACE=my-namespace
ARGOCD_APP_SOURCE_PATH=guestbook
ARGOCD_APP_SOURCE_REPO_URL=https://cloudnativeapp.github.io/charts/curated/
ARGOCD_APP_SOURCE_TARGET_REVISION=0.2.0

# Plugin env variables
# User configurable
BASE_EXTRA=base/applications/guestbook/extra
ENV_EXTRA=env/preview/applications/guestbook/extra

BASE_GLOBAL=base/global.yaml
ENV_GLOBAL=env/preview/global.yaml

BASE_VALUES=base/applications/guestbook/guestbook_values.yaml
ENV_VALUES=env/preview/applications/guestbook/guestbook_values.yaml

# Internal env variables
WORK_DIR=_work
WORK_EXTRA=${WORK_DIR}/extra

BASE_VALUES_TEMPLATED=${WORK_DIR}/base_VALUES.yaml
ENV_VALUES_TEMPLATED=${WORK_DIR}/env_VALUES.yaml

GLOBAL=${WORK_DIR}/global.yaml

VALUES=${WORK_DIR}/values.yaml
MANIFEST=${WORK_DIR}/manifest.yaml

# Script start
# TODO: try catch to always remove working directory
{

  # Takes two variables:
  # 1. The folder containing your templates
  # 2. Value.yaml file you want to template over
  # Writes the output of the template to STDOUT
  function template {
    local _TEMPLATES=${1:?Must provide an argument}
    local _VALUES=${2:?Must provide an argument}

    helm create temp > /dev/null
    rm -r ./temp/templates/*
    cp ${_TEMPLATES} ./temp/templates/
    cp ${_VALUES} ./temp/values.yaml
    helm template temp
    rm temp -r > /dev/null
  }

  # Make work directory
  mkdir -p ${WORK_DIR}

  # Merge globals
  yaml-merge ${BASE_GLOBAL} ${ENV_GLOBAL} > ${GLOBAL}

  # Template base/values.yaml from globals
  template ${BASE_VALUES} ${GLOBAL} > ${BASE_VALUES_TEMPLATED}

  # Template env/values.yaml from globals
  template ${ENV_VALUES} ${GLOBAL} > ${ENV_VALUES_TEMPLATED}

  # Merge base and env values.yaml, and remove temp files
  yaml-merge ${BASE_VALUES_TEMPLATED} ${ENV_VALUES_TEMPLATED} > ${VALUES}
  rm ${BASE_VALUES_TEMPLATED}
  rm ${ENV_VALUES_TEMPLATED}

  # Template the helm chart with the generated values.yaml
  helm template ${ARGOCD_APP_NAME} ${ARGOCD_APP_SOURCE_PATH}
      --repo ${ARGOCD_APP_SOURCE_REPO_URL}  \
      --namespace ${ARGOCD_APP_NAMESPACE} \
      --version ${ARGOCD_APP_SOURCE_TARGET_REVISION} \
      --values ${VALUES} \
      > ${MANIFEST}

  # Copy extra files into common folder, and template and concat onto manifest
  # TODO: ignore extra files if paths are empty.
  cp -r ${BASE_EXTRA}/* ${WORK_EXTRA}
  cp -r ${ENV_EXTRA}/* ${WORK_EXTRA}
  template ${WORK_EXTRA} ${VALUES} >> ${MANIFEST}

  # Output manifest on STDOUT
  cat ${MANIFEST}
}

# Remove working directory
rm -r ${WORK_DIR}

# TODO create unit test !!!!!!!!!