import asyncio
import pytest
import dill
import os
import sys
from types import SimpleNamespace
import time

from starkware.starknet.compiler.compile import compile_starknet_files
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.business_logic.state import BlockInfo

from OpenZeppelin.Signer import Signer

# pytest-xdest only shows stderr
sys.stdout = sys.stderr
CONTRACT_SRC = [os.path.dirname(__file__), "..", "contracts"]

def compile(path):
  return compile_starknet_files(
    files=['/'.join(CONTRACT_SRC + [path])],
    debug_info=True
  )


def get_block_timestamp(starknet_state):
  return starknet_state.state.block_info.block_timestamp


def set_block_timestamp(starknet_state, timestamp):
  starknet_state.state.block_info = BlockInfo(
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
    account=compile("openzeppelin/Account.cairo"),
    ravageData=compile("RavageData.cairo"),
    ravageCards=compile("RavageCards.cairo"),
    ravageTokens=compile("RavageTokens.cairo")
  )

  signers = dict(
    admin=Signer(8245892928310),
    rando=Signer(7427329833829)
  )

  accounts = SimpleNamespace(
    **{
      name: (await deploy_account(starknet, signer, defs.account))
      for name, signer in signers.items()
    }
  )

  ravageData = await starknet.deploy(
    contract_def=defs.ravageData,
    constructor_calldata=[]
  )

  ravageCards = await starknet.deploy(
    contract_def=defs.ravageCards,
    constructor_calldata=[
      ravageData.contract_address
    ]
  )

  ravageTokens = await starknet.deploy(
    contract_def=defs.ravageTokens,
    constructor_calldata=[
      0x5374616D70656465, # name
      0x5354414D50, # symbol
      ravageCards.contract_address,
      0
    ]
  )

  return SimpleNamespace(
    starknet=starknet,
    signers=signers,
    serialized_contracts=dict(
      admin=serialize_contract(accounts.admin, defs.account.abi),
      rando=serialize_contract(accounts.rando, defs.account.abi),
      ravageData=serialize_contract(ravageData, defs.ravageData.abi),
      ravageCards=serialize_contract(ravageCards, defs.ravageCards.abi),
      ravageTokens=serialize_contract(ravageTokens, defs.ravageTokens.abi)
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
      return await signers[account_name].sendTransaction(
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
