# Install

Take care that the `pg_config` command is available in your path

```
cd monitoring_role
make install USE_PGXS=1
```

# Test

```
create database monitoring;
create role monitor login;
\c monitoring monitor
select * from pg_ls_dir('.');
\c monitoring postgres
create schema monitoring;
create extension monitoring_role schema monitoring;
select monitoring.grant_monitor('monitor');
ALTER ROLE monitor SET search_path = monitoring, pg_catalog, public;
\c monitoring monitor
select * from pg_ls_dir('.');
\q
```

# About

This extension has been written by Thomas Reiss

