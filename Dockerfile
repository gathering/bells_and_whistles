FROM debian:testing
RUN apt-get update
RUN apt-get install -y make openssl httpie gawk wget moreutils ansible
ADD . /
WORKDIR /
CMD ansible-playbook -i localhost, bells_and_whistles_to_slack.yml
