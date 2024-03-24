FROM python:3.10.13

WORKDIR /flask-711

COPY app.py .
COPY requirements.txt .

RUN pip install -r requirements.txt

CMD ["python3", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers=4", "app:app"]