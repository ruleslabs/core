use traits::{ Into, TryInto };
use array::{ ArrayTrait, SpanSerde };
use zeroable::Zeroable;
use option::OptionTrait;

use super::voucher::Voucher;

const METADATA_MULTIHASH_IDENTIFIER: u16 = 0x1220;

// Metadata

#[derive(Serde, Copy, Drop)]
struct Metadata {
  hash: Span<felt252>,
}

// Scarcity

#[derive(Serde, Copy, Drop)]
struct Scarcity {
  max_supply: u128,
  name: felt252,
}

// Card model

#[derive(Serde, Copy, Drop)]
struct CardModel {
  artist_name: felt252,
  season: felt252,
  scarcity_id: felt252,
}

// Pack

#[derive(Serde, Copy, Drop)]
struct Pack {
  name: felt252,
}

// Token id

#[derive(Serde, Drop)]
struct TokenId {
  id: u256,
}

// TODO: pack support
#[derive(Drop)]
struct PackToken {
  pack_id: u128,
  id: u256,
}

#[derive(Drop)]
struct CardToken {
  card_model_id: u128,
  serial_number: u128,
  id: u256,
}

enum Token {
  card: CardToken,
  pack: PackToken,
}

//
// Interfaces
//

#[starknet::interface]
trait IRulesTokens<TContractState> {
  fn contract_uri(self: @TContractState) -> Span<felt252>;

  fn marketplace(self: @TContractState) -> starknet::ContractAddress;

  fn card_exists(self: @TContractState, card_token_id: u256) -> bool;

  fn set_contract_uri(ref self: TContractState, contract_uri_: Span<felt252>);

  fn set_marketplace(ref self: TContractState, marketplace_: starknet::ContractAddress);

  fn redeem_voucher(ref self: TContractState, voucher: Voucher, signature: Span<felt252>);

  fn redeem_voucher_to(
    ref self: TContractState,
    to: starknet::ContractAddress,
    voucher: Voucher,
    signature: Span<felt252>
  );

  fn set_royalties_receiver(ref self: TContractState, new_receiver: starknet::ContractAddress);

  fn set_royalties_percentage(ref self: TContractState, new_percentage: u16);
}

#[starknet::interface]
trait IRulesTokensCamelCase<TContractState> {
  fn contractURI(self: @TContractState) -> Span<felt252>;
}

#[starknet::interface]
trait IRulesData<TContractState> {
  fn card_model(self: @TContractState, card_model_id: u128) -> CardModel;

  fn pack(self: @TContractState, pack_id: u128) -> Pack;

  fn card_model_metadata(self: @TContractState, card_model_id: u128) -> Metadata;

  fn pack_metadata(self: @TContractState, pack_id: u128) -> Metadata;

  fn scarcity(self: @TContractState, season: felt252, scarcity_id: felt252) -> Scarcity;

  fn uncommon_scarcities_count(self: @TContractState, season: felt252) -> felt252;

  fn add_card_model(ref self: TContractState, new_card_model: CardModel, metadata: Metadata) -> u128;

  fn add_pack(ref self: TContractState, new_pack: Pack, metadata: Metadata) -> u128;

  fn add_scarcity(ref self: TContractState, season: felt252, scarcity: Scarcity);

  fn set_card_model_metadata(ref self: TContractState, card_model_id: u128, metadata: Metadata);

  fn set_pack_metadata(ref self: TContractState, pack_id: u128, metadata: Metadata);
}

#[starknet::interface]
trait IRulesMessages<TContractState> {
  fn voucher_signer(self: @TContractState) -> starknet::ContractAddress;

  fn consume_valid_voucher(ref self: TContractState, voucher: Voucher, signature: Span<felt252>);
}
