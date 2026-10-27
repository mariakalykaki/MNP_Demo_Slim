# Number Activation

Small telecom number-activation service (.NET + Oracle).

## Run locally

```bash
cp .env.example .env                         # first time only: fill ORACLE_PASSWORD and APP_USER_PASSWORD
podman compose --env-file .env up -d         # Oracle on host port 1522; wait for "DATABASE IS READY TO USE!"
scripts/db-apply.sh                          # schema, packages (database/packages), seeds, checks
scripts/run-local.sh                         # API :5100, mock carrier :5101, worker
scripts/demo.sh                              # in another terminal: end-to-end demo, ~2 min, needs a fresh database
```

```bash
curl -X POST localhost:5100/api/activations -H 'content-type: application/json' \
  -d '{"msisdn":"+306900000101","customerId":"C-1001","customerType":"POSTPAID","idVerified":true,"planCode":"PRO"}'
curl localhost:5100/api/activations/<id>
curl -X POST localhost:5100/api/activations/<id>/confirm
curl -X POST localhost:5100/api/activations/<id>/review -H 'content-type: application/json' -d '{"decision":"APPROVE"}'
curl -X POST localhost:5100/api/activations/<id>/cancel
```

## Tests

```bash
dotnet build && dotnet test                  # unit tests; integration tests are skipped without a connection string
# Integration tests against the local Oracle (stop the worker first: it would take the outbox rows)
ConnectionStrings__Oracle="User Id=na_app;Password=<APP_USER_PASSWORD>;Data Source=localhost:1522/FREEPDB1;" dotnet test tests/Na.IntegrationTests
```

## Reset to a clean database

```bash
podman compose --env-file .env down -v && podman compose --env-file .env up -d && scripts/db-apply.sh
```

`database/packages/` holds the PL/SQL package specs (`.pks`) and bodies (`.pkb`), the same code as in
`database_export_with_seed_data.sql`. `db-apply.sh` applies every spec before any body.
