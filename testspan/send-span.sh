#!/bin/bash

# https://docs.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad

# Set the `errexit` option to make sure that
# if one command fails, all the script execution
# will also fail (see `man bash` for more 
# information on the options that you can set).
set -o errexit

main () {
    while getopts "h" option; 
    do
        case $option in
            h) # display Help
                Help
                exit;;
            \?) # Invalid option
                echo "Error: Invalid option"
                exit;;
        esac
    done
    SendSpan
}
SendSpan(){
    serverURI="http://kube.local/zipkin/api/v2/spans"
    serverOTEL="http://kube.local/otel/v1/traces"
    traceID=$(dbus-uuidgen)
    echo $traceID
    remoteDuration=$((40000))
    server2Duration=$((1480000+$remoteDuration))
    server1Duration=$((5000+$server2Duration+$remoteDuration))
    clientDuration=$((1000+$server1Duration))
    # send client trace
    echo "Send client trace:"
    timestampClient=$(((${EPOCHSECONDS/./} ) * 1000000))
    sed -i "s|TRACE_ID|$traceID|g" ./test-client.json
    sed -i "s|DURATION_SPAN|$clientDuration|g" ./test-client.json
    sed -i "s|TIMESTAMP_SPAN|$timestampClient|g" ./test-client.json
    curl --insecure --write-out "%{http_code}\n" -X POST $serverURI --data "@./test-client.json" -H  "accept: application/json" -H  "Content-Type: application/json" -H "X-B3-TraceId: $traceID" 
    sed -i "s|$traceID|TRACE_ID|g" ./test-client.json
    sed -i "s|$timestampClient|TIMESTAMP_SPAN|g" ./test-client.json
    sed -i "s|$clientDuration|DURATION_SPAN|g" ./test-client.json
    # send server trace
    echo "Send server trace:"
    timestampServer1=$(((${EPOCHSECONDS/./} ) * 1000000))
    sed -i "s|TRACE_ID|$traceID|g" ./test-server.json
    sed -i "s|DURATION_SPAN|$server1Duration|g" ./test-server.json
    sed -i "s|TIMESTAMP_SPAN|$timestampServer1|g" ./test-server.json
    curl --insecure --write-out "%{http_code}\n" -X POST $serverURI --data "@./test-server.json" -H  "accept: application/json" -H  "Content-Type: application/json" -H "X-B3-TraceId: $traceID" 
    sed -i "s|$traceID|TRACE_ID|g" ./test-server.json
    sed -i "s|$timestampServer1|TIMESTAMP_SPAN|g" ./test-server.json
    sed -i "s|$server1Duration|DURATION_SPAN|g" ./test-server.json
    # send server trace
    echo "Send server 2 trace:"
    timestampServer2=$((((${EPOCHSECONDS/./} ) * 1000000)+$remoteDuration))
    sed -i "s|TRACE_ID|$traceID|g" ./test-server2.json
    sed -i "s|DURATION_SPAN|$server2Duration|g" ./test-server2.json
    sed -i "s|TIMESTAMP_SPAN|$timestampServer2|g" ./test-server2.json
    curl --insecure --write-out "%{http_code}\n" -X POST $serverURI --data "@./test-server2.json" -H  "accept: application/json" -H  "Content-Type: application/json" -H "X-B3-TraceId: $traceID" 
    sed -i "s|$traceID|TRACE_ID|g" ./test-server2.json
    sed -i "s|$timestampServer2|TIMESTAMP_SPAN|g" ./test-server2.json
    sed -i "s|$server2Duration|DURATION_SPAN|g" ./test-server2.json
    # send remote server trace
    echo "Send remote server trace:"
    timestampRemoteServer=$((((${EPOCHSECONDS/./} ) * 1000000)+($remoteDuration*2)))
    timestampRemoteServerStartRemote=$(($timestampRemoteServer+($remoteDuration*2)))
    timestampRemoteServerStopRemote=$(($timestampRemoteServerStartRemote+($remoteDuration*2)))
    timestampRemoteServerDuration=$(($remoteDuration*6))
    sed -i "s|TRACE_ID|$traceID|g" ./test-remoteserver.json
    sed -i "s|DURATION_SPAN|$timestampRemoteServerDuration|g" ./test-remoteserver.json
    sed -i "s|TIMESTAMP_SPAN|$timestampRemoteServer|g" ./test-remoteserver.json
    sed -i "s|START_REMOTE|$timestampRemoteServerStartRemote|g" ./test-remoteserver.json
    sed -i "s|STOP_REMOTE|$timestampRemoteServerStopRemote|g" ./test-remoteserver.json
    curl --insecure --write-out "%{http_code}\n" -X POST $serverURI --data "@./test-remoteserver.json" -H  "accept: application/json" -H  "Content-Type: application/json" -H "X-B3-TraceId: $traceID" 
    sed -i "s|$traceID|TRACE_ID|g" ./test-remoteserver.json
    sed -i "s|$timestampRemoteServer|TIMESTAMP_SPAN|g" ./test-remoteserver.json
    sed -i "s|$timestampRemoteServerStartRemote|START_REMOTE|g" ./test-remoteserver.json
    sed -i "s|$timestampRemoteServerStopRemote|STOP_REMOTE|g" ./test-remoteserver.json
    sed -i "s|$timestampRemoteServerDuration|DURATION_SPAN|g" ./test-remoteserver.json
    # send server trace
    echo "Send server 3 trace:"
    timestampServer3=$(($timestampClient + $server2Duration))
    sed -i "s|TRACE_ID|$traceID|g" ./test-server3.json
    sed -i "s|DURATION_SPAN|$remoteDuration|g" ./test-server3.json
    sed -i "s|TIMESTAMP_SPAN|$timestampServer3|g" ./test-server3.json
    curl --insecure --write-out "%{http_code}\n" -X POST $serverURI --data "@./test-server3.json" -H  "accept: application/json" -H  "Content-Type: application/json" -H "X-B3-TraceId: $traceID" 
    sed -i "s|$traceID|TRACE_ID|g" ./test-server3.json
    sed -i "s|$timestampServer3|TIMESTAMP_SPAN|g" ./test-server3.json
    sed -i "s|$remoteDuration|DURATION_SPAN|g" ./test-server3.json
    # send server trace
    echo "Send otel trace:"
    timestampotel=$(date +'%s%9N') 
    durationotel=$((10000000+$timestampotel))
    sed -i "s|TRACE_ID|$traceID|g" ./test-otel.json
    sed -i "s|DURATION_SPAN|$durationotel|g" ./test-otel.json
    sed -i "s|TIMESTAMP_SPAN|$timestampotel|g" ./test-otel.json
    curl --insecure --write-out "%{http_code}\n" -X POST $serverOTEL --data "@./test-otel.json" -H  "accept: application/json" -H  "Content-Type: application/json" -H "X-B3-TraceId: $traceID" 
    sed -i "s|$traceID|TRACE_ID|g" ./test-otel.json
    sed -i "s|$timestampotel|TIMESTAMP_SPAN|g" ./test-otel.json
    sed -i "s|$durationotel|DURATION_SPAN|g" ./test-otel.json
    
}
Help() {
   # Display Help
   echo "script to send span to zipkin."
   echo
   echo "Syntax: send-span [-h] "
   echo "options:"
   echo "h     Print this Help."
   echo
}
main "$@"