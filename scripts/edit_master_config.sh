#!/bin/bash

sed -i "s/projectRequestTemplate: ''/projectRequestTemplate: \"default\/project-request\"/g" /etc/origin/master/master-config.yaml
/usr/local/bin/master-restart api
/usr/local/bin/master-restart controllers
