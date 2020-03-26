Bells and whistles
==================

Simple hacks used to ensure sensibility on gathering.org and related
services.

Testing and running
-------------------

See Dockerfile for how to build it. It's nothing fancy.

We run this as regular one-off docker container, but can also be run
as Kubernetes, e.g. GKE. Kubernetes deployment examples is found
under build/.

You can test it locally by just running ``./test_shit.sh``, or optionally
building the container and running that.

An automated script for running this could be as simple as::

      #!/bin/bash

      # Create docker image (very quick build time)
      docker build -t bells_and_whistles .

      # Run image and mount local config/playbook file
      # (you don't want this as part of your image since it contains secret slack token)
      docker run -v $(pwd)/build/bells_and_whistles_to_slack.yml:/ansible/bells_and_whistles_to_slack.yml bells_and_whistles

Automated tests are done periodically, and the results are posted to
Core:Systems' Slack channel.

Automatic image build
.....................

The image referenced in the various deploy files is automatically built on
git push. This happens in Google Cloud Container Registry, under build
triggers.

The build trigger does not, at present, trigger an actual test. Just a
build. Build time varies, but is typically less than a minute from git
push.

``build/bells_and_whistles_to_slack.yml.dist``
...............................................

This a template(!) used to create a secret. Copy it to
``bells_and_whistles_to_slack.yml``, inject the correct slack token, then
run::

        kubectl create secret generic bells-and-whistles  \
          --from-file=bells_and_whistles_to_slack.yml

This creates a secret (e.g.: password store of sorts), which is visible to
everyone in the namespace. DO NOT COMMIT the file to git, I do not want
random strangers sending messages to our slack channel.

``build/cronjob.yaml``
......................

Core cronjob spec, this is what ensures that things run periodically. Does
not require modifications before deployment. Feel free to adjust the
timing, but remember: it's UTC, not CET.

``build/job.yaml``
..................

Same as CronJob, but provided to enable one-off runs. To start a single
test run::

        kubectl create -f job.yml

        # or:

        kubectl replace --force -f job.yml
