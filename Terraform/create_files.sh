export $(terraform output | sed 's/ *//g')
printf \
"FROM python:3.6.0-alpine

COPY requirements.txt /requirements.txt
COPY requirements-test.txt /requirements-test.txt
RUN pip install -r /requirements.txt -r /requirements-test.txt

ENV MONGO=${mongo_ip}
ENV MONGO_PORT=27017
ENV RMQ_HOST=${rabbitmq_ip}
ENV RMQ_QUEUE=raq
ENV RMQ_USERNAME=user
ENV RMQ_PASSWORD=password
ENV CHECK_INTERVAL=30
ENV EXCLUDE_URLS=.*github.com
ENV URL=https://vitkhab.github.io/search_engine_test_site/

ENTRYPOINT [ 'python', '-u', 'crawler/crawler.py' ]
CMD [ 'https://vitkhab.github.io/search_engine_test_site/' ]
" > ../ansible/files/crawler_Dockerfile

printf \
"FROM python:3.6.0-alpine

COPY requirements.txt /requirements.txt
COPY requirements-test.txt /requirements-test.txt
RUN pip install -r /requirements.txt -r /requirements-test.txt

ENV MONGO=${mongo_ip}
ENV MONGO_PORT=27017

CMD [ 'cd ui && FLASK_APP=ui.py gunicorn ui:app -b 0.0.0.0' ]
" > ../ansible/files/ui_Dockerfile

printf "[all]
" > ../ansible/inventory
terraform output | sed 's/ = / ansible_host=/g' >> ../ansible/inventory