#!/bin/sh

# Start PostgreSQL
su -c "postgres -c config_file=/etc/postgresql/postgresql.conf" postgres &

# Wait for PostgreSQL to start (adjust the sleep time as needed)
sleep 5

# Check if the 'nominatim' role exists, and if not, create it
su -c "psql --username=postgres --dbname=postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='nominatim'\"" postgres | grep -q 1 || su -c "createuser -s nominatim" postgres

# Check if the 'www-data' role exists, and if not, create it
su -c "psql --username=postgres --dbname=postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='www-data'\"" postgres | grep -q 1 || su -c "createuser -SDR www-data" postgres
su -c "psql --username=postgres --dbname=postgres -tAc \"ALTER USER \\\"www-data\\\" WITH ENCRYPTED PASSWORD '$NOMINATIM_PASSWORD'\"" postgres

# Alter the passwords for the 'nominatim' and 'www-data' roles
su -c "psql --username=postgres --dbname=postgres -tAc \"ALTER USER nominatim WITH ENCRYPTED PASSWORD '$NOMINATIM_PASSWORD'\"" postgres
su -c "psql --username=postgres --dbname=postgres -tAc \"ALTER USER \\\"www-data\\\" WITH ENCRYPTED PASSWORD '$NOMINATIM_PASSWORD'\"" postgres


# Keep the script running
tail -f /dev/null
