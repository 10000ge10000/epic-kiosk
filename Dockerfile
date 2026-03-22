FROM python:3.10-slim

WORKDIR /app

# 预创建挂载点目录（解决飞牛 NAS 等 Docker 存储驱动兼容性问题）
RUN mkdir -p /app/data

RUN pip install --no-cache-dir \
    fastapi uvicorn redis apscheduler aiofiles python-multipart jinja2 httpx

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]