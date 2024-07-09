import { ITransfer, TaskState, TransferState } from "./types";
import { getAttestation, getRelayTaskStatus, postCallWithSyncFee } from "./api";
import { CallWithSyncFeeRequest } from "@gelatonetwork/relay-sdk";
import { ChainId, NETWORKS } from "./constants";
import { TWO_HOURS } from "./constants";
import { ethers } from "ethers";
import { Web3Function, Web3FunctionContext } from "@gelatonetwork/web3-functions-sdk";
import { IMessageTransmitter__factory, CCTPAdapter__factory, CCTPReceiver__factory } from "./typechain";

// eslint-disable-next-line
(BigInt.prototype as any).toJSON = function () {
  return this.toString();
};

Web3Function.onRun(async (context: Web3FunctionContext) => {
  // index events from one network at a time
  // execute transfers from the current network
  const networkIndexStr = await context.storage.get("network");
  const networkIndex = networkIndexStr ? Number(networkIndexStr) : 0;

  // set next index immediately
  // if any subsequent operation fails we still serve other networks
  const nextNetworkIndex = (networkIndex + 1) % Object.keys(NETWORKS).length;
  await context.storage.set("network", nextNetworkIndex.toString());

  const [chainId, network] = Object.entries(NETWORKS)[networkIndex];
  const provider = await context.multiChainProvider.chainId(Number(chainId));

  // event indexing contains no reorg protection
  // todo: implemented via block confirmations or use event based trigger
  const currentBlock = await provider.getBlockNumber();
  const lastBlockStr = await context.storage.get(chainId);
  const lastBlock = lastBlockStr ? Number(lastBlockStr) : currentBlock;

  if (!lastBlockStr) await context.storage.set(chainId, currentBlock.toString());

  // if no blocks have passed since last execution, return early
  // no reason to check attestations since the attestation service waits for new blocks
  if (currentBlock === lastBlock) return { canExec: false, message: "No blocks to index" };

  // get stored transfer requests
  const transferRequestsStr = await context.storage.get("transfers");
  const transferRequests: ITransfer[] = transferRequestsStr ? JSON.parse(transferRequestsStr) : [];

  // instantiate all contracts on the current network
  // eslint-disable-next-line
  const runner = { provider: provider as any };

  const circleMessageTransmitter = IMessageTransmitter__factory.connect(network.circleMessageTransmitter, runner);

  const mikiCCTPAdapter = CCTPAdapter__factory.connect(network.mikiCCTPAdapter, runner);

  const mikiCCTPReceiver = CCTPReceiver__factory.connect(network.mikiCCTPReceiver, runner);

  // query the state of all relayed transfers and mark successful transfers as confirmed
  // retry failed transfers by marking them as pending relay request
  // the relay request will be resubmitted
  await Promise.all(
    transferRequests.map(async (transferRequest, index): Promise<void> => {
      if (transferRequest.state !== TransferState.PendingConfirmation || !transferRequest.taskId) return;

      const taskStatus = await getRelayTaskStatus(transferRequest.taskId);
      if (!taskStatus) return;

      if (
        taskStatus.taskState === TaskState.CheckPending ||
        taskStatus.taskState === TaskState.ExecPending ||
        taskStatus.taskState === TaskState.WaitingForConfirmation
      )
        return;

      if (taskStatus.taskState === TaskState.ExecSuccess) transferRequests[index].state = TransferState.Confirmed;
      else {
        console.error("Retrying transfer:", transferRequest.taskId);
        transferRequests[index].state = TransferState.PendingRelayRequest;
      }
    }),
  );

  // index all events since last processed block
  // todo: split whole block range into smaller subranges (max 10,000)
  const circleMessageSents = await circleMessageTransmitter.queryFilter(
    circleMessageTransmitter.filters.MessageSent,
    lastBlock + 1,
    currentBlock,
  );

  const mikiCCTPSend = await mikiCCTPAdapter.queryFilter(mikiCCTPAdapter.filters.CCTPSend, lastBlock + 1, currentBlock);

  // MessageTransmitter and GelatoCCTPSender emit on depositForBurn
  // every GelatoCCTPSender event corresponds to a MessageTransmitter event
  // but not every MessageTransmitter event corresponds to a GelatoCCTPSender event
  // we merge these events together based on their transactionHash
  // ths can be optimised since events are in the same order
  const indexedTransferRequests = mikiCCTPSend.map((sendEvent): ITransfer => {
    const message = circleMessageSents.find((message) => message.transactionHash === sendEvent.transactionHash)!;

    return {
      owner: sendEvent.args.sender,
      chainId: Number(sendEvent.args.dstChainId),
      message: message.args.message,
      mikiMessage: "", // TODO: update
      appReceiver: "0x928842BB2aD5A2161277e62260e6AC5c5C16d6c1", // EmptyAppReceiver
      state: TransferState.PendingAttestation,
      expiry: Date.now() + TWO_HOURS,
    };
  });

  // add newly indexed transfer requests to transfer requests
  transferRequests.push(...indexedTransferRequests);

  // fetch attestations for transfers pending attestation
  await Promise.all(
    transferRequests.map(async (transferRequest, index): Promise<void> => {
      if (transferRequest.state !== TransferState.PendingAttestation) return;

      const messageHash = ethers.keccak256(transferRequest.message);
      const attestation = await getAttestation(messageHash);

      if (!attestation) return;

      transferRequests[index].attestation = attestation;
      transferRequests[index].state = TransferState.PendingRelayRequest;
    }),
  );

  // execute all executable transfers
  // store their corresponding taskIds to manage their lifetime
  await Promise.all(
    transferRequests.map(async (transferRequest, index): Promise<void> => {
      if (
        transferRequest.state !== TransferState.PendingRelayRequest ||
        transferRequest.chainId !== network.chainId ||
        !transferRequest.attestation
      )
        return;

      /*
       * function cctpReceive(
       *  bytes calldata _message,
       *  bytes calldata _attestation,
       *  address _appReceiver,
       *  uint256 _srcChainId,
       *  address _srcAddress,
       *  bytes calldata _mikiMessage
       * )
       */

      // TODO: update to dynamic

      const receiveMessage = await mikiCCTPReceiver.cctpReceive.populateTransaction(
        transferRequest.message,
        transferRequest.attestation,
        transferRequest.appReceiver,
        transferRequest.chainId,
        transferRequest.owner,
        transferRequest.mikiMessage,
      );

      const request: CallWithSyncFeeRequest = {
        chainId: BigInt(chainId),
        target: receiveMessage.to,
        data: receiveMessage.data,
        feeToken: network.usdc,
      };

      const taskId = await postCallWithSyncFee(request);
      if (!taskId) return;

      transferRequests[index].taskId = taskId;
      transferRequests[index].state = TransferState.PendingConfirmation;
    }),
  );

  // filter out confirmed and expired transfers
  const remainingTransferRequests = transferRequests.filter(
    (transferRequest) => transferRequest.state !== TransferState.Confirmed && transferRequest.expiry > Date.now(),
  );

  // store remaining transfer requests
  await context.storage.set("transfers", JSON.stringify(remainingTransferRequests));

  // store the last processed block
  await context.storage.set(chainId, currentBlock.toString());

  // get the number of transfers in a given state
  const stateCount = transferRequests.reduce(
    (prev, transferRequest) => {
      prev[transferRequest.state]++;
      return prev;
    },
    {
      Confirmed: 0,
      PendingAttestation: 0,
      PendingConfirmation: 0,
      PendingRelayRequest: 0,
    } as { [key in TransferState]: number },
  );

  const message =
    `network: ${ChainId[Number(chainId) as ChainId]}, ` +
    `processed: ${currentBlock - lastBlock}, ` +
    `indexed: ${indexedTransferRequests.length}, ` +
    `attesting: ${stateCount[TransferState.PendingAttestation]}, ` +
    `executed: ${stateCount[TransferState.PendingConfirmation]}, ` +
    `confirmed: ${stateCount[TransferState.Confirmed]}`;

  return { canExec: false, message };
});
