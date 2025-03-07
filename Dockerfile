FROM python:3-alpine3.15
WORKDIR /app
COPY . /app
RUN pip install -r requirement.txt
EXPOSE 3000
CMD ["python3","app.py"]