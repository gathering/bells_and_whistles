#!/bin/bash
docker build -t bells_and_whistles:1.0 .
docker run --rm -v $(pwd)/build/bells_and_whistles_to_slack.yml:/ansible/bells_and_whistles_to_slack.yml --network webproxy bells_and_whistles:1.0
