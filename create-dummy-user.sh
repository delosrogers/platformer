#!/bin/bash
curl --header "Content-Type: application/json"\
 --request POST\
 --data '{"name":"mattias"}' http://localhost:3000/api/v1/u