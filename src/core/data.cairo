use zeroable::Zeroable;
use traits::Into;
use integer::{ U128Zeroable, U256Zeroable };

// locals
use super::interface::{ Scarcity, CardModel, Pack, Metadata, METADATA_MULTIHASH_IDENTIFIER };

const COMMON_SCARCITY_MAX_SUPPLY: u128 = 0xffffffffffffffffffffffffffffffff;
const COMMON_SCARCITY_NAME: felt252 = 'Common';

#[starknet::interface]
trait RulesDataABI<TContractState> {
  fn card_model(self: @TContractState, card_model_id: u128) -> CardModel;

  fn scarcity(self: @TContractState, season: felt252, scarcity_id: felt252) -> Scarcity;

  fn uncommon_scarcities_count(self: @TContractState, season: felt252) -> felt252;

  fn add_card_model(
    ref self: TContractState,
    new_card_model: CardModel,
    animation_metadata: Metadata,
    image_metadata: Metadata
  ) -> u128;

  fn add_scarcity(ref self: TContractState, season: felt252, scarcity: Scarcity);
}

#[starknet::contract]
mod RulesData {
  use zeroable::Zeroable;
  use traits::Into;

  use rules_utils::utils::base64::Base64;
  use rules_utils::utils::array::ArrayTraitExt;
  use rules_utils::utils::strings::Strings;

  // locals
  use rules_tokens::core::interface;
  use rules_tokens::core::interface::{ IRulesData };

  use rules_tokens::utils::storage::{ StoreScarcity, StoreCardModel, StorePack, StoreMetadata };
  use rules_tokens::utils::zeroable::{ CardModelZeroable, PackZeroable, ScarcityZeroable };

  use super::{ Scarcity, ScarcityTrait, CardModel, CardModelTrait, Pack, PackTrait, Metadata, MetadataTrait };

  //
  // Storage
  //

  #[storage]
  struct Storage {
    // season -> uncommon scarcities count
    _uncommon_scarcities_count: LegacyMap<felt252, felt252>,
    // (season, scarcity_id) -> Scarcity
    _scarcities: LegacyMap<(felt252, felt252), Scarcity>,

    // card_model_id -> CardModel
    _card_models: LegacyMap<u128, CardModel>,
    // card_model_id -> Image Metadata
    _card_models_image_metadata: LegacyMap<u128, Metadata>,
    // card_model_id -> Animation Metadata
    _card_models_animation_metadata: LegacyMap<u128, Metadata>,

    // pack_id -> Pack
    _packs: LegacyMap<u128, Pack>,
    // number of packs already created
    _packs_count: u128,
    // pack_id -> Metadata
    _packs_image_metadata: LegacyMap<u128, Metadata>,
  }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState) { }

  //
  // IRulesData impl
  //

  impl IRulesDataImpl of interface::IRulesData<ContractState> {
    fn card_model(self: @ContractState, card_model_id: u128) -> CardModel {
      self._card_models.read(card_model_id)
    }

    fn pack(self: @ContractState, pack_id: u128) -> Pack {
      self._packs.read(pack_id)
    }

    fn card_model_image_metadata(self: @ContractState, card_model_id: u128) -> Metadata {
      self._card_models_image_metadata.read(card_model_id)
    }

    fn card_model_animation_metadata(self: @ContractState, card_model_id: u128) -> Metadata {
      self._card_models_animation_metadata.read(card_model_id)
    }

    fn pack_image_metadata(self: @ContractState, pack_id: u128) -> Metadata {
      self._packs_image_metadata.read(pack_id)
    }

    fn scarcity(self: @ContractState, season: felt252, scarcity_id: felt252) -> Scarcity {
      if (scarcity_id.is_zero()) {
        ScarcityTrait::common()
      } else {
        self._scarcities.read((season, scarcity_id))
      }
    }

    fn uncommon_scarcities_count(self: @ContractState, season: felt252) -> felt252 {
      self._uncommon_scarcities_count.read(season)
    }

    fn add_card_model(
      ref self: ContractState,
      new_card_model: CardModel,
      image_metadata: Metadata,
      animation_metadata: Metadata
    ) -> u128 {
      // assert card model and metadata are valid
      assert(new_card_model.is_valid(), 'Invalid card model');
      assert(image_metadata.is_valid(), 'Invalid image metadata');
      assert(animation_metadata.is_valid(), 'Invalid animation metadata');

      // assert card model does not already exists
      let card_model_id = new_card_model.id();
      assert(self.card_model(:card_model_id).is_zero(), 'Card model already exists');

      // assert scarcity exists
      let scarcity_ = self.scarcity(season: new_card_model.season, scarcity_id: new_card_model.scarcity_id);
      assert(scarcity_.is_non_zero(), 'Scarcity does not exists');

      // save card model and metadata
      self._card_models.write(card_model_id, new_card_model);
      self._card_models_image_metadata.write(card_model_id, image_metadata);
      self._card_models_animation_metadata.write(card_model_id, animation_metadata);

      // return card model id
      card_model_id
    }

    fn add_pack(ref self: ContractState, new_pack: Pack, image_metadata: Metadata) -> u128 {
      // assert pack name and metadata are valid
      assert(new_pack.is_valid(), 'Invalid pack');
      assert(image_metadata.is_valid(), 'Invalid image metadata');

      // get new pack id
      let pack_id = self._packs_count.read() + 1;

      // save card model and metadata
      self._packs.write(pack_id, new_pack);
      self._packs_image_metadata.write(pack_id, image_metadata);

      // increase pack count
      self._packs_count.write(pack_id);

      // return card model id
      pack_id
    }

    fn add_scarcity(ref self: ContractState, season: felt252, scarcity: Scarcity) {
      assert(scarcity.is_valid(), 'Invalid scarcity');

      // get new scarcities count
      let new_uncommon_scarcities_count = self.uncommon_scarcities_count(season) + 1;

      self._uncommon_scarcities_count.write(season, new_uncommon_scarcities_count);
      self._scarcities.write((season, new_uncommon_scarcities_count), scarcity);
    }

    // Set Metadata

    fn set_card_model_metadata(
      ref self: ContractState,
      card_model_id: u128,
      image_metadata: Metadata,
      animation_metadata: Metadata
    ) {
      // assert card model already exists
      assert(self.card_model(:card_model_id).is_non_zero(), 'Card model does not exists');

      // save metadata
      self._card_models_image_metadata.write(card_model_id, image_metadata);
      self._card_models_animation_metadata.write(card_model_id, animation_metadata);
    }

    fn set_pack_metadata(ref self: ContractState, pack_id: u128, image_metadata: Metadata) {
      // assert card model already exists
      assert(self.pack(:pack_id).is_non_zero(), 'Pack does not exists');

      // save metadata
      self._packs_image_metadata.write(pack_id, image_metadata);
    }
  }

  //
  // Internals
  //

  #[generate_trait]
  impl InternalImpl of InternalTrait {
    fn _card_uri(self: @ContractState, card_model_id: u128, serial_number: u128) -> Array<felt252> {
      let card_model = self.card_model(:card_model_id);
      let scarcity = self.scarcity(season: card_model.season, scarcity_id: card_model.scarcity_id);
      let image_metadata = self.card_model_image_metadata(:card_model_id);
      let animation_metadata = self.card_model_animation_metadata(:card_model_id);

      let mut ret = array!['{"image":"ipfs://'];

      // append metadata
      ret = ret.concat(image_metadata.hash.snapshot);
      ret.append('","animation_url":"ipfs://');
      ret = ret.concat(animation_metadata.hash.snapshot);

      // append onchain data
      let mut arr = array![
        '","name":"',
        card_model.artist_name,
        ' - ',
        scarcity.name,
        ' #',
        serial_number.into().itoa(),
        '","attributes":[{"trait_type":"',
        'Serial number","value":"',
        serial_number.into().itoa(),
        '"},{"trait_type":"Artist","valu',
        'e":"',
        card_model.artist_name,
        '"},{"trait_type":"Rarity","valu',
        'e":"',
        scarcity.name,
        '"},{"trait_type":"Season","valu',
        'e":"',
        card_model.season.itoa(),
        '"}]}',
      ];

      ret.append_all(ref :arr);

      // base64 encode and return
      ret = ret.encode();

      // add data URL prefix
      arr = array!['data:application/json;base64,'];
      arr.append_all(ref arr: ret);

      arr
    }

    fn _pack_uri(self: @ContractState, pack_id: u128) -> Array<felt252> {
      let pack = self.pack(:pack_id);
      let image_metadata = self.pack_image_metadata(:pack_id);

      let mut ret = array!['{"image":"ipfs://'];

      // append metadata
      ret = ret.concat(image_metadata.hash.snapshot);

      // append onchain data
      let mut arr = array![
        '","name":"',
        pack.name,
        '","attributes":[{"trait_type":"',
        'Season","value":"',
        pack.season.itoa(),
        '"}]}',
      ];

      ret.append_all(ref :arr);

      // base64 encode and return
      ret = ret.encode();

      // add data URL prefix
      arr = array!['data:application/json;base64,'];
      arr.append_all(ref arr: ret);

      arr
    }
  }
}

// Metadata trait

trait MetadataTrait {
  fn is_valid(self: Metadata) -> bool;
}

impl MetadataImpl of MetadataTrait {
  fn is_valid(self: Metadata) -> bool {
    self.hash.len() == 2
  }
}

// Scarcity trait

trait ScarcityTrait {
  fn is_valid(self: Scarcity) -> bool;

  fn common() -> Scarcity;
}

impl ScarcityImpl of ScarcityTrait {
  fn is_valid(self: Scarcity) -> bool {
    if (self.name.is_zero() | self.max_supply.is_zero()) {
      false
    } else {
      true
    }
  }

  fn common() -> Scarcity {
    Scarcity {
      max_supply: COMMON_SCARCITY_MAX_SUPPLY,
      name: COMMON_SCARCITY_NAME,
    }
  }
}

// Card model trait

trait CardModelTrait {
  fn is_valid(self: CardModel) -> bool;

  fn id(self: CardModel) -> u128;
}

impl CardModelImpl of CardModelTrait {
  fn is_valid(self: CardModel) -> bool {
    if (self.artist_name.is_zero() | self.season.is_zero()) {
      false
    } else {
      true
    }
  }

  fn id(self: CardModel) -> u128 {
    let mut hash = pedersen::pedersen(0, self.artist_name);
    hash = pedersen::pedersen(hash, self.season);
    hash = pedersen::pedersen(hash, self.scarcity_id);
    hash = pedersen::pedersen(hash, 3);

    Into::<felt252, u256>::into(hash).low
  }
}

// Pack trait

trait PackTrait {
  fn is_valid(self: Pack) -> bool;
}

impl PackImpl of PackTrait {
  fn is_valid(self: Pack) -> bool {
    self.name.is_non_zero() & self.season.is_non_zero()
  }
}
