YARN_VERSION=$(yarn --version) && echo "$YARN_VERSION"
if [[ ${YARN_VERSION:0:1} == "1" ]]; then
  echo "Upgrading yarn" && yarn set version stable && yarn plugin import workspace-tools
fi
