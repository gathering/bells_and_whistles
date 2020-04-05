FROM debian:testing
RUN apt-get update
RUN apt-get install -y make openssl httpie gawk wget moreutils ansible curl
ADD . /
CMD ansible-playbook -i localhost, /ansible/bells_and_whistles_to_slack.yml -c local
