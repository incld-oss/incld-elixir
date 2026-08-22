# Contributing

Issues and focused pull requests are welcome. Run the complete local checks
before submitting a pull request:

```bash
mix deps.get
mix format --check-formatted
mix test
mix hex.build
```

Public API changes must include tests and documentation. Never include API keys,
webhook secrets, access tokens, or customer payloads in fixtures or reports.
