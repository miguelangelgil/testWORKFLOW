#!/bin/bash
type=${1}
task=${2}
statusTask=${3}
actor=$4
projectName=$5
bundleVersionCode=$6
platform=$7
buildType=$8
commitLink=$9
actionLink=${10}
channelId=${11}
messagePath=${12}
messageId=${13}

slackMessagePath="$messagePath"
slackTaskPath="./.github/github-workflows/.github/slackMessage/slackMessageTask.json"
slackSummaryPath="./.github/github-workflows/.github/slackMessage/summaryStatus.txt"

statusToInt () {
  local status="$1"

  case "$status" in
  "success")
    echo 1
    ;;
  "failure")
    echo 3
    ;;
  "cancelled")
  echo 4
  ;;
  "in_progress")
    echo 0
    ;;
  "skipped")
    echo 2
    ;;
  "none")
    echo 0
    ;;
  *)
    echo 0
    ;;
esac
}
if [ "$type" != "end" ]; then
  if [ "$(statusToInt $statusTask)" -gt '0' ]; then
    summary=$(head -n 1 "$slackSummaryPath")
    if [ "$summary" == ""]; then
        echo $statusTask > "$slackSummaryPath"
    elif [ "$(statusToInt $statusTask)" -gt "$(statusToInt $summary)" ]; then
        echo $statusTask > "$slackSummaryPath"
    fi
  fi
fi

if [ "$type" != "endlink" ]; then
  if [ "$(statusToInt $statusTask)" -gt '0' ]; then
    summary=$(head -n 1 "$slackSummaryPath")
    if [ "$summary" == ""]; then
        echo $statusTask > "$slackSummaryPath"
    elif [ "$(statusToInt $statusTask)" -gt "$(statusToInt $summary)" ]; then
        echo $statusTask > "$slackSummaryPath"
    fi
  fi
fi

if [ "$type" != "cancelled" ]; then
  if [ "$(statusToInt $statusTask)" -gt '0' ]; then
    summary=$(head -n 1 "$slackSummaryPath")
    if [ "$summary" == ""]; then
        echo $statusTask > "$slackSummaryPath"
    elif [ "$(statusToInt $statusTask)" -gt "$(statusToInt $summary)" ]; then
        echo $statusTask > "$slackSummaryPath"
    fi
  fi
fi

icon () {
  local status="$1"

  local working=":pepe_naruto:"
  local success=":heavy_check_mark:"
  local failure=":x:"
  local skipped=":black_right_pointing_double_triangle_with_vertical_bar:"
  local cancelled=":octagonal_sign:"

  case "$status" in
  "success")
    echo $success
    ;;
  "failure")
    echo $failure
    ;;
  "in_progress")
    echo $working
    ;;
  "skipped")
    echo $skipped
    ;;
  "cancelled")
    echo $cancelled
    ;;
  "none")
    echo $skipped
    ;;
  *)
    echo $working
    ;;
esac
}

color () {
    local status=$1

    local working="#C2FAFB"
    local success="#4BB543"
    local failure="#ff3333"
    local skipped="#BDC2C1"

case "$status" in
  "success")
    echo $success
    ;;
  "failure")
    echo $failure
    ;;
  "in_progress")
    echo $working
    ;;
  "skipped")
  echo $skipped
  ;;
  "cancelled")
  echo $skipped
  ;;
  "none")
    echo $skipped
    ;;
  *)
    echo $working
    ;;
esac
}

init() {
    local actor="$1"
    local projectName="$2"
    local bundleVersionCode="$3"
    local platform="$4"
    local buildType="$5"
    local commitLink="$6"
    local actionLink="$7"
    local slackmessage=$(cat "$slackMessagePath")
    local slackmessage=$(printf "$slackmessage" | sed "s/inputs.actor/$actor/g")
    local slackmessage=$(printf "$slackmessage" | sed "s/inputs.project-name/$projectName/g")
    local slackmessage=$(printf "$slackmessage" | sed "s/inputs.bundle-version-code/$bundleVersionCode/g")
    local slackmessage=$(printf "$slackmessage" | sed "s/inputs.platform/$platform/g")
    local slackmessage=$(printf "$slackmessage" | sed "s/inputs.build-type/$buildType/g")
    local slackmessage=$(printf "$slackmessage" | sed "s#inputs.commit-link#$commitLink#g")
    local slackmessage=$(printf "$slackmessage" | sed "s#inputs.action-link#$actionLink#g")
    printf "%s\n" "$slackmessage" > "$slackMessagePath"

}

newTask () {
    local text=$1

    local num_lineas=$(($(wc -l < "$slackMessagePath") - 4))
    local header=$(head -n $num_lineas "$slackMessagePath")
    local footer=$(tail -n +$(($num_lineas + 1)) "$slackMessagePath")

    local task=$(cat "$slackTaskPath")
    local texto_original=">>TEXT<<"
    local nuevo_texto=$text
    local task=$(printf "$task" | sed "s/$texto_original/$nuevo_texto/")
    local slackmessage=$(printf "%b\n" "$header,\n$task\n$footer")
    printf "%s\n" "$slackmessage" > "$slackMessagePath"

}

updateStatus () {
    local task=$1
    local status=$2
    echo $task
    echo $status
    local slackmessage=$(cat "$slackMessagePath")
    local taskLn=$(($(awk -v task="$task" 'BEGIN{IGNORECASE=1} $0 ~ task {line=NR} END{print line}' <<< "$slackmessage") + 4))
    local slackmessage=$(sed "${taskLn}s/.*/        \"text\":\"${status}\"/" <<< "$slackmessage")
    sed -i "1s/.*/$(head -n 1 "$slackSummaryPath")${status}/" "$slackSummaryPath"
    printf "%s\n" "$slackmessage" > "$slackMessagePath"
}

end () {
    local buildType=$1
    local slackmessage=$(cat "$slackMessagePath")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/GitHub Action build :pepe_naruto:/GitHub Action build $(icon $(head -n 1 "$slackSummaryPath"))/g")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/:pepe_naruto:/$(icon "skipped")/g")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/#C2FAFB/$(color $(head -n 1 "$slackSummaryPath"))/g")
    printf "%s\n" "$slackmessage" > "$slackMessagePath"

    if [ "$buildType" == "Production" ]; then
      curl -H "Content-type: application/json" \
      --data "{\"channel\":\"$channelId\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"@channel :bell: <https://labcavegames.slack.com/archives/$channelId/$messageId| $projectName done> :bell:\" }}]}" \
      -H "Authorization: Bearer xoxb-7032279906-3834010697957-YKP37c6Omvf6prcJarulWWq2" \
      -X POST https://slack.com/api/chat.postMessage
    else
      curl -H "Content-type: application/json" \
     --data "{\"channel\":\"$channelId\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\":bell: <https://labcavegames.slack.com/archives/$channelId/$messageId| $projectName done> :bell:\" }}]}" \
     -H "Authorization: Bearer xoxb-7032279906-3834010697957-YKP37c6Omvf6prcJarulWWq2" \
     -X POST https://slack.com/api/chat.postMessage
    fi

    
}

endlink () {
    local buildType=$1
    local slackmessage=$(cat "$slackMessagePath")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/GitHub Action build :pepe_naruto:/GitHub Action build $(icon $(head -n 1 "$slackSummaryPath"))/g")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/:pepe_naruto:/$(icon "skipped")/g")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/#C2FAFB/$(color $(head -n 1 "$slackSummaryPath"))/g")
    printf "%s\n" "$slackmessage" > "$slackMessagePath"

     if [ "$buildType" == "Production" ]; then
       curl -H "Content-type: application/json" \
     --data "{\"channel\":\"$channelId\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"@channel :bell: <https://labcavegames.slack.com/archives/$channelId/$messageId| $projectName done> :bell: -> :link: <$task| BUILD LINK> :link: \" }}]}" \
     -H "Authorization: Bearer xoxb-7032279906-3834010697957-YKP37c6Omvf6prcJarulWWq2" \
     -X POST https://slack.com/api/chat.postMessage
    else
      curl -H "Content-type: application/json" \
     --data "{\"channel\":\"$channelId\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\":bell: <https://labcavegames.slack.com/archives/$channelId/$messageId| $projectName done> :bell: -> :link: <$task| BUILD LINK> :link: \" }}]}" \
     -H "Authorization: Bearer xoxb-7032279906-3834010697957-YKP37c6Omvf6prcJarulWWq2" \
     -X POST https://slack.com/api/chat.postMessage
    fi

   
}

cancelled () {
    
    local slackmessage=$(cat "$slackMessagePath")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/GitHub Action build :pepe_naruto:/GitHub Action build $(icon "cancelled")/g")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/:pepe_naruto:/$(icon "cancelled")/g")
    local slackmessage=$(printf "%s\n" "$slackmessage" | sed "s/#C2FAFB/$(color "cancelled")/g")
    printf "%s\n" "$slackmessage" > "$slackMessagePath"

    curl -H "Content-type: application/json" \
     --data "{\"channel\":\"$channelId\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"$(icon "cancelled") <https://labcavegames.slack.com/archives/$channelId/$messageId| $projectName done> $(icon "cancelled")\" }}]}" \
     -H "Authorization: Bearer xoxb-7032279906-3834010697957-YKP37c6Omvf6prcJarulWWq2" \
     -X POST https://slack.com/api/chat.postMessage
}


case "$type" in
  init)
    init "$actor" "$projectName" "$bundleVersionCode" "$platform" "$buildType" "$commitLink" "$actionLink"
    ;;
  newtask)
    newTask $task
    ;;
  taskstatus)
    updateStatus $task $(icon "$statusTask")
    ;;
  cancelled)
    cancelled 
    ;;
  endlink)
    endlink "$buildType"
    ;;
  end)
    end "$buildType"
    ;;
  *)
    echo "Opción no válida. Por favor, elige opcion1, opcion2 o opcion3."
    ;;
esac