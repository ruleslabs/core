# Rules protocol

Core smart contracts of the Rules protocol.
- for marketplace contracts, see [marketplace](https://github.com/ruleslabs/marketplace) repository.
- for pack opening contracts, see [pack-opener](https://github.com/ruleslabs/pack-opener) repository.

## Overview

Rules protocol is composed of 4 contracts interacting with each other.

`RulesData`, `RulesCards` and `RulesPacks` are responsible for all the logic and data storage.

`RulesTokens` implements the ERC-1155 standard, and uses other contracts logic to manage its tokens.

### RulesData

`RulesData` is responsible for holding the most basic informations, currently its only utility is to store artists names.

#### @externals

##### `createArtist`:

Create an artists if it does not already exist.

- ###### parameters
  - `artist_name: Uint256`: the artist name (must be at most 27 characters long)

### RulesCards

`RulesCard` handles cards, their scarcities, their supply and can be used to stop the production for the given scarcity level of a season.

#### cards, card models, scarcities and seasons

A card is a struct composed like bellow, and the main purpose of this contract is to store cards.

```cairo
struct Card:
  member model: CardModel
  member serial_number: felt # uint24
end

struct CardModel:
  member artist_name: Uint256
  member season: felt # uint8
  member scarcity: felt # uint8
end
```

As you can see, each card is associated to a card model, itself associated to a season and a scarcity level.

Scarcity levels are used to control the max supply of a card model and exists in the context of a season, which means a scarcity `n` can have a different max supply from one season to another.
For each possible season, it exists by default the scarcity level `0`, the only scarcity level with an infinite max supply.

#### @externals

##### `addScarcityForSeason`:

Add a new scarcity level to a given season.

- ###### parameters
  - `season: felt`: the season for which to create the scarcity level.

  - `supply: felt`: the max supply of the scarcity level to create.

##### `stopProductionForSeasonAndScarcity`:

Definitively Stop the production of new cards for the scarcity level of a given season.

- ###### parameters
  - `season: felt`

  - `scarcity: felt`

##### `createCard`

Store card informations in a `Uint256`, and use it as a card identifier.
If the card informations are invalid, that the scarcity provided does not allow more card creation, or if the card already exists, the transaction will fail.

- ###### parameters
  - `card: Card`:

    - `model: CardModel`:

      - `artist_name: Uint256`: must exist in `RulesData`

      - `season: felt`: must be non null and fit in 8 bits

      - `scarcity: felt`: must fit in 8 bits, and exist in the given season

    - `serial_number: felt`: must be non null and fit in 24 bits

- ###### return value
  - `card_id: Uint256` the card identifier

##### `packCardModel`

Increase the packed supply of a card model, in other terms, the quantity of cards in packs. If not enough supply is available for the card model, or if the card model is invalid, the transaction will fail.

- ###### parameters
  - `pack_card_model: PackCardModel`:

    - `card_model: CardModel`

    - `quantity: felt`: the amount of cards to pack

### RulesPacks

#### Packs and common packs

A pack is a list of card models with, optionally, a quantity for each card model, and a number of cards per minted pack. According to the card models quantities and the number of cards per pack, the contract will deduce the pack max supply.

`pack max supply = sum of card models quantities / number of cards per pack`

Given that [cards created with the scarcity level `0` have an unlimited max supply](#cards-card-models-scarcities-and-seasons), it allows to create packs with only card models of scarcity level `0`, and so, to create packs with an unlimited max supply as well.  
We are calling these packs **common packs**

##### `createPack`

Create a new pack with a deduced max supply, card models with any valid season and scarcity levels can be provided as long as the available supply of these card models is enough regarding to the pack card models quantities

```cairo
struct PackCardModel:
  member card_model: CardModel
  member quantity: felt
end
```

- ###### parameters
  - `cards_per_pack: felt`

  - `pack_card_models: PackCardModel*`

  - `metadata: Metadata`: see [metadata section](#metadata)

- ###### return value
  - `pack_id: Uint256`: id of the newly created pack. For packs with a limited max supply the nth created pack have the id `Uint256(low=n, high=0)`

##### `createCommonPack`

Create a new common pack, with all the present and future card models of scarcity level `0` of a given season.

- ###### parameters
  - `cards_per_pack: felt`

  - `season: felt`: must be a valid season and no other common pack of the same season must exist.

  - `metadata: Metadata`: see [metadata section](#metadata)

- ###### return value
  - `pack_id: Uint256`: id of the newly created pack. For common packs the id is such that `Uint256(low=0, high=season)`

### RulesTokens

`RulesToken` is the protocol's keystone, this ERC-1155 contract handles all the tokens logic.  
Rules tokens are indivisible, cards have a max supply of 1 (basically, it's NFTs), and packs have a max supply calculated by the [`RulesPacks`](#rulespacks) contract.

##### `createAndMintCard`

Create a card in [`RulesCards`](#rulescards) and mint its associated token to the recipient address.

- ###### parameters
  - `card: Card`: the card to create and mint, it must be unique and not minted yet.

  - `metadata: Metadata*`: see [metadata section](#metadata).

  - `to: felt`: address to send the newly minted card token.

##### `openPackTo`

Pack opening is the mechanism by which a pack token will be burned and `cards_per_pack` card tokens will be minted.

The transfer of cards to the recipient address is not safe, this is done to avoid a Reetrancy attack which could allow a malicious
contract to make the pack opening fail during the transfer acceptance check, if the selected cards does not suit it.

Also, to ensure the impossibility of invalidating an opening transaction in progress, it is important to make sure that the pack
has been moved to a secure pack opening contract. See the pack opener contract at [periphery](https://github.com/ruleslabs/periphery)
for more information.

- ###### parameters
  - `to: felt`: address to send the newly minted cards.

  - `pack_id: felt`: the id of the pack to open.

  - `cards: Card*`: the cards to mint. Like [`createAndMintCard`](#createandmintcard) does, they will be created in
  [`RulesCards`](#rulescards) first, then, corresponding card tokens will be minted.

  - `metadata: Metadata*`: see [metadata section](#metadata).

### Metadata

### Access Control

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
starknet declare artifacts/RulesData.json
starknet declare artifacts/RulesCards.json
starknet declare artifacts/RulesPacks.json
starknet declare artifacts/RulesTokens.json

nile deploy Proxy [RULES_DATA_CLASS_HASH]
nile deploy RulesCards [RULES_CARDS_CLASS_HASH]
nile deploy RulesPacks [RULES_PACKS_CLASS_HASH]
nile deploy RulesTokens [RULES_TOKENS_CLASS_HASH]
```
