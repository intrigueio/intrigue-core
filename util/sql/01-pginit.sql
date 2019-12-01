/* This file is use configure the postgres server prior to max_connections */
/* from web or worker instances */

/* Create a user */
CREATE DATABASE intriguedb;
/* Set a password */
CREATE USER intrigue WITH PASSWORD 'intrigue';
/* Create a database */
GRANT ALL PRIVILEGES ON DATABASE intriguedb TO intrigue;
