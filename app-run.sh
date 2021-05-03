#!/usr/bin/env bash

set -ex

export $(cat .env|grep SPRING_DATASOURCE|xargs)
gradle :application:bootRun

