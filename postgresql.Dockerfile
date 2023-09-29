FROM alpine:latest

# Set environment variables for PostgreSQL
ENV PGDATA /var/lib/postgresql/data
ENV POSTGRES_USER nominatim
ENV POSTGRES_PASSWORD nominatim
ENV POSTGRES_DB nominatim
ENV LOG_FILE /var/log/postgresql.log
ENV NOMINATIM_PASSWORD js3R5ddh5u

# Install PostgreSQL 16, PostGIS, and PostgreSQL client utilities (including PostGIS utilities)
RUN apk --update add postgresql postgresql-contrib postgis postgresql-client && \
    rm -rf /var/cache/apk/*

# Copy the custom postgresql.conf to the container
COPY postgresql.conf /etc/postgresql/postgresql.conf

# Copy entrypoint script
COPY postgresql-entrypoint.sh /postgresql-entrypoint.sh

# Create the directory for the lock file
RUN mkdir -p /run/postgresql && chown postgres:postgres /run/postgresql

# Initialize the PostgreSQL database cluster
RUN mkdir -p "$PGDATA" && chown -R postgres "$PGDATA" && chmod 700 "$PGDATA" && \
    su postgres -c "initdb --encoding=UTF8 --locale=en_US.UTF-8 --data-checksums"

# Expose the PostgreSQL port
EXPOSE 5432

# Start PostgreSQL when the container runs
ENTRYPOINT [ "/postgresql-entrypoint.sh" ]
