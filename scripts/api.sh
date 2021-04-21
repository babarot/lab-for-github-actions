GITHUB_TOKEN=${GITHUB_TOKEN:?GITHUB_TOKEN is required}
EVENT_ACTION=${EVENT_ACTION:?EVENT_ACTION is required}
GITHUB_REPO=${GITHUB_REPO:?GITHUB_REPO is required}
PULL_REQUEST_NUMBER=${PULL_REQUEST_NUMBER:?PULL_REQUEST_NUMBER is required}
GIST_ID=${GIST_ID:?GIST_ID is required}

ok_to_record() {
  local -i count
  count=$(get_pull_files | jq -r '.[] | select(.filename == endwith("module.tf")) | select(.status == "added") | .additions')

  if [[ ${count:-0} == 0 ]]; then
    return 1
  fi

  return 0
}

main() {
  local action
  action=${EVENT_ACTION}

  if ! ok_to_record; then
    return
  fi

  # https://docs.github.com/ja/developers/webhooks-and-events/github-event-types#pullrequestevent
  case "${action}" in
    "opened" | "reopened")
      insert_record | update_db
      ;;

    "closed")
      local closed_at
      closed_at=$(get_pull | jq -r '.closed_at')
      update_record "closed_at" "${closed_at}" | update_db
      ;;

  esac
}

get_pull() {
  curl \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/${GITHUB_REPO}/pulls/${PULL_REQUEST_NUMBER}
}

get_pull_files() {
  curl \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/${GITHUB_REPO}/pulls/${PULL_REQUEST_NUMBER}/files
}

get_record() {
  curl \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/gists/${GIST_ID} \
    | jq -r '.files["pull_request.json"].content'
}

insert_record() {
  local created_at closed_at
  created_at=$(get_pull | jq -r '.created_at')
  closed_at=$(get_pull | jq -r '.closed_at')
  get_record | jq '.pull_requests += [
  {
    "number": '${PULL_REQUEST_NUMBER}',
    "created_at": "'${created_at}'",
    "closed_at": "'${closed_at}'"
  }]'
}

update_record() {
  local json k v
  local k=${1:?key which you update is required}
  local v=${2:?value which you update is required}
  get_record | jq '(.pull_requests[] | select(.number == '${PULL_REQUEST_NUMBER}') | .'${k}') |= "'${v}'"'
}

update_db() {
  local json
  json="$(jq 'tostring')"
  cat <<EOF |
{
  "files": {
    "pull_request.json": {
      "filename": "pull_request.json",
      "content": ${json}
    }
  }
}
EOF

  curl \
    -X PATCH \
    -H "Authorization: Bearer ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/gists/${GIST_ID} \
    -d @-
}

set -e
main
