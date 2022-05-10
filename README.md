# Rules V1

Core smart contracts of the Rules V1 protocol, for marketplace contracts, see [marketplace](https://github.com/ruleslabs/marketplace) repository.

## Local development

### Compile contracts

```bash
nile compile src/ruleslabs/contracts/Rules*/Rules*.cairo --directory src
```

### Run tests

```bash
tox tests/test.py
```

### Deploy contracts

```bash
nile deploy RulesData <owner>
nile deploy RulesCards <owner> <rules_data>
nile deploy RulesPacks <owner> <rules_cards>
nile deploy RulesTokens <name> <symbol> <owner> <rules_cards> <rules_packs>
```
