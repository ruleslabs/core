import asyncio
import pytest
import dill
import os
import sys
from types import SimpleNamespace
import time

from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.business_logic.state.state import BlockInfo

from utils import Signer, get_contract_def, _root

# pytest-xdest only shows stderr
sys.stdout = sys.stderr


def get_block_timestamp(starknet_state):
  return starknet_state.state.block_info.block_timestamp


def set_block_timestamp(starknet_state, timestamp):
  starknet_state.state.block_info = BlockInfo.create_for_testing(
    starknet_state.state.block_info.block_number, timestamp
  )


async def deploy_account(starknet, signer, account_def):
  return await starknet.deploy(
    contract_def=account_def,
    constructor_calldata=[signer.public_key]
  )


def serialize_contract(contract, abi):
  return dict(
    abi=abi,
    contract_address=contract.contract_address,
    deploy_execution_info=contract.deploy_execution_info
  )


def unserialize_contract(starknet_state, serialized_contract):
  return StarknetContract(state=starknet_state, **serialized_contract)


@pytest.fixture(scope="session")
def event_loop():
  return asyncio.new_event_loop()


async def build_copyable_deployment():
  starknet = await Starknet.empty()

  # initialize realistic timestamp
  set_block_timestamp(starknet.state, round(time.time()))

  defs = SimpleNamespace(
    account=get_contract_def("mocks/account/Account.cairo"),
    rulesData=get_contract_def("ruleslabs/contracts/RulesData/RulesData.cairo"),
    rulesCards=get_contract_def("ruleslabs/contracts/RulesCards/RulesCards.cairo"),
    rulesPacks=get_contract_def("ruleslabs/contracts/RulesPacks/RulesPacks.cairo"),
    rulesTokens=get_contract_def("ruleslabs/contracts/RulesTokens/RulesTokens.cairo")
  )

  signers = dict(
    owner=Signer(8245892928310),
    minter=Signer(1004912350233),
    rando1=Signer(1111111111111),
    rando2=Signer(2222222222222),
    rando3=Signer(3333333333333)
  )

  accounts = SimpleNamespace(
    **{
      name: (await deploy_account(starknet, signer, defs.account))
      for name, signer in signers.items()
    }
  )

  rulesData = await starknet.deploy(
    contract_def=defs.rulesData,
    constructor_calldata=[
      accounts.owner.contract_address # owner
    ]
  )

  rulesCards = await starknet.deploy(
    contract_def=defs.rulesCards,
    constructor_calldata=[
      accounts.owner.contract_address, # owner
      rulesData.contract_address
    ]
  )

  rulesPacks = await starknet.deploy(
    contract_def=defs.rulesPacks,
    constructor_calldata=[
      accounts.owner.contract_address, # owner
      rulesCards.contract_address
    ]
  )

  rulesTokens = await starknet.deploy(
    contract_def=defs.rulesTokens,
    constructor_calldata=[
      0x5374616D70656465, # name
      0x5354414D50, # symbol
      accounts.owner.contract_address, # owner
      rulesCards.contract_address,
      rulesPacks.contract_address
    ]
  )

  for contract in [rulesData, rulesCards, rulesTokens, rulesPacks]:
    await signers["owner"].send_transaction(
      accounts.owner,
      contract.contract_address,
      "addMinter",
      [accounts.minter.contract_address]
    )

  await signers["owner"].send_transaction(
    accounts.owner,
    rulesCards.contract_address,
    "addMinter",
    [rulesTokens.contract_address]
  )

  await signers["owner"].send_transaction(
    accounts.owner,
    rulesPacks.contract_address,
    "addMinter",
    [rulesTokens.contract_address]
  )

  await signers["owner"].send_transaction(
    accounts.owner,
    rulesCards.contract_address,
    "addPacker",
    [rulesPacks.contract_address]
  )

  await signers["owner"].send_transaction(
    accounts.owner,
    rulesCards.contract_address,
    "revokePacker",
    [accounts.owner.contract_address]
  )

  return SimpleNamespace(
    starknet=starknet,
    signers=signers,
    serialized_contracts=dict(
      owner=serialize_contract(accounts.owner, defs.account.abi),
      rando1=serialize_contract(accounts.rando1, defs.account.abi),
      rando2=serialize_contract(accounts.rando2, defs.account.abi),
      rando3=serialize_contract(accounts.rando3, defs.account.abi),
      minter=serialize_contract(accounts.minter, defs.account.abi),
      rulesData=serialize_contract(rulesData, defs.rulesData.abi),
      rulesCards=serialize_contract(rulesCards, defs.rulesCards.abi),
      rulesPacks=serialize_contract(rulesPacks, defs.rulesPacks.abi),
      rulesTokens=serialize_contract(rulesTokens, defs.rulesTokens.abi)
    )
  )


@pytest.fixture(scope="session")
async def copyable_deployment(request):
  CACHE_KEY="deployment"
  val = request.config.cache.get(CACHE_KEY, None)

  if val is None:
    val = await build_copyable_deployment()
    res = dill.dumps(val).decode("cp437")
    request.config.cache.set(CACHE_KEY, res)
  else:
    val = dill.loads(val.encode("cp437"))

  return val


@pytest.fixture(scope="session")
async def ctx_factory(copyable_deployment):
  serialized_contracts = copyable_deployment.serialized_contracts
  signers = copyable_deployment.signers

  def make():
    starknet_state = copyable_deployment.starknet.state.copy()
    contracts = {
      name: unserialize_contract(starknet_state, serialized_contract)
      for name, serialized_contract in serialized_contracts.items()
    }

    async def execute(account_name, contract_address, selector_name, calldata):
      return await signers[account_name].send_transaction(
        contracts[account_name],
        contract_address,
        selector_name,
        calldata
      )

    return SimpleNamespace(
      starknet=Starknet(starknet_state),
      execute=execute,
      **contracts
    )

  return make
