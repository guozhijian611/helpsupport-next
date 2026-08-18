FROM mysql:8.0.45

COPY Database/b8aiadmin.sql /docker-entrypoint-initdb.d/001-b8aiadmin.sql
