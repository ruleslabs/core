import asyncio
import pytest
import dill
import sys
from types import SimpleNamespace
import time

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.starknet.testing.contract import DeclaredClass, StarknetContract
from starkware.starknet.compiler.compile import get_selector_from_name

from utils import Signer, get_contract_class, get_periphery_contract_class, _root

# pytest-xdest only shows stderr
sys.stdout = sys.stderr


def set_block_timestamp(starknet_state, timestamp):
  starknet_state.state.block_info = BlockInfo.create_for_testing(
    starknet_state.state.block_info.block_number, timestamp
  )


async def deploy_account(starknet, signer, account_def):
  account = await starknet.deploy(contract_class=account_def)
  await account.initialize(signer.public_key, 0).invoke()
  return account


def serialize_contract(contract, abi):
  return dict(
    abi=abi,
    contract_address=contract.contract_address,
    deploy_execution_info=contract.deploy_execution_info
  )


def serialize_class(declared_class):
  return dict(
    class_hash=declared_class.class_hash,
    abi=declared_class.abi
  )


def unserialize_contract(starknet_state, serialized_contract):
  return StarknetContract(state=starknet_state, **serialized_contract)


def unserialize_class(serialized_class):
  return DeclaredClass(**serialized_class)


@pytest.fixture(scope="session")
def event_loop():
  return asyncio.new_event_loop()


async def build_copyable_deployment():
  starknet = await Starknet.empty()

  # initialize realistic timestamp
  set_block_timestamp(starknet.state, round(time.time()))

  contract_classes = SimpleNamespace(
    account=get_periphery_contract_class("account/Account.cairo"),
    proxy=get_periphery_contract_class("proxy/Proxy.cairo"),
    rulesData=get_contract_class("ruleslabs/contracts/RulesData/RulesData.cairo"),
    rulesCards=get_contract_class("ruleslabs/contracts/RulesCards/RulesCards.cairo"),
    rulesPacks=get_contract_class("ruleslabs/contracts/RulesPacks/RulesPacks.cairo"),
    rulesTokens=get_contract_class("ruleslabs/contracts/RulesTokens/RulesTokens.cairo"),
    upgrade=get_contract_class("test/upgrade.cairo")
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
      name: (await deploy_account(starknet, signer, contract_classes.account))
      for name, signer in signers.items()
    }
  )

  # Implementations
  rulesData = await starknet.declare(contract_class=contract_classes.rulesData)
  rulesCards = await starknet.declare(contract_class=contract_classes.rulesCards)
  rulesPacks = await starknet.declare(contract_class=contract_classes.rulesPacks)
  rulesTokens = await starknet.declare(contract_class=contract_classes.rulesTokens)

  # Upgrade
  upgrade = await starknet.declare(contract_class=contract_classes.upgrade)

  # Proxies
  rulesDataProxy = await starknet.deploy(
    contract_class=contract_classes.proxy,
    constructor_calldata=[
      rulesData.class_hash,
      get_selector_from_name('initialize'),
      1,
      accounts.owner.contract_address,
    ]
  )
  rulesCardsProxy = await starknet.deploy(
    contract_class=contract_classes.proxy,
    constructor_calldata=[
      rulesCards.class_hash,
      get_selector_from_name('initialize'),
      2,
      accounts.owner.contract_address,
      rulesDataProxy.contract_address,
    ]
  )
  rulesPacksProxy = await starknet.deploy(
    contract_class=contract_classes.proxy,
    constructor_calldata=[
      rulesPacks.class_hash,
      get_selector_from_name('initialize'),
      3,
      accounts.owner.contract_address,
      rulesDataProxy.contract_address,
      rulesCardsProxy.contract_address,
    ]
  )
  rulesTokensProxy = await starknet.deploy(
    contract_class=contract_classes.proxy,
    constructor_calldata=[
      rulesTokens.class_hash,
      get_selector_from_name('initialize'),
      5,
      0x5374616D70656465, # name
      0x5354414D50, # symbol
      accounts.owner.contract_address, # owner
      rulesCardsProxy.contract_address,
      rulesPacksProxy.contract_address,
    ]
  )

  # Configure access control
  for contract in [rulesDataProxy, rulesCardsProxy, rulesTokensProxy, rulesPacksProxy]:
    await signers["owner"].send_transaction(
      accounts.owner,
      contract.contract_address,
      "addMinter",
      [accounts.minter.contract_address]
    )

  await signers["owner"].send_transaction(
    accounts.owner,
    rulesCardsProxy.contract_address,
    "addMinter",
    [rulesTokensProxy.contract_address]
  )

  await signers["owner"].send_transaction(
    accounts.owner,
    rulesPacksProxy.contract_address,
    "addMinter",
    [rulesTokensProxy.contract_address]
  )

  await signers["owner"].send_transaction(
    accounts.owner,
    rulesCardsProxy.contract_address,
    "addPacker",
    [rulesPacksProxy.contract_address]
  )

  await signers["owner"].send_transaction(
    accounts.owner,
    rulesCardsProxy.contract_address,
    "revokePacker",
    [accounts.owner.contract_address]
  )

  return SimpleNamespace(
    starknet=starknet,
    signers=signers,
    serialized_contracts=dict(
      owner=serialize_contract(accounts.owner, contract_classes.account.abi),
      rando1=serialize_contract(accounts.rando1, contract_classes.account.abi),
      rando2=serialize_contract(accounts.rando2, contract_classes.account.abi),
      rando3=serialize_contract(accounts.rando3, contract_classes.account.abi),
      minter=serialize_contract(accounts.minter, contract_classes.account.abi),
      rulesData=serialize_contract(rulesDataProxy, contract_classes.rulesData.abi),
      rulesCards=serialize_contract(rulesCardsProxy, contract_classes.rulesCards.abi),
      rulesPacks=serialize_contract(rulesPacksProxy, contract_classes.rulesPacks.abi),
      rulesTokens=serialize_contract(rulesTokensProxy, contract_classes.rulesTokens.abi),
    ),
    serialized_classes=dict(
      upgrade=serialize_class(upgrade)
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
  serialized_classes = copyable_deployment.serialized_classes
  signers = copyable_deployment.signers

  def make():
    starknet_state = copyable_deployment.starknet.state.copy()
    contracts = {
      name: unserialize_contract(starknet_state, serialized_contract)
      for name, serialized_contract in serialized_contracts.items()
    }
    classes = {
      name: unserialize_class(serialized_class)
      for name, serialized_class in serialized_classes.items()
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
      **classes,
      **contracts
    )

  return make
